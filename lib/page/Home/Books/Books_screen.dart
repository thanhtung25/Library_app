import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/category/event.dart';
import 'package:library_app/bloc/category/state.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/state.dart';
import 'package:library_app/model/user_model.dart';
import '../../../Router/AppRoutes.dart';
import '../../../api_localhost/BookService.dart';
import '../../../bloc/category/bloc.dart';
import '../../../bloc/reservation/event.dart';
import '../../../model/book_model.dart';
import 'book_card.dart';

class BooksScreen extends StatefulWidget {
  final UserModel user;
  const BooksScreen({super.key, required this.user});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _search = TextEditingController();
  @override
  void initState() {
    super.initState();
    context.read<BookBloc>().add(GetBookEvent());
    context.read<CategoryBloc>().add(GetCategoriesHasBookEvent());
    context.read<ReservationBloc>().add(GetReservationsByUserEvent(widget.user.id_user));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          color: Colors.green.shade50,
          padding: const EdgeInsets.fromLTRB(30, 70, 30, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        style: const TextStyle(
                          fontFamily: 'Times New Roman',
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          contentPadding: EdgeInsets.all(10),
                          labelText: "Search..........",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                            borderSide: BorderSide(color: Color(0xffFF9E74), width: 1),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white, // hoặc màu nền tùy thích
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Color(0xffFF9E74), blurRadius: 3),
                          ],
                        ),
                        child: IconButton(
                          onPressed: () {},
                          icon: Icon(
                            Icons.search,
                            color: Color(0xffFF9E74),
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                     Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.cardRecervation,
                                arguments: widget.user,
                              );
                            },
                            icon: const Icon(
                              Icons.shopping_cart,
                              color: Color(0xffFF9E74),
                              size: 26,
                            ),
                          ),
                          BlocBuilder<ReservationBloc, ReservationState>(
                        builder: (context, state) {
                          if(state is ReservationLoading){
                            return const CircularProgressIndicator();
                          }
                          if(state is ReservationError){ return Text(state.error);}
                          if(state is ReservationLoaded){
                            final reservation = state.reservations;
                            return Positioned(
                              right: 4,
                              top: 4,
                              child: Container(
                                width: 18,
                                height: 18,
                                alignment: Alignment.center,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child:  Text(
                                  reservation.length.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          }
                          return Container();
                        },
                        ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                decoration: BoxDecoration(// nền ngoài
                  borderRadius: BorderRadius.circular(25),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _item("Категории"),
                      _item("Где ищутся"),
                      _item("Язык"),
                      _item("Страна"),
                    ],
                  ),
                ),
              ),
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              //   child: Text(
              //     'Популярный',
              //     textAlign: TextAlign.start,
              //     style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500,color: Color(0xffFF9E74)),
              //   ),
              // ),
              //
              // BlocBuilder<BookBloc, BookState>(
              //   builder: (context, state) {
              //     List<BookModel> books = [];
              //
              //     if (state is BookLoading) {
              //       return const Center(
              //         child: CircularProgressIndicator(),
              //       );
              //     }
              //
              //     if (state is BookError) {
              //       return Text(state.message);
              //     }
              //
              //     if (state is BookSuccess) {
              //       books = state.books;
              //     } else if (state is BookByCategorySuccess) {
              //       books = state.allBooks;
              //     }
              //
              //     if (books.isEmpty) {
              //       return const SizedBox.shrink();
              //     }
              //
              //     return SizedBox(
              //       height: 360,
              //       child: ListView.builder(
              //         scrollDirection: Axis.horizontal,
              //         padding: const EdgeInsets.symmetric(
              //           horizontal: 18,
              //           vertical: 10,
              //         ),
              //         itemCount: books.length,
              //         itemBuilder: (context, index) {
              //           final book = books[index];
              //           return BookCard(
              //             book: book,
              //             user: widget.user,
              //             authorFuture: bookService().getAuthorByID(book.id_author),
              //             onReload: () {
              //               context.read<BookBloc>().add(GetBookEvent());
              //             },
              //           );
              //         },
              //       ),
              //     );
              //   },
              // ),

              BlocListener<CategoryBloc, CategoryState>(
                  listener: (context,state){
                    if(state is CategorySuccess){
                      for(var c in state.category){
                        context.read<BookBloc>().add(GetBookByCategoryEvent(category: c.name));
                      }
                    }
                  },
                child: BlocBuilder<CategoryBloc, CategoryState>(
                    builder: (context, catestate) {
                      if (catestate is CategoryLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (catestate is CategoryError) {
                        return Text(catestate.message);
                      }

                      if (catestate is CategorySuccess) {
                        return BlocBuilder<BookBloc, BookState>(
                          builder: (context, bookstate) {
                            Map<String, List<BookModel>> booksByCategory = {};

                            if (bookstate is BookByCategorySuccess) {
                              booksByCategory = bookstate.booksByCategory;
                            }

                            if (bookstate is BookError) {
                              return Text(bookstate.message);
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: catestate.category.length,
                              itemBuilder: (context, index) {
                                final category = catestate.category[index];
                                final hasLoaded = booksByCategory.containsKey(category.name);
                                final books = booksByCategory[category.name] ?? [];

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      category.name,
                                      textAlign: TextAlign.start,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xffFF9E74),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    if (!hasLoaded)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 20),
                                        child: Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      )
                                    else if (books.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 10),
                                        child: Text("Книги отсутствуют"),
                                      )
                                    else
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: books.map((book) {
                                            return BookCard(
                                              book: book,
                                              user: widget.user,
                                              authorFuture:bookService().getAuthorByID(book.id_author),
                                              onReload: () {
                                                context.read<BookBloc>().add(GetBookByCategoryEvent(category: category.name));
                                              },
                                                onReservationLoad:(){
                                                context.read<ReservationBloc>().add(GetReservationsByUserEvent(widget.user.id_user));
                                                }
                                            );
                                          }).toList(),
                                        ),
                                      ),

                                    const SizedBox(height: 20),
                                  ],
                                );
                              },
                            );
                          },
                        );
                      }
                      return Container();
                  },
                ),
              )

            ],
          ),
        ),
      ),
    );

  }
}



Widget _item(String text) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8,
    ),
    decoration: BoxDecoration(
      color: Color(0xffFBEEE4), // màu nút
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
        Icon(Icons.arrow_drop_down_sharp, color: Colors.black),
      ],
    ),
  );
}
