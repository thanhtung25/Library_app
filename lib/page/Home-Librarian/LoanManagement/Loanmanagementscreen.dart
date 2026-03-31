import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';
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

  static const _tabs     = ['Tất cả', 'Đặt trước', 'Đang mượn', 'Đã trả', 'Quá hạn'];
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
      setState(() {
        _loans   = raw.map((e) => LoanItem.fromJson(e as Map<String, dynamic>)).toList();
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
      _filtered = _loans.where((l) {
        final matchSt = status == 'all' || l.status == status;
        final matchQ  = q.isEmpty ||
            l.idUser.toString().contains(q) ||
            l.idCopy.toString().contains(q) ||
            l.idLoan.toString().contains(q);
        return matchSt && matchQ;
      }).toList();
    });
  }

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
      _showSuccess('Đã xác nhận phát sách và gửi thông báo!');
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
      _showSuccess('Đã tạo phạt ${loanFormatMoney(amount)} VNĐ và gửi thông báo!');
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
      _showSuccess('Đã gửi thông báo nhắc hạn!');
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
        title: const Text('Quản lý Mượn / Trả',
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

      body: Column(children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => _applyFilter(),
            decoration: InputDecoration(
              hintText: 'Tìm theo ID phiếu / người dùng / bản sao...',
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

        // Summary chips
        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                LoanChip('Tổng: ${_loans.length}',                Colors.blueGrey),
                const SizedBox(width: 6),
                LoanChip('Đặt trước: ${_cnt("reserved")}',       Colors.purple),
                const SizedBox(width: 6),
                LoanChip('Đang mượn: ${_cnt("borrowed")}',       Colors.orange),
                const SizedBox(width: 6),
                LoanChip('Quá hạn: ${_cnt("overdue")}',          Colors.red),
                const SizedBox(width: 6),
                LoanChip('Sắp hạn: ${_loans.where((l) => l.isNearDeadline).length}',
                    const Color(0xffE65100)),
              ]),
            ),
          ),

        const LoanTableHeader(),

        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kLoanOrange))
              : _error != null
              ? Center(child: Text(_error!,
              style: const TextStyle(color: Colors.red)))
              : _filtered.isEmpty
              ? const Center(child: Text('Không có dữ liệu'))
              : RefreshIndicator(
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
      ]),

      floatingActionButton: FloatingActionButton(
        backgroundColor: kLoanOrange,
        onPressed: _addLoan,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  int _cnt(String s) => _loans.where((l) => l.status == s).length;

  void _showError(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _showSuccess(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
}
