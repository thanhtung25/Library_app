import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:library_app/page/Login_Register_Page/person_info_screen.dart';

import '../../model/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _nameControler =  TextEditingController();
  final TextEditingController _emailControler =  TextEditingController();
  final TextEditingController _passControler =  TextEditingController();
  final TextEditingController _phoneControler =  TextEditingController();
  @override
  void dispose() {
    _nameControler.dispose();
    _emailControler.dispose();
    _passControler.dispose();
    _phoneControler.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xffFBEEE4),
        iconTheme: const IconThemeData(color: Color(0xffFF715D)),
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
        constraints: const BoxConstraints.expand(),
        color: const Color(0xffFBEEE4),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              const SizedBox(height: 20,),
              const Text(
                'Добро пожаловать в библиотеку',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffFF715D),
                ),
              ),
              const Text(
                'Зарегистрируйтесь в библиотеке в несколько простых шагов. ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: Color(0xffFF715D),

                ),
              ),

              Padding(
                padding:const EdgeInsets.fromLTRB(10,30,10,20),
                child: TextField(
                  controller: _nameControler,
                  style:const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xffFF9E74),
                  ),
                  decoration: InputDecoration(
                      //errorText: snapshot.hasError ? '${snapshot.error}' : null,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding:const EdgeInsets.all(10),
                      labelText: "User Name",
                      prefixIcon:const SizedBox(
                        width: 50,child: Icon(Icons.person),
                      ),
                      border:const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white,width: 1)
                      )
                  ),
                ),
              ),

              Padding(
                padding:const EdgeInsets.fromLTRB(10,0,10,20),
                child: TextField(
                  controller: _phoneControler,
                  style:const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xffFF9E74),
                  ),
                  decoration: InputDecoration(
                      //errorText: snapshot.hasError ? '${snapshot.error}' : null,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding:const EdgeInsets.all(10),
                      labelText: "Phone Number",
                      prefixIcon:const SizedBox(
                        width: 50,child: Icon(Icons.phone),
                      ),
                      border:const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white,width: 1)
                      )
                  ),
                ),
              ),

              Padding(
                padding:const EdgeInsets.fromLTRB(10,0,10,20),
                child: TextField(
                  controller: _emailControler,
                  style:const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xffFF9E74),
                  ),
                  decoration: InputDecoration(
                      //errorText: snapshot.hasError ? '${snapshot.error}' : null,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding: const EdgeInsets.all(10),
                      labelText: "Email",
                      prefixIcon:const SizedBox(
                        width: 50,child: Icon(Icons.mail),
                      ),
                      border:const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white,width: 1)
                      )
                  ),
                ),
              ),
              Padding(
                padding:const EdgeInsets.fromLTRB(10,0,10,20),
                child: TextField(
                  controller: _passControler,
                  obscureText: true,
                  style:const TextStyle(
                    fontFamily: 'Times New Roman',
                    fontSize: 20,
                    fontWeight: FontWeight.normal,
                    color: Color(0xffFF9E74),
                  ),
                  decoration: InputDecoration(
                      //errorText: snapshot.hasError ? '${snapshot.error}' : null,
                      fillColor: Colors.white,
                      filled: true,
                      contentPadding:const EdgeInsets.all(10),
                      labelText: "Password",
                      prefixIcon:const SizedBox(
                        width: 50,child: Icon(Icons.vpn_key),
                      ),
                      border:const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(20)),
                          borderSide: BorderSide(color: Colors.white,width: 1)
                      )
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20,20,20,60),
                child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xffFF715D),
                      onPressed: (){
                        final user = UserModel(
                          id_user: 0,
                          fullName: '',
                          birth_day: null,
                          gender: '',
                          email: _emailControler.text.trim(),
                          phone: _phoneControler.text.trim(),
                          username: _nameControler.text.trim(),
                          password: _passControler.text.trim(),
                          status: 'active',
                          created_at: DateTime.now(),
                          library_card: '',
                          address: '',
                          avatar_url: '',
                          role: '',
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PersonInfoScreen(user: user),
                          ),
                        );
                      },
                      child:const Text(
                        'Регистратор',
                        style: TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                ),
              ),

              RichText(
                text:  TextSpan(
                    text: 'Уже пользователь?',
                    style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        color: Color(0xff606470)
                    ),
                    children: <TextSpan>[
                      TextSpan(
                          recognizer: TapGestureRecognizer()..onTap =() => Navigator.pushNamed(context, '/login'),
                          text: 'Войти сейчас',
                          style:const TextStyle(
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

    );
  }
}
