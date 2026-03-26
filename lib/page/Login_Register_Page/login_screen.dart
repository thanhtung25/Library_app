import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/localization/app_localizations.dart';

import '../../Router/AppRoutes.dart';
import '../../bloc/auth/bloc.dart';
import '../../bloc/auth/event.dart';
import '../../bloc/auth/state.dart';

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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr(state.message)),
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
              Text(
                context.tr('login.welcome'),
                textAlign: TextAlign.center,
                style: const TextStyle(
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
                  decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.all(10),
                      labelText: context.tr('login.username_label'),
                      prefixIcon: const SizedBox(
                        width: 50, child: Icon(Icons.mail),
                      ),
                      border: const OutlineInputBorder(
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
                  decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: EdgeInsets.all(10),
                      labelText: context.tr('login.password_label'),
                      prefixIcon: const SizedBox(
                        width: 50, child: Icon(Icons.vpn_key),
                      ),
                      border: const OutlineInputBorder(
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
                child: Padding(
                  padding: EdgeInsets.fromLTRB(0, 10, 10, 0),
                  child: Text(
                    context.tr('login.forgot_password'),
                    style: const TextStyle(
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
                          context.tr('login.submit'),
                          style: const TextStyle(
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
                    text: context.tr('login.new_user'),
                    style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        color: Color(0xff606470)
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        recognizer: TapGestureRecognizer()..onTap =() =>  Navigator.pushNamed(context, '/register'),

                          text: context.tr('login.register_now'),
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


