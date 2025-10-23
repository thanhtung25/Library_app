import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:library_app/page/Home_page/home_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailControler =  TextEditingController();
  final TextEditingController _passControler =  TextEditingController();
  @override
  Widget build(BuildContext context) {
    // ignore: prefer_typing_uninitialized_variables
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
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
                'Welcome to Library Mirea!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xffFF9E74),
                ),
              ),
              const Text(
                'Login to continue using Library!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Times New Roman',
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: Color(0xffFF9E74),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 145, 10, 20),
                child: TextField(
                  controller: _emailControler,
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
                    'Forgot password?',
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
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 60),
                child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xffFF9E74),
                      onPressed: () async {
                        final username = _emailControler.text.trim();
                        final password = _passControler.text;

                        if (username.isEmpty || password.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập tài khoản và mật khẩu')),
                          );
                          return;
                        }

                        final user = await login(username, password);

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tài khoản hoặc mật khẩu không đúng')),
                          );
                          return;
                        }

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
                        );
                      },
                      child: const Text(
                        'Login',
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
                text: TextSpan(
                    text: 'New user? ',
                    style: const TextStyle(
                        fontFamily: 'Times New Roman',
                        fontSize: 16,
                        color: Color(0xff606470)
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        recognizer: TapGestureRecognizer()..onTap =() =>  Navigator.pushNamed(context, '/register'),

                          text: ' Sign up for a new account',
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

    );
  }
}

Future<Map<String, dynamic>?> login(String username, String password) async {
  await Future.delayed(Duration(milliseconds: 500)); // Giả lập chậm mạng

  final user = users.firstWhere(
        (u) => u['username'] == username && u['password'] == password,
    orElse: () => {},
  );

  return user.isNotEmpty ? user : null;
}


final List<Map<String, dynamic>> users = [
  {
    'user_id': 1,
    'full_name': 'Nguyễn Văn A',
    'birth_date': DateTime(2000, 5, 12),
    'gender': 'male',
    'email': 'vana@student.mirea.edu',
    'phone': '0912345678',
    'role': 'student',
    'username': '1',
    'password': '1'
  },
  {
    'user_id': 3,
    'full_name': 'Phạm Văn C',
    'birth_date': DateTime(1980, 11, 4),
    'gender': 'male',
    'email': 'vanc@teacher.mirea.edu',
    'phone': '0911222333',
    'role': 'teacher',
    'username': '2',
    'password': '2'
  },
  {
    'user_id': 5,
    'full_name': 'Hoàng Văn E',
    'birth_date': DateTime(1975, 7, 10),
    'gender': 'male',
    'email': 'hoange@library.mirea.edu',
    'phone': '0933444555',
    'role': 'librarian',
    'username': '3',
    'password': '3'
  }
];


