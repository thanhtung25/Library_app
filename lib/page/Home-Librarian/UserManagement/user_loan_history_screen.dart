import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';

class _LoanRow {
  final int idLoan;
  final String bookTitle;
  final String issueDate;
  final String returnDate;
  final String status;

  _LoanRow({
    required this.idLoan,
    required this.bookTitle,
    required this.issueDate,
    required this.returnDate,
    required this.status,
  });
}

class UserLoanHistoryScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserLoanHistoryScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserLoanHistoryScreen> createState() => _UserLoanHistoryScreenState();
}

class _UserLoanHistoryScreenState extends State<UserLoanHistoryScreen> {
  static const _orange = Color(0xffFF9E74);
  static const _bg = Color(0xffFBEEE4);

  List<_LoanRow> _loans = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<String> _resolveBookTitle(int idCopy) async {
    try {
      final copy =
      await ApiService.get('/book_copies-management/book_copy/$idCopy');
      final idBook = copy['id_book'] ?? copy['book_id'];
      if (idBook == null) return 'Экз. #$idCopy';
      final book = await ApiService.get('/book-management/book/$idBook');
      return book['title'] ?? 'Экз. #$idCopy';
    } catch (_) {
      return 'Экз. #$idCopy';
    }
  }

  Future<void> _fetchLoans() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.get(
          '/loans-management/loan/user/${widget.userId}');
      final raw = data is List ? data : (data['loans'] as List? ?? []);

      final rows = await Future.wait(
        (raw as List).map((e) async {
          final idCopy = e['id_copy'] ?? 0;
          final title = await _resolveBookTitle(idCopy);
          return _LoanRow(
            idLoan: e['id_loan'] ?? 0,
            bookTitle: title,
            issueDate: e['issue_date'] ?? '',
            returnDate: e['return_date'] ?? '',
            status: e['status'] ?? '',
          );
        }),
      );

      setState(() { _loans = rows; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'reserved': return Colors.purple;
      case 'borrowed': return _orange;
      case 'returned': return Colors.green;
      case 'overdue':  return Colors.red;
      default:         return Colors.grey;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'reserved': return 'Зарезервирована';
      case 'borrowed': return 'На руках';
      case 'returned': return 'Возвращена';
      case 'overdue':  return 'Просрочена';
      default:         return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'История выдач',
              style: TextStyle(
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
                color: _orange,
                fontSize: 18,
              ),
            ),
            Text(widget.userName,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: _orange),
              onPressed: _fetchLoans),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : _loans.isEmpty
          ? _buildEmpty()
          : Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              itemCount: _loans.length,
              itemBuilder: (_, i) => _buildRow(_loans[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/book1.png',
            height: 120,
            opacity: const AlwaysStoppedAnimation(0.4)),
        const SizedBox(height: 16),
        const Text(
          'История выдач пуста',
          style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 16,
              color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _buildHeader() => Container(
    color: _orange,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    child: const Row(
      children: [
        Expanded(flex: 4, child: _H('Книга')),
        Expanded(flex: 2, child: _H('Дата выдачи')),
        Expanded(flex: 2, child: _H('Дата возврата')),
        SizedBox(width: 36),
      ],
    ),
  );

  Widget _buildRow(_LoanRow row) => Container(
    decoration:
    BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
    child: Row(
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            child: Text(row.bookTitle,
                style: const TextStyle(
                    fontFamily: 'Times New Roman', fontSize: 13),
                overflow: TextOverflow.ellipsis,
                maxLines: 2),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Text(row.issueDate,
                style: const TextStyle(fontSize: 12)),
          ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            child: Text(row.returnDate,
                style: const TextStyle(fontSize: 12)),
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
          onSelected: (_) {},
          itemBuilder: (_) => [
            PopupMenuItem(
              enabled: false,
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: _statusColor(row.status),
                        shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(_statusLabel(row.status),
                      style: TextStyle(
                          color: _statusColor(row.status),
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            PopupMenuItem(
              enabled: false,
              child: Text('Выдача #${row.idLoan}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 13)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _H extends StatelessWidget {
  final String t;
  const _H(this.t);
  @override
  Widget build(BuildContext context) => Text(t,
      style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
}
