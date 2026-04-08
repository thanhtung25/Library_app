import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';
import 'package:library_app/api_localhost/AuthService.dart';
import 'package:library_app/model/user_model.dart';
import 'loan_item.dart';
import 'loan_constants.dart';
import 'loan_dialogs.dart';
import 'loan_widgets.dart';

class LoanManagementScreen extends StatefulWidget {
  final UserModel user;
  const LoanManagementScreen({super.key, required this.user});

  @override
  State<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen>
    with SingleTickerProviderStateMixin {

  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  List<LoanItem> _loans = [], _filtered = [];
  bool    _loading = true;
  String? _error;

  // ── Cache tên người dùng để tránh gọi API lặp lại ──────────────────────
  final AuthService _authService = AuthService();
  final Map<int, String> _userNameCache = {};

  // ── Pagination ──────────────────────────────────────────────────────────
  static const int _rowsPerPage = 15;
  int _currentPage = 0;

  static const _tabs     = ['Все', 'Забронировано', 'На руках', 'Возвращено', 'Просрочено'];
  static const _statuses = ['all', 'reserved', 'borrowed', 'returned', 'overdue'];

  // ── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
    _tabCtrl.addListener(_applyFilter);
    _fetchLoans();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<void> _fetchLoans() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.get('/loans-management/loans');
      final raw  = data is List ? data : (data['loans'] as List? ?? []);

      // Bước 1: parse danh sách loan cơ bản
      final loans = raw
          .map((e) => LoanItem.fromJson(e as Map<String, dynamic>))
          .toList();

      // Bước 2: lấy tên người dùng — gọi API song song, dùng cache
      final uniqueUserIds = loans.map((l) => l.idUser).toSet();
      await Future.wait(
        uniqueUserIds
            .where((id) => !_userNameCache.containsKey(id))
            .map((id) async {
          try {
            final user = await _authService.getUserbyId(id);
            _userNameCache[id] = user.fullName;
          } catch (_) {
            // Nếu lỗi, giữ nguyên — widget sẽ fallback về "Польз. #id"
          }
        }),
      );

      // Bước 3: gán userName từ cache vào từng LoanItem
      final enriched = loans.map((l) => l.copyWith(
        userName: _userNameCache[l.idUser],
      )).toList();

      setState(() {
        _loans   = enriched;
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q      = _searchCtrl.text.toLowerCase();
    final status = _statuses[_tabCtrl.index];
    setState(() {
      _currentPage = 0;
      _filtered = _loans.where((l) {
        final matchSt = status == 'all' || l.status == status;
        final matchQ  = q.isEmpty ||
            l.idUser.toString().contains(q) ||
            l.idCopy.toString().contains(q) ||
            l.idLoan.toString().contains(q) ||
            (l.userName?.toLowerCase().contains(q) ?? false);
        return matchSt && matchQ;
      }).toList();
    });
  }

  // ── Pagination helpers ───────────────────────────────────────────────────
  List<LoanItem> get _pagedItems {
    final start = _currentPage * _rowsPerPage;
    final end   = (start + _rowsPerPage).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  int get _totalPages => (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<void> _confirmBorrow(LoanItem loan) async {
    Map<String, dynamic>? copy;
    try {
      copy = await ApiService.get(
          '/book_copies-management/book_copy/${loan.idCopy}');
    } catch (_) {}

    if (!mounted) return;
    final ok = await showConfirmBorrowDialog(
      context, loan,
      barcode: copy?['barcode']?.toString() ?? '',
      qrVal:   copy?['qr_code']?.toString()  ?? copy?['barcode']?.toString() ?? '',
    );
    if (ok != true) return;

    try {
      final barcodeVal = copy?['barcode']?.toString() ?? '';
      final qrVal      = copy?['qr_code']?.toString() ?? barcodeVal;
      final scanCode   = qrVal.isNotEmpty ? qrVal : barcodeVal;
      await ApiService.put('/loans-management/loan/${loan.idLoan}',
          {'status': 'borrowed'});
      await ApiService.post('/notifications-management/notification', {
        'id_user': loan.idUser,
        'type':    'loan_ready',
        'message': 'Phiếu mượn #${loan.idLoan}: Bạn đã nhận bản sao '
            '#${loan.idCopy}. Hạn trả: ${loan.returnDate}.'
            '${scanCode.isNotEmpty ? '|BARCODE:$scanCode' : ''}',
      });
      _showSuccess('Выдача подтверждена, уведомление отправлено!');
      _fetchLoans();
    } catch (e) { _showError(e.toString()); }
  }

  Future<void> _handleOverdue(LoanItem loan) async {
    final ok = await showOverdueDialog(context, loan);
    if (ok != true) return;

    try {
      final days   = loan.daysOverdue;
      final amount = days * kFinePerDay;
      await ApiService.post('/fines-management/fine', {
        'id_loan':    loan.idLoan,
        'amount':     amount,
        'reason':     'Trả sách quá hạn $days ngày (hạn: ${loan.returnDate})',
        'created_at': loanTodayStr(),
        'status':     'unpaid',
      });
      await ApiService.post('/notifications-management/notification', {
        'id_user': loan.idUser,
        'type':    'overdue',
        'message': 'Phiếu mượn #${loan.idLoan} quá hạn $days ngày. '
            'Tiền phạt: ${loanFormatMoney(amount)} VNĐ. '
            'Vui lòng trả sách và thanh toán ngay.',
      });
      _showSuccess('Штраф ${loanFormatMoney(amount)} VNĐ создан, уведомление отправлено!');
      _fetchLoans();
    } catch (e) { _showError(e.toString()); }
  }

  Future<void> _sendDueSoon(LoanItem loan) async {
    final ok = await showDueSoonDialog(context, loan);
    if (ok != true) return;

    try {
      final days = loan.daysUntilReturn;
      await ApiService.post('/notifications-management/notification', {
        'id_user': loan.idUser,
        'type':    'due_soon',
        'message': days == 0
            ? 'Phiếu mượn #${loan.idLoan}: Hôm nay là ngày cuối hạn trả '
            'bản sao #${loan.idCopy}. Vui lòng trả ngay!'
            : 'Phiếu mượn #${loan.idLoan}: Còn $days ngày đến hạn trả '
            'bản sao #${loan.idCopy} (hạn: ${loan.returnDate}).',
      });
      _showSuccess('Напоминание о сроке отправлено!');
    } catch (e) { _showError(e.toString()); }
  }

  Future<void> _markReturned(LoanItem loan) async {
    final ok = await showMarkReturnedDialog(context, loan);
    if (ok != true) return;
    try {
      await ApiService.put('/loans-management/loan/${loan.idLoan}', {
        'status':             'returned',
        'actual_return_date': loanTodayStr(),
      });
      _fetchLoans();
    } catch (e) { _showError(e.toString()); }
  }

  Future<void> _deleteLoan(LoanItem loan) async {
    final ok = await showDeleteLoanDialog(context, loan);
    if (ok != true) return;
    try {
      await ApiService.delete('/loans-management/loan/${loan.idLoan}');
      _fetchLoans();
    } catch (e) { _showError(e.toString()); }
  }

  Future<void> _addLoan() async {
    final data = await showAddLoanFormDialog(context);
    if (data == null) return;
    try {
      await ApiService.post('/loans-management/loan', data);
      _fetchLoans();
    } catch (e) { _showError(e.toString()); }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLoanBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: kLoanBg,
        elevation: 0,
        title: const Text('Управление выдачей книг',
            style: TextStyle(
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
                color: kLoanOrange,
                fontSize: 22)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: kLoanOrange),
              onPressed: _fetchLoans),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: kLoanOrange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kLoanOrange,
          isScrollable: true,
          labelStyle: const TextStyle(
              fontFamily: 'Times New Roman', fontWeight: FontWeight.bold),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWeb = constraints.maxWidth >= 900;
          return Column(children: [
            // ── Search bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (_) => _applyFilter(),
                decoration: InputDecoration(
                  hintText: 'Поиск по ID, читателю, экземпляру...',
                  prefixIcon: const Icon(Icons.search, color: kLoanOrange),
                  filled: true, fillColor: Colors.white,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ),

            // ── Summary chips ────────────────────────────────────────────
            if (!_loading && _error == null)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    LoanChip('Всего: ${_loans.length}',                    Colors.blueGrey),
                    const SizedBox(width: 6),
                    LoanChip('Заброн.: ${_cnt("reserved")}',               Colors.purple),
                    const SizedBox(width: 6),
                    LoanChip('На руках: ${_cnt("borrowed")}',              Colors.orange),
                    const SizedBox(width: 6),
                    LoanChip('Просрочено: ${_cnt("overdue")}',             Colors.red),
                    const SizedBox(width: 6),
                    LoanChip('Скоро срок: ${_loans.where((l) => l.isNearDeadline).length}',
                        const Color(0xffE65100)),
                  ]),
                ),
              ),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: kLoanOrange))
                  : _error != null
                  ? Center(child: Text(_error!,
                  style: const TextStyle(color: Colors.red)))
                  : _filtered.isEmpty
                  ? const Center(child: Text('Нет данных'))
                  : isWeb
                  ? _buildWebLayout()
                  : _buildMobileLayout(),
            ),
          ]);
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: kLoanOrange,
        onPressed: _addLoan,
        tooltip: 'Добавить запись',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Web layout (table + pagination) ──────────────────────────────────────
  Widget _buildWebLayout() {
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: LoanWebTable(
              loans:           _pagedItems,
              onOpenDetail:    (l) => showLoanDetailSheet(context, l),
              onConfirmBorrow: _confirmBorrow,
              onDueSoon:       _sendDueSoon,
              onOverdue:       _handleOverdue,
              onMarkReturn:    _markReturned,
              onDelete:        _deleteLoan,
            ),
          ),
        ),
        _buildPaginationBar(),
      ],
    );
  }

  Widget _buildPaginationBar() {
    final start = _currentPage * _rowsPerPage + 1;
    final end   = ((_currentPage + 1) * _rowsPerPage).clamp(0, _filtered.length);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Показано $start–$end из ${_filtered.length} записей',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page),
                color: _currentPage == 0 ? Colors.grey : kLoanOrange,
                onPressed: _currentPage == 0
                    ? null
                    : () => setState(() => _currentPage = 0),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: _currentPage == 0 ? Colors.grey : kLoanOrange,
                onPressed: _currentPage == 0
                    ? null
                    : () => setState(() => _currentPage--),
              ),
              ..._buildPageNumbers(),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: _currentPage >= _totalPages - 1 ? Colors.grey : kLoanOrange,
                onPressed: _currentPage >= _totalPages - 1
                    ? null
                    : () => setState(() => _currentPage++),
              ),
              IconButton(
                icon: const Icon(Icons.last_page),
                color: _currentPage >= _totalPages - 1 ? Colors.grey : kLoanOrange,
                onPressed: _currentPage >= _totalPages - 1
                    ? null
                    : () => setState(() => _currentPage = _totalPages - 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    const maxVisible = 5;
    final total = _totalPages;
    final start = (_currentPage - maxVisible ~/ 2)
        .clamp(0, (total - maxVisible).clamp(0, total));
    final end = (start + maxVisible).clamp(0, total);

    return List.generate(end - start, (i) {
      final page     = start + i;
      final isActive = page == _currentPage;
      return GestureDetector(
        onTap: () => setState(() => _currentPage = page),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: isActive ? kLoanOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: isActive ? kLoanOrange : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text(
            '${page + 1}',
            style: TextStyle(
              fontSize: 13,
              color: isActive ? Colors.white : Colors.black87,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );
    });
  }

  // ── Mobile layout ─────────────────────────────────────────────────────────
  Widget _buildMobileLayout() {
    return Column(
      children: [
        const LoanTableHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchLoans,
            color: kLoanOrange,
            child: ListView.builder(
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final loan = _filtered[i];
                return LoanRow(
                  loan:            loan,
                  onTap:           () => showLoanDetailSheet(context, loan),
                  onConfirmBorrow: () => _confirmBorrow(loan),
                  onDueSoon:       () => _sendDueSoon(loan),
                  onOverdue:       () => _handleOverdue(loan),
                  onMarkReturn:    () => _markReturned(loan),
                  onDelete:        () => _deleteLoan(loan),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  int _cnt(String s) => _loans.where((l) => l.status == s).length;

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
}