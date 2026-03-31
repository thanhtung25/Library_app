import 'package:flutter/material.dart';
import 'loan_item.dart';
import 'loan_constants.dart';

// ─── Table Header ─────────────────────────────────────────────────────────────
class LoanTableHeader extends StatelessWidget {
  const LoanTableHeader({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: kLoanOrange,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: const Row(children: [
      Expanded(flex: 1, child: _H('ID')),
      Expanded(flex: 2, child: _H('ND')),
      Expanded(flex: 2, child: _H('Bản sao')),
      Expanded(flex: 3, child: _H('Hạn trả')),
      Expanded(flex: 2, child: _H('T.thái')),
      SizedBox(width: 96),
    ]),
  );
}

class _H extends StatelessWidget {
  final String t;
  const _H(this.t, {super.key});
  @override
  Widget build(BuildContext context) => Text(t,
      style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
}

// ─── Loan Row ─────────────────────────────────────────────────────────────────
class LoanRow extends StatelessWidget {
  final LoanItem loan;
  final VoidCallback            onTap;
  final VoidCallback?           onConfirmBorrow;
  final VoidCallback?           onDueSoon;
  final VoidCallback?           onOverdue;
  final VoidCallback?           onMarkReturn;
  final VoidCallback?           onDelete;

  const LoanRow({
    super.key,
    required this.loan,
    required this.onTap,
    this.onConfirmBorrow,
    this.onDueSoon,
    this.onOverdue,
    this.onMarkReturn,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = loanStatusColor(loan.status);
    final label = loanStatusLabel(loan.status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: loan.isNearDeadline
              ? Colors.orange.withOpacity(0.05)
              : Colors.transparent,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Column(children: [
          // Near-deadline warning banner
          if (loan.isNearDeadline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              color: Colors.orange.withOpacity(0.15),
              child: Row(children: [
                const Icon(Icons.access_time, size: 13, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  loan.daysUntilReturn == 0
                      ? 'Hết hạn hôm nay!'
                      : 'Còn ${loan.daysUntilReturn} ngày đến hạn',
                  style: const TextStyle(
                      color: Colors.orange, fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ]),
            ),

          Row(children: [
            Expanded(flex: 1, child: _cell(loan.idLoan.toString())),
            Expanded(flex: 2, child: _cell(loan.idUser.toString())),
            Expanded(flex: 2, child: _cell(loan.idCopy.toString())),
            Expanded(flex: 3, child: _cell(loan.returnDate)),
            // Status badge
            Expanded(
              flex: 2,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(label,
                    style: TextStyle(
                        color: color, fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            // Action buttons
            SizedBox(
              width: 96,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (loan.status == 'reserved' && onConfirmBorrow != null)
                    _actionBtn(Icons.qr_code_2,             Colors.purple,
                        'Xác nhận phát sách',              onConfirmBorrow!),
                  if (loan.isNearDeadline && onDueSoon != null)
                    _actionBtn(Icons.notifications_active,  Colors.orange,
                        'Gửi nhắc hạn',                    onDueSoon!),
                  if (loan.status == 'overdue' && onOverdue != null)
                    _actionBtn(Icons.gavel,                 Colors.red,
                        'Tạo phạt & thông báo',            onOverdue!),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: Colors.grey),
                    onSelected: (v) {
                      if (v == 'detail')  onTap();
                      if (v == 'return')  onMarkReturn?.call();
                      if (v == 'delete')  onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'detail',
                          child: ListTile(
                              leading: Icon(Icons.info_outline),
                              title: Text('Xem chi tiết'),
                              contentPadding: EdgeInsets.zero)),
                      if (loan.status == 'borrowed' || loan.status == 'overdue')
                        const PopupMenuItem(value: 'return',
                            child: ListTile(
                                leading: Icon(Icons.check_circle_outline,
                                    color: Colors.green),
                                title: Text('Đánh dấu đã trả',
                                    style: TextStyle(color: Colors.green)),
                                contentPadding: EdgeInsets.zero)),
                      const PopupMenuItem(value: 'delete',
                          child: ListTile(
                              leading: Icon(Icons.delete_outline, color: Colors.red),
                              title: Text('Xoá phiếu',
                                  style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero)),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  Widget _cell(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
    child: Text(text,
        style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
  );

  Widget _actionBtn(IconData icon, Color color, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(icon, size: 20, color: color)),
        ),
      );
}

// ─── Reusable small widgets ───────────────────────────────────────────────────

class LoanStatusBadge extends StatelessWidget {
  final String status;
  const LoanStatusBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = loanStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12)),
      child: Text(loanStatusLabel(status),
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}

class LoanChip extends StatelessWidget {
  final String label;
  final Color  color;
  const LoanChip(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
  );
}

/// Dùng trong bottom sheet detail
class LoanDetailRow extends StatelessWidget {
  final IconData icon;
  final String   label, value;
  const LoanDetailRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 18, color: kLoanOrange),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ]),
  );
}

/// Dùng trong dialog (key: value ngang)
class LoanInfoRow extends StatelessWidget {
  final String label, value;
  const LoanInfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    ),
  );
}

/// Date tile cho form dialog
class LoanDateTile extends StatelessWidget {
  final String  label;
  final String? value;
  const LoanDateTile(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(4)),
    child: Row(children: [
      Icon(Icons.calendar_today, size: 16, color: kLoanOrange),
      const SizedBox(width: 8),
      Text(value ?? label,
          style: TextStyle(color: value != null ? Colors.black87 : Colors.grey)),
    ]),
  );
}
