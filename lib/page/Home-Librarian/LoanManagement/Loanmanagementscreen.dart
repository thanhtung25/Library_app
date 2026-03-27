import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';
import 'package:library_app/model/user_model.dart';

// ─── Model ────────────────────────────────────────────────────────────────────
class _Loan {
  final int idLoan;
  final String idUser;
  final String idBook;
  final String issueDate;
  final String returnDate;
  final String? actualReturn;
  final String status; // 'borrowed' | 'returned' | 'overdue'

  _Loan({
    required this.idLoan,
    required this.idUser,
    required this.idBook,
    required this.issueDate,
    required this.returnDate,
    this.actualReturn,
    required this.status,
  });

  factory _Loan.fromJson(Map<String, dynamic> j) => _Loan(
    idLoan: j['id_loan'] ?? 0,
    idUser: j['id_user']?.toString() ?? '',
    idBook: j['id_book']?.toString() ?? '',
    issueDate: j['issue_date'] ?? '',
    returnDate: j['return_date'] ?? '',
    actualReturn: j['actual_return'],
    status: j['status'] ?? 'borrowed',
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class LoanManagementScreen extends StatefulWidget {
  final UserModel user;
  const LoanManagementScreen({super.key, required this.user});

  @override
  State<LoanManagementScreen> createState() => _LoanManagementScreenState();
}

class _LoanManagementScreenState extends State<LoanManagementScreen>
    with SingleTickerProviderStateMixin {
  static const _orange = Color(0xffFF9E74);
  static const _bg     = Color(0xffFBEEE4);

  late final TabController _tabCtrl;
  final _searchCtrl = TextEditingController();

  List<_Loan> _loans    = [];
  List<_Loan> _filtered = [];
  bool   _loading = true;
  String? _error;

  // Tab labels & matching status values
  static const _tabs = ['Tất cả', 'Đang mượn', 'Đã trả', 'Quá hạn'];
  static const _statuses = ['all', 'borrowed', 'returned', 'overdue'];

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

  Future<void> _fetchLoans() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.get('/loans-management/loans');
      final list = (data['loans'] as List? ?? data as List)
          .map((e) => _Loan.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() { _loans = list; _loading = false; });
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
        final matchStatus = status == 'all' || l.status == status;
        final matchSearch = q.isEmpty ||
            l.idUser.toLowerCase().contains(q) ||
            l.idBook.toLowerCase().contains(q);
        return matchStatus && matchSearch;
      }).toList();
    });
  }

  // ── Mark as returned ──────────────────────────────────────────────────────
  Future<void> _markReturned(_Loan loan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận trả sách',
            style: TextStyle(fontFamily: 'Times New Roman')),
        content: Text('Xác nhận người dùng ${loan.idUser} đã trả sách?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.put('/loans-management/loan/${loan.idLoan}',
            {'status': 'returned'});
        _fetchLoans();
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  // ── Add new loan dialog ───────────────────────────────────────────────────
  Future<void> _showAddLoanDialog() async {
    final userCtrl       = TextEditingController();
    final bookCtrl       = TextEditingController();
    final issueDateCtrl  = TextEditingController();
    final returnDateCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tạo phiếu mượn',
            style: TextStyle(fontFamily: 'Times New Roman', color: _orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(userCtrl,       'ID Người dùng', TextInputType.number),
            const SizedBox(height: 10),
            _dialogField(bookCtrl,       'ID Sách',       TextInputType.number),
            const SizedBox(height: 10),
            _dialogField(issueDateCtrl,  'Ngày mượn (dd/mm/yyyy)', TextInputType.datetime),
            const SizedBox(height: 10),
            _dialogField(returnDateCtrl, 'Hạn trả (dd/mm/yyyy)',   TextInputType.datetime),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.post('/loans-management/loan', {
                  'id_user':     int.tryParse(userCtrl.text.trim()),
                  'id_book':     int.tryParse(bookCtrl.text.trim()),
                  'issue_date':  issueDateCtrl.text.trim(),
                  'return_date': returnDateCtrl.text.trim(),
                  'status':      'borrowed',
                });
                _fetchLoans();
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text('Tạo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Quản lý Mượn / Trả',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
            color: _orange,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _orange),
            onPressed: _fetchLoans,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: _orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _orange,
          labelStyle: const TextStyle(
              fontFamily: 'Times New Roman', fontWeight: FontWeight.bold),
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Tìm theo ID người dùng / ID sách...',
                prefixIcon: const Icon(Icons.search, color: _orange),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Table header
          _tableHeader(),

          // Rows
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _orange))
                : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : _filtered.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : RefreshIndicator(
              onRefresh: _fetchLoans,
              color: _orange,
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _loanRow(_filtered[i]),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: _orange,
        onPressed: _showAddLoanDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _tableHeader() {
    return Container(
      color: _orange,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: const Row(
        children: [
          Expanded(flex: 1, child: _H('ID')),
          Expanded(flex: 2, child: _H('ID Sách')),
          Expanded(flex: 2, child: _H('Ngày mượn')),
          Expanded(flex: 2, child: _H('Hạn trả')),
          Expanded(flex: 2, child: _H('Trạng thái')),
          SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _loanRow(_Loan loan) {
    Color statusColor;
    switch (loan.status) {
      case 'returned': statusColor = Colors.green;  break;
      case 'overdue':  statusColor = Colors.red;    break;
      default:         statusColor = Colors.orange;
    }
    final statusLabel = {
      'borrowed': 'Đang mượn',
      'returned': 'Đã trả',
      'overdue':  'Quá hạn',
    }[loan.status] ?? loan.status;

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: _cell(loan.idUser)),
          Expanded(flex: 2, child: _cell(loan.idBook)),
          Expanded(flex: 2, child: _cell(loan.issueDate)),
          Expanded(flex: 2, child: _cell(loan.returnDate)),
          Expanded(
            flex: 2,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          if (loan.status == 'borrowed')
            IconButton(
              icon: const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 20),
              tooltip: 'Đánh dấu đã trả',
              onPressed: () => _markReturned(loan),
            )
          else
            const SizedBox(width: 36),
        ],
      ),
    );
  }

  Widget _cell(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
    child: Text(text, style: const TextStyle(fontSize: 12)),
  );

  TextField _dialogField(TextEditingController ctrl, String label,
      TextInputType type) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: _orange)),
      ),
    );
  }
}

class _H extends StatelessWidget {
  final String t;
  const _H(this.t);
  @override
  Widget build(BuildContext context) => Text(t,
      style: const TextStyle(color: Colors.white,
          fontWeight: FontWeight.bold, fontSize: 12));
}