import 'package:flutter/material.dart';
import 'loan_item.dart';
import 'loan_constants.dart';

// ─── Mobile Header ────────────────────────────────────────────────────────────
class LoanTableHeader extends StatelessWidget {
  const LoanTableHeader({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: kLoanOrange,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    child: const Row(
      children: [
        Expanded(flex: 2, child: _H('ID')),
        Expanded(flex: 3, child: Center(child: _H('User ID'))),
        Expanded(flex: 4, child: Center(child: _H('Дата'))),
        Expanded(flex: 3, child: Center(child: _H('Статус'))),
        SizedBox(width: 44, child: Center(child: _H(''))),
      ],
    ),
  );
}
class _H extends StatelessWidget {
  final String t;
  const _H(this.t, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    t,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    ),
  );
}

// ─── Mobile Row ───────────────────────────────────────────────────────────────
class LoanRow extends StatelessWidget {
  final LoanItem loan;
  final VoidCallback onTap;
  final VoidCallback? onConfirmBorrow;
  final VoidCallback? onDueSoon;
  final VoidCallback? onOverdue;
  final VoidCallback? onMarkReturn;
  final VoidCallback? onDelete;

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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '#${loan.idLoan}',
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Text(
                  '#${loan.idUser}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: Text(
                  loan.issueDate,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 68),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: 44,
              child: Center(
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
                  onSelected: (v) {
                    if (v == 'detail') onTap();
                    if (v == 'confirm') onConfirmBorrow?.call();
                    if (v == 'return') onMarkReturn?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(
                      value: 'detail',
                      child: Text('Подробнее'),
                    ),
                    if (loan.status == 'reserved' && onConfirmBorrow != null)
                      const PopupMenuItem(
                        value: 'confirm',
                        child: Text('Подтвердить выдачу'),
                      ),
                    if (loan.status == 'borrowed' || loan.status == 'overdue')
                      const PopupMenuItem(
                        value: 'return',
                        child: Text('Отметить возврат'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Удалить'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text, {bool bold = false}) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      ),
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _actionBtn(IconData icon, Color color, String tooltip, VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 20, color: color),
          ),
        ),
      );
}

// ─── Web Table ────────────────────────────────────────────────────────────────
class LoanWebTable extends StatelessWidget {
  final List<LoanItem> loans;
  final void Function(LoanItem loan) onOpenDetail;
  final void Function(LoanItem loan) onConfirmBorrow;
  final void Function(LoanItem loan) onDueSoon;
  final void Function(LoanItem loan) onOverdue;
  final void Function(LoanItem loan) onMarkReturn;
  final void Function(LoanItem loan) onDelete;

  const LoanWebTable({
    super.key,
    required this.loans,
    required this.onOpenDetail,
    required this.onConfirmBorrow,
    required this.onDueSoon,
    required this.onOverdue,
    required this.onMarkReturn,
    required this.onDelete,
  });

  static const _headerStyle = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: 13,
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1000),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(kLoanOrange),
                columnSpacing: 20,
                headingRowHeight: 48,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text('№ записи',      style: _headerStyle)),
                  DataColumn(label: Text('Читатель',       style: _headerStyle)),
                  DataColumn(label: Text('Экземпляр',      style: _headerStyle)),
                  DataColumn(label: Text('Дата выдачи',    style: _headerStyle)),
                  DataColumn(label: Text('Срок возврата',  style: _headerStyle)),
                  DataColumn(label: Text('Статус',         style: _headerStyle)),
                  DataColumn(label: Text('Действия',       style: _headerStyle)),
                ],
                rows: loans.map((loan) {
                  final isNear = loan.isNearDeadline;

                  // Имя пользователя или fallback
                  final userName = (loan.userName != null && loan.userName!.trim().isNotEmpty)
                      ? loan.userName!
                      : null;

                  return DataRow(
                    color: MaterialStateProperty.resolveWith((states) {
                      if (isNear) return Colors.orange.withOpacity(0.04);
                      return null;
                    }),
                    cells: [
                      // № записи
                      DataCell(Text(
                        '#${loan.idLoan}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      )),

                      // Читатель — имя жирным + ID серым под ним
                      DataCell(
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName ?? 'Пользователь #${loan.idUser}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: userName != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: userName != null
                                    ? Colors.black87
                                    : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'ID: ${loan.idUser}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),

                      // Экземпляр
                      DataCell(Text('#${loan.idCopy}',
                          style: const TextStyle(fontSize: 13))),

                      // Дата выдачи
                      DataCell(Text(loan.issueDate,
                          style: const TextStyle(fontSize: 12))),

                      // Срок возврата + предупреждение
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              loan.returnDate,
                              style: TextStyle(
                                fontSize: 12,
                                color: isNear ? Colors.orange : Colors.black87,
                                fontWeight: isNear
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (isNear) ...[
                              const SizedBox(width: 4),
                              Tooltip(
                                message: loan.daysUntilReturn == 0
                                    ? 'Срок истекает сегодня!'
                                    : 'Осталось ${loan.daysUntilReturn} дн.',
                                child: const Icon(Icons.warning_amber_rounded,
                                    size: 15, color: Colors.orange),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Статус
                      DataCell(LoanStatusBadge(loan.status)),

                      // Действия
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _webIconBtn(Icons.info_outline, kLoanOrange,
                                'Подробнее', () => onOpenDetail(loan)),
                            if (loan.status == 'reserved')
                              _webIconBtn(Icons.qr_code_2, Colors.purple,
                                  'Подтвердить выдачу', () => onConfirmBorrow(loan)),
                            if (isNear)
                              _webIconBtn(Icons.notifications_active, Colors.orange,
                                  'Напомнить о сроке', () => onDueSoon(loan)),
                            if (loan.status == 'overdue')
                              _webIconBtn(Icons.gavel, Colors.red,
                                  'Создать штраф', () => onOverdue(loan)),
                            if (loan.status == 'borrowed' || loan.status == 'overdue')
                              _webIconBtn(Icons.check_circle_outline, Colors.green,
                                  'Отметить возврат', () => onMarkReturn(loan)),
                            _webIconBtn(Icons.delete_outline, Colors.red,
                                'Удалить запись', () => onDelete(loan)),
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _webIconBtn(
      IconData icon, Color color, String tooltip, VoidCallback onPressed) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      );
}

// ─── Reusable ─────────────────────────────────────────────────────────────────
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        loanStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class LoanChip extends StatelessWidget {
  final String label;
  final Color color;
  const LoanChip(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

class LoanDetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const LoanDetailRow(this.icon, this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      children: [
        Icon(icon, size: 18, color: kLoanOrange),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Times New Roman',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class LoanInfoRow extends StatelessWidget {
  final String label, value;
  const LoanInfoRow(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    ),
  );
}

class LoanDateTile extends StatelessWidget {
  final String label;
  final String? value;
  const LoanDateTile(this.label, this.value, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey.shade400),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: kLoanOrange),
        const SizedBox(width: 8),
        Text(
          value ?? label,
          style: TextStyle(
            color: value != null ? Colors.black87 : Colors.grey,
          ),
        ),
      ],
    ),
  );
}