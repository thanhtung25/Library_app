import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/page/Home/home_screen.dart';

import '../../Router/AppRoutes.dart';
import '../../api_localhost/AuthService.dart';
import '../../bloc/auth/bloc.dart';
import '../../bloc/auth/state.dart';
import '../../bloc/auth/event.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userControler =  TextEditingController();
  final TextEditingController _passControler =  TextEditingController();


  @override
  void dispose() {
    _userControler.dispose();
    _passControler.dispose();
    super.dispose();
  }

  void login() {
    context.read<AuthBloc>().add(
      LoginSubmitted(
        username: _userControler.text.trim(),
        password: _passControler.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // TODO: implement listener}
            if (state is AuthSuccess) {
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
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
        constraints: const BoxConstraints.expand(),
        color: const Color(0xffFBEEE4),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 140,),
              const Image(
                width: 200,
                image: AssetImage('assets/images/lich.png'),
              ),
              const Text(
                'Добро пожаловать в библиотеку!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffFF9E74),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(10, 145, 10, 20),
                child: TextField(
                  controller: _userControler,
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
                      labelText: "User Name",
                      prefixIcon: SizedBox(
                        width: 50, child: Icon(Icons.mail),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white, width: 1)
                      )
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10.0, right: 10),
                child: TextField(
                  controller: _passControler,
                  obscureText: true,
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
                      labelText: "Password",
                      prefixIcon: SizedBox(
                        width: 50, child: Icon(Icons.vpn_key),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white, width: 1)
                      )
                  ),
                ),
              ),

              Container(
                constraints: BoxConstraints.loose(
                    const Size(double.infinity, 40)),
                alignment: AlignmentDirectional.centerEnd,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 10, 0),
                  child: Text(
                    'Забыли пароль?',
                    style: TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 18,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xffFF9E74),
                      onPressed: login,
                        child: Text(
                          'Войти',
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

              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    text: 'Новый пользователь?',
                    style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        color: Color(0xff606470)
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        recognizer: TapGestureRecognizer()..onTap =() =>  Navigator.pushNamed(context, '/register'),

                          text: 'Зарегистрируйте новый аккаунт.',
                          style: const TextStyle(
                            color: Color(0xff3277D8),
                            fontFamily: 'Times New Roman',
                            fontSize: 16,
                          )
                      )
                    ]
                ),
              )
            ],
          ),
        ),
      ),
),

    );
  }
}


