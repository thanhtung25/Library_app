import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => Container(
    color: Colors.purple.shade50,
    child: const Center(child: Text('Sách online đã lưu và đánh dấu', style: TextStyle(fontSize: 18))),
  );
}
