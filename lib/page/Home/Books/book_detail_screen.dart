
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/reservation/state.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/user_model.dart';

import '../../../api_localhost/ApiService.dart';
import '../../../api_localhost/BookService.dart';
import '../../../bloc/book/bloc.dart';
import '../../../bloc/reservation/bloc.dart';
import '../../../bloc/reservation/event.dart';
import '../../../model/reservations_model.dart';
class BookDetailScreen extends StatefulWidget {
  final BookModel bookModel;
  final UserModel userModel;
  const BookDetailScreen({super.key, required this.bookModel, required this.userModel});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();

  static Widget _infoBox({
    required String title,
    required Color backgroundColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  static Widget _smallTag({
    required String text,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          height: 1.4,
        ),
      ),
    );
  }
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late final  Future<AuthorModel> authorFuture;
  @override
  void initState() {
    super.initState();
    context.read<BookBloc>().add((GetBookByIdEvent(id_book: widget.bookModel.id_book)));
    authorFuture = bookService().getAuthorByID(widget.bookModel.id_author);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Column(
              children: [
                // top bar
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context, true),
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    ),
                    const Spacer(),
                  ],
                ),

                const SizedBox(height: 8),

                // main card
                Container(
                  width: double.infinity,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F8F8),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Stack(
                    children: [
                      // background doodle
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Opacity(
                            opacity: 0.5,
                            child: Image.asset(
                              'assets/images/background.jpg',
                              fit: BoxFit.cover,
                            )
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: BlocBuilder<BookBloc, BookState>(
                        builder: (context, state) {
                          if(state is BookLoading){return const CircularProgressIndicator();}
                          if(state is BookError){return Text(state.message);}
                          if(state is BookByIdSucces){
                            final book = state.bookModel;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // top info
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // book cover
                                    Container(
                                      width: 150,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.18),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                        image:  DecorationImage(
                                          image: NetworkImage(
                                            "${ApiService.baseUrl}${book.image_url}",
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 20),

                                    // title + desc
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children:  [
                                          SizedBox(height: 8),
                                          Text(
                                            book.title,
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black87,
                                              height: 1.3,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          FutureBuilder(
                                            future: authorFuture,
                                            builder: (context, snap) {
                                              if (snap.connectionState == ConnectionState.waiting) {
                                                return const Text("Đang tải...");
                                              }

                                              if (snap.hasError) {
                                                return const Text("Lỗi tác giả");
                                              }

                                              if (!snap.hasData) {
                                                return const Text("Không có tác giả");
                                              }
                                              return Text(
                                                snap.data!.full_name,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                  color: Color(0xffFF9E74),
                                                  height: 1.3,
                                                ),
                                              );
                                            }
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // description block
                                BookDetailScreen._infoBox(
                                  title: 'Подробное описание:',
                                  backgroundColor: const Color(0xFFD9F6A6),
                                  child: Text(
                                    book.description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                      color: Colors.black87,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                BookDetailScreen._smallTag(
                                  text: 'Язык: ${book.language}',
                                  color: const Color(0xFFE6D6FA),
                                ),

                                const SizedBox(height: 10),

                                FutureBuilder(
                                  future: authorFuture,
                                  builder: (context, snap) {
                                    if (snap.connectionState == ConnectionState.waiting) {
                                      return const Text("Đang tải...");
                                    }

                                    if (snap.hasError) {
                                      return const Text("Lỗi tác giả");
                                    }

                                    if (!snap.hasData) {
                                      return const Text("Không có tác giả");
                                    }
                                    return BookDetailScreen._smallTag(
                                      text:
                                      'Биография автора: ${snap.data!.biography}',
                                      color: const Color(0xFFF3C7EF),
                                    );
                                  }
                                ),

                                const SizedBox(height: 18),

                                BlocConsumer<ReservationBloc, ReservationState>(
                                  listener: (context, state) {
                                    if (state is ReservationCreated) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Бронирование успешно создано')),
                                      );

                                      Navigator.pop(context, true);
                                    }

                                    if (state is ReservationError) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(state.error)),
                                      );
                                    }
                                  },
                                  builder: (context, state) {
                                    return Padding(
                                      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 60,
                                        child: FloatingActionButton(
                                          backgroundColor: const Color(0xffFF9E74),
                                          onPressed: state is ReservationLoading
                                              ? null
                                              : () {
                                            context.read<ReservationBloc>().add(
                                              AddReservationEvent(
                                                ReservationModel(
                                                  id_user: widget.userModel.id_user,
                                                  id_book: widget.bookModel.id_book,
                                                  comment: 'Book in advance via app',
                                                  status: 'pending',
                                                ),
                                              ),
                                            );
                                          },
                                          child: state is ReservationLoading
                                              ? const CircularProgressIndicator(color: Colors.white)
                                              : const Text(
                                            'Бронирования',
                                            style: TextStyle(
                                              fontFamily: 'Times New Roman',
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 14),
                              ],
                            );
                          }
                          return Container();
                          },
                        ),
                      ),
                      // heart button
                      Positioned(
                        right: 14,
                        top: 165,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: Color(0xFFFF9B7C),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
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