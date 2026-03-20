import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../api_localhost/AuthService.dart';
import '../../../api_localhost/bookService.dart';
import '../../../model/book_model.dart';
import 'book_card.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final TextEditingController _search = TextEditingController();

  late Future<List<BookModel>> futureBooks;
  late Future<List<BookModel>> futureBooksByCategory;
  late Future<List<CategoryModel>> futureCategory;
  @override
  void initState() {
    super.initState();
    futureBooks = bookService().getAllBook();
    futureCategory = bookService().getAllCategory();
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
                      child: IconButton(
                        onPressed: () {},
                        icon: Icon(
                          Icons.shopping_cart,
                          color: Color(0xffFF9E74),
                          size: 26,
                        ),
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
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                child: Text(
                  'Популярный',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500,color: Color(0xffFF9E74)),
                ),
              ),

              SizedBox(
                child: FutureBuilder<List<BookModel>>(
                  future: futureBooks,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }

                    final books = snapshot.data ?? [];
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
                            authorFuture:  bookService().getAuthorByID(book.id_author),
                          );
                        }
                        ).toList(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(
                child:
                FutureBuilder(
                  future: futureCategory,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Text("Error: ${snapshot.error}");
                    }
                    final Categoris = snapshot.data ?? [];
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: Categoris.map((category){
                         return Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Text(
                               category.name,
                               textAlign: TextAlign.start,
                               style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500,color: Color(0xffFF9E74)),
                             ),

                             FutureBuilder(
                               future: bookService().getBookByCategory(category.name),
                               builder: (context, snapshot) {
                                 print("FutureBuilder run: ${category.name}");
                                 if (snapshot.connectionState == ConnectionState.waiting) {
                                   return const Center(
                                     child: CircularProgressIndicator(),
                                   );
                                 }
                                 if (snapshot.hasError) {
                                   return Text("Error: ${snapshot.error}");
                                 }
                                 final  books = snapshot.data ?? [];
                                 return SingleChildScrollView(
                                   scrollDirection: Axis.horizontal,
                                   padding: const EdgeInsets.symmetric(
                                     horizontal: 18,
                                     vertical: 10,
                                   ),
                                   child: Row(
                                     children: books.map((book) {
                                       return BookCard(
                                         authorFuture:  bookService().getAuthorByID(book.id_author),
                                         book: book,
                                       );
                                     }
                                     ).toList(),
                                   ),
                                 );
                               }
                             )
                           ],
                         );
                      }
                      ).toList(),
                      )
                    );
                  }
                ),

              ),

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
