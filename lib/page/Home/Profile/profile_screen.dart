import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => Container(
    color: Colors.teal.shade50,
    child: const Center(child: Text('profile', style: TextStyle(fontSize: 18))),
  );
}
