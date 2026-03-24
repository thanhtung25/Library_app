import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/reservation/bloc.dart';

import '../../api_localhost/AuthService.dart';
import '../../api_localhost/BookService.dart';
import '../../bloc/book/bloc.dart';
import '../../bloc/reservation/event.dart';
import '../../model/user_model.dart';
import 'Books/book_card.dart';

class HomeTab extends StatefulWidget {
  final UserModel user;
  final Function(int) onChangeTab;
  const HomeTab({super.key, required this.user, required this.onChangeTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<UserModel> futureUser;
  @override
  void initState() {
    super.initState();
    futureUser = AuthService().getUserbyId(widget.user.id_user);
    context.read<BookBloc>().add(GetBookEvent());
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(30, 70, 30, 0),
          color: Color(0xffFBEEE4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Avatar tròn
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: AssetImage('assets/images/lich.png'),
                    // hoặc dùng NetworkImage nếu là ảnh lấy từ web
                    backgroundColor: Colors.white,
                  ),
                  const SizedBox(width: 20),
                  FutureBuilder(
                    future: futureUser,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Text("...");
                      }
                      return Text(
                        'Hi, ${snapshot.data!.fullName}!',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontWeight: FontWeight.w600,
                          fontSize: 26,
                          color: Colors.brown.shade800,
                        ),
                      );
                    }
                  ),
                ],
              ),
              SizedBox(
                height: 18,
              ),
              Container(
                decoration: BoxDecoration(
                  color:  Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "Юношеская библиотека – это современный информационно-культурный центр, ориентированный "
                        "на удовлетворение образовательных, познавательных и досуговых потребностей подростков и "
                        "молодежи. Библиотека предоставляет доступ к художественной, учебной, научно-популярной и "
                        "справочной литературе, а также создает комфортные условия для чтения, самообразования и "
                        "культурного развития пользователей.",
                    textAlign: TextAlign.justify,
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.normal
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Рекомендуется',
                    textAlign: TextAlign.start,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                  TextButton(onPressed: (){
                    if (widget.onChangeTab != null) {
                      widget.onChangeTab(1);
                    } }, child: Row(
                    children: [
                      Text(
                        'View all',
                        textAlign: TextAlign.start,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.normal,
                          color: Color(0xffFF9E74),
                        ),
                      ),
                      Icon(Icons.arrow_right, color: Color(0xffFF9E74)),
                    ],
                  ),),

                ],
              ),
              SizedBox(
                child: BlocBuilder<BookBloc, BookState>(
                  builder: (context, state) {
                    if (state is BookLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (state is BookError) {
                      return Text(state.message);
                    }
                    if (state is BookSuccess) {
                      final books = state.books;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      child: Row(
                        children: books.map((book) {
                          return BookCard(
                            book: book,
                            user: widget.user,
                            authorFuture:  bookService().getAuthorByID(book.id_author),
                            onReload: () {
                              context.read<BookBloc>().add(GetBookEvent());
                            },
                              onReservationLoad:(){
                                context.read<ReservationBloc>().add(GetReservationsByUserEvent(widget.user.id_user));
                              }
                          );
                        }).toList(),
                      ),
                    );
                  }
                    return Container();
                    },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
