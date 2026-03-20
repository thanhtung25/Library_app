import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/auth/event.dart';
import 'package:library_app/bloc/auth/state.dart';

import '../../Router/AppRoutes.dart';
import '../../api_localhost/AuthService.dart';
import '../../bloc/auth/bloc.dart';
import '../../model/user_model.dart';
import 'dart:math';

class PersonInfoScreen extends StatefulWidget {
  final UserModel user;

  const PersonInfoScreen({super.key, required this.user});

  @override
  State<PersonInfoScreen> createState() => _PersonInfoScreenState();
}

class _PersonInfoScreenState extends State<PersonInfoScreen> {

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _addressControler = TextEditingController();
  TextEditingController _birthController = TextEditingController();
  DateTime? _selectedBirthDate;
  String? _selectedGender;
  String? _selectedRole;

  final List<String> genders = ['Мужской', 'Женский'];
  final List<String> roles = ['reader', 'librarian'];

  late UserModel user;

  @override
  void initState() {
    super.initState();
    user = widget.user;
  }

  String generateLibraryCard() {
    final rand = Random();
    return "CARD${100000 + rand.nextInt(900000)}";
  }


  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthDate = pickedDate;
        _birthController.text =
        "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
      });
    }
  }

  void register() {
    user = user.copyWith(
      fullName: _fullNameController.text.trim(),
      gender: _selectedGender!,
      birth_day: _selectedBirthDate,
      address: _addressControler.text.trim(),
      avatar_url: '',
      library_card: generateLibraryCard(),
      role: _selectedRole!,
    );
    context.read<AuthBloc>().add(
      RegisterSubmitted(
          fullName: user.fullName,
          username: user.username,
          password: user.password,
          role: user.role,
          email: user.email,
          gender: user.gender,
          birthDay: user.birth_day?.toIso8601String().split('T')[0],
          phone: user.phone,
          status: user.status,
          createdAt: user.created_at?.toIso8601String(),
          libraryCard: user.library_card,
          address: user.address,
          avatarUrl: user.avatar_url

      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFBEEE4),
        iconTheme: const IconThemeData(color: Color(0xffFF715D)),
        elevation: 0,
        title: const Text(
          'Персональная информация',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xffFF715D),
          ),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // TODO: implement listener}
          if (state is AuthSuccess) {
            print("Dang ky thanh cong");
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.home,
              arguments: state.user,
            );
          }
          if (state is AuthError) {

            ScaffoldMessenger.of(context)
                .showSnackBar(
              SnackBar(
                content: Text(state.message),
              ),
            );
          }
        },
        child: Container(
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
                      labelText: "Полное имя",
                      prefixIcon: SizedBox(
                          width: 50, child: Icon(Icons.person)),
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
                    controller: _birthController,
                    readOnly: true,
                    onTap: () {
                      _selectDate(context);
                    },
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
                      labelText: "Дата рождения",
                      prefixIcon: SizedBox(
                        width: 50,
                        child: Icon(Icons.calendar_month),
                      ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      labelText: 'Пол',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGender,
                        hint: const Text('Выберите пол'),
                        isExpanded: true,
                        items: genders.map((String gender) {
                          return DropdownMenuItem<String>(
                            value: gender,
                            child: Text(
                              gender,
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 20,
                                color: Color(0xffFF9E74),
                              ),
                            ),
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      labelText: 'Роль',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(color: Colors.white, width: 1),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedRole,
                        hint: const Text('Выберите роль'),
                        isExpanded: true,
                        items: roles.map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                              role,
                              style: const TextStyle(
                                fontFamily: 'Times New Roman',
                                fontSize: 20,
                                color: Color(0xffFF9E74),
                              ),
                            ),
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
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                  child: TextField(
                    controller: _addressControler,
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
                      labelText: "Введите адрес",
                      prefixIcon: SizedBox(
                          width: 50, child: Icon(Icons.home_filled)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                        borderSide: BorderSide(color: Colors.white, width: 1),
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
                        //submitRegister();
                        register();
                      },
                      child: const Text(
                        'Сохраните информацию',
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
      ),
    );
  }
}
