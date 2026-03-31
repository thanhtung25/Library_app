import 'package:flutter/material.dart';

const Color  kLoanOrange = Color(0xffFF9E74);
const Color  kLoanBg     = Color(0xffFBEEE4);
const double kFinePerDay = 5000; // VNĐ / ngày quá hạn

Color loanStatusColor(String s) {
  switch (s) {
    case 'reserved': return Colors.purple;
    case 'borrowed': return Colors.orange;
    case 'returned': return Colors.green;
    case 'overdue':  return Colors.red;
    default:         return Colors.grey;
  }
}

String loanStatusLabel(String s) {
  switch (s) {
    case 'reserved': return 'Đặt trước';
    case 'borrowed': return 'Đang mượn';
    case 'returned': return 'Đã trả';
    case 'overdue':  return 'Quá hạn';
    default:         return s;
  }
}

String loanFmtDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}'
        '-${d.day.toString().padLeft(2, '0')}';

String loanTodayStr() => loanFmtDate(DateTime.now());

String loanFormatMoney(double v) {
  final s   = v.toStringAsFixed(0);
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return buf.toString();
}
