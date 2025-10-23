import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PersonInfoScreen extends StatefulWidget {
  const PersonInfoScreen({super.key});

  @override
  State<PersonInfoScreen> createState() => _PersonInfoScreenState();
}

class _PersonInfoScreenState extends State<PersonInfoScreen> {
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  String? _selectedRole;

  final List<String> genders = ['Nam', 'Nữ'];
  final List<String> roles = ['student', 'teacher'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFBEEE4),
        iconTheme: const IconThemeData(color: Color(0xffFF715D)),
        elevation: 0,
        title: const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xffFF715D),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(30, 20, 30, 0),
        constraints: const BoxConstraints.expand(),
        color: const Color(0xffFBEEE4),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 30, 10, 20),
                child: TextField(
                  controller: _fullNameController,
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xffFF9E74),
                  ),
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: EdgeInsets.all(10),
                    labelText: "Họ và tên",
                    prefixIcon: SizedBox(width: 50, child: Icon(Icons.person)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: TextField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xffFF9E74),
                  ),
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: EdgeInsets.all(10),
                    labelText: "Tuổi",
                    prefixIcon: SizedBox(width: 50, child: Icon(Icons.cake)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    labelText: 'Giới tính',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGender,
                      hint: const Text('Chọn giới tính'),
                      isExpanded: true,
                      items: genders.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender,
                              style: const TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontSize: 20,
                                  color: Color(0xffFF9E74))),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 20),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    labelText: 'Vai trò',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      borderSide: BorderSide(color: Colors.white, width: 1),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      hint: const Text('Chọn vai trò'),
                      isExpanded: true,
                      items: roles.map((String role) {
                        return DropdownMenuItem<String>(
                          value: role,
                          child: Text(role,
                              style: const TextStyle(
                                  fontFamily: 'Times New Roman',
                                  fontSize: 20,
                                  color: Color(0xffFF9E74))),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      },
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: FloatingActionButton(
                    backgroundColor: const Color(0xffFF715D),
                    onPressed: () {
                      if (_fullNameController.text.isEmpty ||
                          _ageController.text.isEmpty ||
                          _selectedGender == null ||
                          _selectedRole == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin")));
                        return;
                      }
                      final age = int.tryParse(_ageController.text);
                      if (age == null || age <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Tuổi không hợp lệ")));
                        return;
                      }
                      // Xử lý thông tin ở đây (gửi lên backend, lưu state...)
                      // Ví dụ điều hướng về home theo role
                      Navigator.pushReplacementNamed(context, '/home', arguments: {
                        'role': _selectedRole,
                      });
                    },
                    child: const Text(
                      'Lưu thông tin',
                      style: TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
