import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';

class _Fine {
  final int idFine;
  final int idLoan;
  final double amount;
  final String reason;
  final String createdAt;
  final String status;

  _Fine({
    required this.idFine,
    required this.idLoan,
    required this.amount,
    required this.reason,
    required this.createdAt,
    required this.status,
  });

  factory _Fine.fromJson(Map<String, dynamic> j) => _Fine(
    idFine: j['id_fine'] ?? 0,
    idLoan: j['id_loan'] ?? 0,
    amount: (j['amount'] ?? 0).toDouble(),
    reason: j['reason'] ?? '',
    createdAt: j['created_at'] ?? '',
    status: j['status'] ?? 'unpaid',
  );
}

class UserFinesScreen extends StatefulWidget {
  final int userId;
  final String userName;

  const UserFinesScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<UserFinesScreen> createState() => _UserFinesScreenState();
}

class _UserFinesScreenState extends State<UserFinesScreen> {
  static const _orange = Color(0xffFF9E74);
  static const _bg = Color(0xffFBEEE4);

  List<_Fine> _fines = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFines();
  }

  Future<void> _fetchFines() async {
    setState(() { _loading = true; _error = null; });
    try {
      // Step 1 – lấy loan IDs của user
      final loansData = await ApiService.get(
          '/loans-management/loan/user/${widget.userId}');
      final rawLoans = loansData is List ? loansData as List : [];
      final loanIds = rawLoans
          .map<int>((e) => (e['id_loan'] ?? 0) as int)
          .toSet(); // dùng Set để lookup O(1)

      // Step 2 – lấy TẤT CẢ fines, filter theo loanIds
      final finesData = await ApiService.get('/fines-management/fines');
      final rawFines = finesData is List ? finesData as List : [];

      final allFines = rawFines
          .map((e) => _Fine.fromJson(e as Map<String, dynamic>))
          .where((f) => loanIds.contains(f.idLoan))
          .toList();

      setState(() {
        _fines = allFines.where((f) => f.status == 'unpaid').toList();
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }


  String _formatMoney(double v) {
    final s = v.toInt().toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return '${buf.toString()} ₫';
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
              'Штрафы и долги',
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
              onPressed: _fetchFines),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
          ? Center(
          child: Text(_error!,
              style: const TextStyle(color: Colors.red)))
          : _fines.isEmpty
          ? _buildEmpty()
          : _buildFinesList(),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/book1.png',
            height: 150,
            opacity: const AlwaysStoppedAnimation(0.5)),
        const SizedBox(height: 20),
        const Text(
          'По данному счету нет\nнепогашенных штрафов',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 16,
              color: Colors.grey),
        ),
      ],
    ),
  );

  Widget _buildFinesList() {
    final total = _fines.fold(0.0, (sum, f) => sum + f.amount);
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Общая сумма долга:',
                style: TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                _formatMoney(total),
                style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _fines.length,
            itemBuilder: (_, i) => _buildFineCard(_fines[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildFineCard(_Fine fine) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Штраф #${fine.idFine}',
                  style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _formatMoney(fine.amount),
                  style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13),
                ),
              ),
            ],
          ),
          if (fine.reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(fine.reason,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.receipt_long,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('Выдача #${fine.idLoan}',
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
              if (fine.createdAt.isNotEmpty) ...[
                const SizedBox(width: 12),
                const Icon(Icons.calendar_today,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(fine.createdAt,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    ),
  );
}
