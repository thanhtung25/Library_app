import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';
import 'package:library_app/model/user_model.dart';

class ReportScreen extends StatefulWidget {
  final UserModel user;
  const ReportScreen({super.key, required this.user});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const _orange = Color(0xffFF9E74);
  static const _bg     = Color(0xffFBEEE4);

  // Report type dropdown (matches design)
  static const _reportTypes = [
    'Báo cáo thống kê mượn / trả',
    'Báo cáo sách quá hạn',
    'Báo cáo người dùng hoạt động',
    'Báo cáo sách phổ biến',
  ];

  String _selectedReport = _reportTypes.first;
  DateTime? _fromDate;
  DateTime? _toDate;

  bool   _loading = false;
  bool   _generated = false;
  Map<String, dynamic>? _reportData;
  String? _error;

  // ── Date picker ─────────────────────────────────────────────────────────────
  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom
        ? (_fromDate ?? DateTime.now().subtract(const Duration(days: 30)))
        : (_toDate ?? DateTime.now());

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _orange),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        if (isFrom) _fromDate = picked;
        else        _toDate   = picked;
      });
    }
  }

  String _fmt(DateTime? d) => d == null
      ? 'Chọn ngày'
      : '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  // ── Generate report ─────────────────────────────────────────────────────────
  Future<void> _generateReport() async {
    setState(() { _loading = true; _error = null; _generated = false; });
    try {
      final params = StringBuffer('/reports-management/report?type=$_selectedReport');
      if (_fromDate != null) params.write('&from=${_fmt(_fromDate)}');
      if (_toDate   != null) params.write('&to=${_fmt(_toDate)}');

      final data = await ApiService.get(params.toString());
      setState(() {
        _reportData = data as Map<String, dynamic>?;
        _loading   = false;
        _generated = true;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // ── Export (calls backend endpoint that returns file) ──────────────────────
  Future<void> _export(String format) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đang xuất $format...'),
          backgroundColor: _orange,
        ),
      );
      await ApiService.get(
        '/reports-management/export?type=$_selectedReport&format=$format',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Xuất $format thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
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
          'Báo cáo & Tài liệu',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
            color: _orange,
            fontSize: 22,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Report type dropdown (matches design) ────────────────────────
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _orange),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: _selectedReport,
                  icon: const Icon(Icons.keyboard_arrow_down, color: _orange),
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  onChanged: (v) => setState(() => _selectedReport = v!),
                  items: _reportTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Date range ──────────────────────────────────────────────────
            Row(
              children: [
                Expanded(child: _dateTile(label: 'Từ ngày', isFrom: true)),
                const SizedBox(width: 12),
                Expanded(child: _dateTile(label: 'Đến ngày', isFrom: false)),
              ],
            ),

            const SizedBox(height: 20),

            // ── Action buttons (matches design) ─────────────────────────────
            _actionButton(
              label: 'Tạo báo cáo',
              color: _orange,
              icon: Icons.analytics_rounded,
              onTap: _loading ? null : _generateReport,
              loading: _loading,
            ),
            const SizedBox(height: 12),
            _actionButton(
              label: 'Xuất Excel',
              color: Colors.green.shade600,
              icon: Icons.table_chart_rounded,
              onTap: _generated ? () => _export('excel') : null,
            ),
            const SizedBox(height: 12),
            _actionButton(
              label: 'Tải xuống PDF',
              color: Colors.blue.shade600,
              icon: Icons.picture_as_pdf_rounded,
              onTap: _generated ? () => _export('pdf') : null,
            ),

            // ── Error ─────────────────────────────────────────────────────
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                  textAlign: TextAlign.center),
            ],

            // ── Report preview ────────────────────────────────────────────
            if (_generated && _reportData != null) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Kết quả báo cáo',
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: _orange,
                ),
              ),
              const SizedBox(height: 10),
              _reportPreview(),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _dateTile({required String label, required bool isFrom}) {
    return GestureDetector(
      onTap: () => _pickDate(isFrom: isFrom),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: _orange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  Text(
                    isFrom ? _fmt(_fromDate) : _fmt(_toDate),
                    style: const TextStyle(
                        fontFamily: 'Times New Roman', fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required Color color,
    required IconData icon,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    final disabled = onTap == null;
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? Colors.grey.shade300 : color,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          elevation: disabled ? 0 : 2,
        ),
        onPressed: onTap,
        icon: loading
            ? const SizedBox(
            width: 20, height: 20,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2))
            : Icon(icon, color: disabled ? Colors.grey : Colors.white),
        label: Text(
          label,
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: disabled ? Colors.grey : Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _reportPreview() {
    final entries = _reportData!.entries.toList();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) => ListTile(
          dense: true,
          title: Text(entries[i].key,
              style: const TextStyle(fontFamily: 'Times New Roman',
                  fontWeight: FontWeight.w600)),
          trailing: Text(entries[i].value.toString(),
              style: const TextStyle(color: _orange,
                  fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}