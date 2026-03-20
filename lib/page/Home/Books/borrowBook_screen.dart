import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BorrowbookScreen extends StatefulWidget {
  const BorrowbookScreen({super.key});

  @override
  State<BorrowbookScreen> createState() => _BorrowbookScreenState();
}

class _BorrowbookScreenState extends State<BorrowbookScreen> {


  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green.shade50,
      child: const Center(child: Text('borrow', style: TextStyle(fontSize: 18))),
    );
  }
}
