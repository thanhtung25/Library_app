

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:library_app/model/user_model.dart';
import '../../../Router/AppRoutes.dart';
import '../../../api_localhost/ApiService.dart';
import '../../../model/book_model.dart';
import '../../../model/favorite_manager.dart';



class BookCard extends StatelessWidget {
  final BookModel book;
  final UserModel user;
  final  Future<AuthorModel> authorFuture;
  final VoidCallback onReload;
  final VoidCallback onReservationLoad;
  const BookCard({super.key, required this.book , required this.authorFuture, required this.onReload, required this.onReservationLoad, required this.user});



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.bookDetail,
          arguments: {
            'book': book,
            'user': user,
          },
        );

        if (result == true && context.mounted) {
          onReload();
          onReservationLoad();
        }
      },
      child: Container(
        height: 350,
        margin: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(3, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(22)),
                    child: book.image_url.isNotEmpty
                        ? Image.network(
                      "${ApiService.baseUrl}${book.image_url}",
                      height: 240,
                      width: 180,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      "assets/images/book1.png",
                      height: 240,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ),

                  Positioned(
                    top: 10, right: 10,
                    child: ValueListenableBuilder<Set<int>>(
                      valueListenable: FavoriteManager.notifier,
                      builder: (context, favorites, _) {
                        final isFav = favorites.contains(book.id_book);
                        return GestureDetector(
                          onTap: () => FavoriteManager.toggle(book.id_book),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 6)],
                            ),
                            child: Icon(
                              isFav ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                              color: isFav ? const Color(0xffFF9E74) : Colors.black54,
                              size: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: SizedBox(
                width: 180,
                child: Text(
                  book.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
              child: SizedBox(
                width: 180,
                child: FutureBuilder(
                  future: authorFuture,
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                      return const Text("Đang tải...");
                    }

                    if (asyncSnapshot.hasError) {
                      return const Text("Lỗi tác giả");
                    }

                    if (!asyncSnapshot.hasData) {
                      return const Text("Không có tác giả");
                    }

                    return Text(
                      asyncSnapshot.data!.full_name,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}


