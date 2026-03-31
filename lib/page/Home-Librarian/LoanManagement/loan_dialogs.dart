import 'package:flutter/material.dart';
import 'loan_item.dart';
import 'loan_constants.dart';
import 'loan_widgets.dart';

// ─── 1. Confirm Borrow — hiện QR + barcode ────────────────────────────────────
Future<bool?> showConfirmBorrowDialog(
    BuildContext context,
    LoanItem loan, {
      required String barcode,
      required String qrVal,
    }) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(children: [
        const Icon(Icons.qr_code_2, color: kLoanOrange),
        const SizedBox(width: 8),
        Expanded(
          child: Text('Xác nhận phát sách #${loan.idLoan}',
              style: const TextStyle(
                  fontFamily: 'Times New Roman',
                  color: kLoanOrange, fontSize: 16)),
        ),
      ]),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Quét mã để xác nhận người dùng nhận sách:',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            // QR code qua network (không cần thêm package)
            if (qrVal.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'https://api.qrserver.com/v1/create-qr-code/'
                      '?size=180x180&data=${Uri.encodeComponent(qrVal)}',
                  width: 180, height: 180,
                  errorBuilder: (_, __, ___) =>
                  const Icon(Icons.qr_code, size: 80, color: Colors.grey),
                ),
              ),
            const SizedBox(height: 12),
            // Barcode dạng text
            if (barcode.isNotEmpty) ...[
              const Text('Barcode:',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(barcode,
                    style: const TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.white,
                        fontSize: 18,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold)),
              ),
            ],
            const SizedBox(height: 10),
            LoanInfoRow('Người dùng', '#${loan.idUser}'),
            LoanInfoRow('Bản sao',    '#${loan.idCopy}'),
            LoanInfoRow('Hạn trả',    loan.returnDate),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: kLoanOrange),
          icon: const Icon(Icons.check, color: Colors.white, size: 18),
          label: const Text('Xác nhận phát sách',
              style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
}

// ─── 2. Overdue — tạo phạt + thông báo ───────────────────────────────────────
Future<bool?> showOverdueDialog(BuildContext context, LoanItem loan) {
  final days   = loan.daysOverdue;
  final amount = days * kFinePerDay;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.warning_amber_rounded, color: Colors.red),
        SizedBox(width: 8),
        Text('Xử lý quá hạn',
            style: TextStyle(fontFamily: 'Times New Roman', color: Colors.red)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LoanInfoRow('Phiếu mượn',      '#${loan.idLoan}'),
          LoanInfoRow('Người dùng',      '#${loan.idUser}'),
          LoanInfoRow('Hạn trả',         loan.returnDate),
          LoanInfoRow('Số ngày quá hạn', '$days ngày'),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tiền phạt:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text('${loanFormatMoney(amount)} VNĐ',
                  style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Text('(${loanFormatMoney(kFinePerDay)} VNĐ × $days ngày)',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          icon: const Icon(Icons.send, color: Colors.white, size: 18),
          label: const Text('Tạo phạt + Gửi thông báo',
              style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
}

// ─── 3. Due soon — nhắc hạn ──────────────────────────────────────────────────
Future<bool?> showDueSoonDialog(BuildContext context, LoanItem loan) {
  final days = loan.daysUntilReturn;
  final msg  = days == 0
      ? 'Phiếu mượn #${loan.idLoan}: Hôm nay là ngày cuối hạn trả '
      'bản sao #${loan.idCopy}. Vui lòng trả sách ngay!'
      : 'Phiếu mượn #${loan.idLoan}: Còn $days ngày đến hạn trả '
      'bản sao #${loan.idCopy} (hạn: ${loan.returnDate}).';

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(children: [
        Icon(Icons.notifications_active, color: Colors.orange),
        SizedBox(width: 8),
        Text('Gửi nhắc hạn',
            style: TextStyle(
                fontFamily: 'Times New Roman', color: Colors.orange)),
      ]),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LoanInfoRow('Người dùng', '#${loan.idUser}'),
          LoanInfoRow('Hạn trả',   loan.returnDate),
          LoanInfoRow('Còn lại',   days == 0 ? 'Hôm nay!' : '$days ngày'),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3))),
            child: Text(msg,
                style: const TextStyle(fontSize: 13, color: Colors.black87)),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey))),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          icon: const Icon(Icons.send, color: Colors.white, size: 18),
          label: const Text('Gửi thông báo',
              style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );
}

// ─── 4. Mark returned ────────────────────────────────────────────────────────
Future<bool?> showMarkReturnedDialog(BuildContext context, LoanItem loan) =>
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận trả sách',
            style: TextStyle(fontFamily: 'Times New Roman')),
        content: Text(
            'Người dùng #${loan.idUser} trả bản sao #${loan.idCopy}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kLoanOrange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

// ─── 5. Delete ────────────────────────────────────────────────────────────────
Future<bool?> showDeleteLoanDialog(BuildContext context, LoanItem loan) =>
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá phiếu mượn',
            style: TextStyle(
                color: Colors.red, fontFamily: 'Times New Roman')),
        content: Text('Xoá phiếu mượn #${loan.idLoan}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

// ─── 6. Add loan form — trả về data map hoặc null ────────────────────────────
Future<Map<String, dynamic>?> showAddLoanFormDialog(
    BuildContext context) async {
  final userCtrl = TextEditingController();
  final copyCtrl = TextEditingController();
  DateTime? issueDate, returnDate;
  String selectedStatus = 'reserved';
  final formKey = GlobalKey<FormState>();

  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDlg) => AlertDialog(
        title: const Text('Tạo phiếu mượn',
            style: TextStyle(
                fontFamily: 'Times New Roman', color: kLoanOrange)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(userCtrl, 'ID Người dùng', TextInputType.number),
                const SizedBox(height: 10),
                _field(copyCtrl, 'ID Bản sao sách', TextInputType.number),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Trạng thái ban đầu',
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: kLoanOrange)),
                  ),
                  items: const [
                    DropdownMenuItem(
                        value: 'reserved', child: Text('Đặt trước')),
                    DropdownMenuItem(
                        value: 'borrowed', child: Text('Đang mượn')),
                  ],
                  onChanged: (v) => setDlg(() => selectedStatus = v!),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final p = await _pickDate(ctx, DateTime.now());
                    if (p != null) setDlg(() => issueDate = p);
                  },
                  child: LoanDateTile('Ngày mượn',
                      issueDate != null ? loanFmtDate(issueDate!) : null),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final p = await _pickDate(
                        ctx, DateTime.now().add(const Duration(days: 14)));
                    if (p != null) setDlg(() => returnDate = p);
                  },
                  child: LoanDateTile('Hạn trả',
                      returnDate != null ? loanFmtDate(returnDate!) : null),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Huỷ',
                  style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kLoanOrange),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              if (issueDate == null || returnDate == null) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Vui lòng chọn ngày mượn và hạn trả'),
                    backgroundColor: Colors.red));
                return;
              }
              Navigator.pop(ctx, {
                'id_user':       int.tryParse(userCtrl.text.trim()),
                'id_copy':       int.tryParse(copyCtrl.text.trim()),
                'issue_date':    loanFmtDate(issueDate!),
                'return_date':   loanFmtDate(returnDate!),
                'status':        selectedStatus,
                'renewal_count': 0,
              });
            },
            child: const Text('Tạo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

// ─── 7. Detail bottom sheet ───────────────────────────────────────────────────
void showLoanDetailSheet(BuildContext context, LoanItem loan) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 14),
          Row(children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: kLoanOrange.withOpacity(0.2),
              child: const Icon(Icons.swap_horiz_rounded,
                  color: kLoanOrange, size: 24),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Phiếu mượn #${loan.idLoan}',
                  style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              LoanStatusBadge(loan.status),
            ]),
          ]),
          const SizedBox(height: 12),
          const Divider(),
          LoanDetailRow(Icons.person,         'Người dùng',       '#${loan.idUser}'),
          LoanDetailRow(Icons.book_outlined,  'Bản sao sách',     '#${loan.idCopy}'),
          LoanDetailRow(Icons.calendar_today, 'Ngày mượn',        loan.issueDate),
          LoanDetailRow(Icons.event,          'Hạn trả',          loan.returnDate),
          if (loan.actualReturnDate != null)
            LoanDetailRow(Icons.check_circle_outline,
                'Ngày trả thực tế', loan.actualReturnDate!),
          LoanDetailRow(Icons.replay, 'Số lần gia hạn',
              '${loan.renewalCount}'),
          if (loan.status == 'overdue')
            LoanDetailRow(Icons.money_off, 'Tiền phạt dự kiến',
                '${loanFormatMoney(loan.daysOverdue * kFinePerDay)} VNĐ '
                    '(${loan.daysOverdue} ngày)'),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

// ── Private helpers ────────────────────────────────────────────────────────────
TextFormField _field(
    TextEditingController ctrl, String label, TextInputType type) =>
    TextFormField(
      controller: ctrl,
      keyboardType: type,
      validator: (v) =>
      (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: kLoanOrange)),
      ),
    );

Future<DateTime?> _pickDate(BuildContext ctx, DateTime initial) =>
    showDatePicker(
      context: ctx,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
            colorScheme: const ColorScheme.light(primary: kLoanOrange)),
        child: child!,
      ),
    );
