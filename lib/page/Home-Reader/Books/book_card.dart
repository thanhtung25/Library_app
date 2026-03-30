import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/model/user_model.dart';
import '../../../Router/AppRoutes.dart';
import '../../../api_localhost/ApiService.dart';
import '../../../bloc/favorite/bloc.dart';
import '../../../bloc/favorite/event.dart';
import '../../../bloc/favorite/state.dart';
import '../../../model/author_model.dart';
import '../../../model/book_model.dart';
import '../../../model/book_copy_model.dart';
import '../../../model/favorite_model.dart';


class BookCard extends StatelessWidget {
  final BookModel book;
  final UserModel user;
  final BookCopyModel bookCopy;
  final Future<AuthorModel> authorFuture;
  final VoidCallback onReload;
  final VoidCallback onReservationLoad;

  const BookCard({
    super.key,
    required this.book,
    required this.authorFuture,
    required this.onReload,
    required this.onReservationLoad,
    required this.user,
    required this.bookCopy,
  });

  void _addFavorite(BuildContext context,
      {required bool isFav, required List<FavoriteModel> favorites}) {
    if (!isFav) {
      context.read<FavoriteBloc>().add(AddFavoriteEvent(
        favorite: FavoriteModel(id_book: book.id_book, id_user: user.id_user),
      ));
    } else {
      final existing = favorites.firstWhere(
            (f) => f.id_book == book.id_book && f.id_user == user.id_user,
        orElse: () =>
            FavoriteModel(id_book: book.id_book, id_user: user.id_user),
      );
      if (existing.id_favorite != null) {
        context.read<FavoriteBloc>().add(
            DeleteFavoriteEvent(id_favorite: existing.id_favorite!));
      } else {
        context.read<FavoriteBloc>().add(
            GetFavoritesByUserIdEvent(id_user: user.id_user));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context,
          AppRoutes.bookDetail,
          arguments: {'book': book, 'user': user},
        );
        if (result == true && context.mounted) {
          onReload();
          onReservationLoad();
        }
      },
      child: Container(
        height: 380,
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
            // ── ảnh + bookmark ──────────────────────────────
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(22)),
                    child: book.image_url.isNotEmpty
                        ? Image.network(
                      "${ApiService.baseUrl}${book.image_url}",
                      height: 240, width: 180,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      "assets/images/book1.png",
                      height: 240, width: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 10, right: 10,
                    child: BlocConsumer<FavoriteBloc, FavoriteState>(
                      listenWhen: (_, curr) =>
                      curr is FavoriteActionSuccess || curr is FavoriteError,
                      listener: (context, state) {
                        if (state is FavoriteActionSuccess) {
                          context.read<FavoriteBloc>().add(
                              GetFavoritesByUserIdEvent(id_user: user.id_user));
                        }
                        if (state is FavoriteError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(state.message)));
                        }
                      },
                      buildWhen: (_, curr) =>
                      curr is FavoriteByUserSuccess || curr is FavoriteInitial,
                      builder: (context, favState) {
                        final favorites = favState is FavoriteByUserSuccess
                            ? favState.favoritesByUser[user.id_user] ?? <FavoriteModel>[]
                            : <FavoriteModel>[];
                        final isFav = favorites.any((f) =>
                        f.id_book == book.id_book && f.id_user == user.id_user);
                        return GestureDetector(
                          onTap: () => _addFavorite(context,
                              isFav: isFav, favorites: favorites),
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Icon(
                              isFav
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: isFav
                                  ? const Color(0xffFF9E74)
                                  : Colors.black54,
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

            // ── tiêu đề ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
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

            // ── tác giả ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 6),
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
              ),
            ),

            // ── status badge (có màu) ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 0),
              child: SizedBox(
                width: 180,
                child: _StatusBadge(status: bookCopy.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// Badge trạng thái bản sao — có màu theo status
// ════════════════════════════════════════════════════
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  Color get _color {
    switch (status) {
      case 'available': return Colors.green;
      case 'borrowed':  return Colors.red;
      case 'reserved':  return Colors.orange;
      default:          return Colors.grey;
    }
  }

  String get _label {
    switch (status) {
      case 'available': return 'Доступный';
      case 'borrowed':  return 'Заимствованный';
      case 'reserved':  return 'Заказ размещен';
      default:          return 'Не определено';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: _color),
          const SizedBox(width: 5),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _color,
            ),
          ),
        ],
      ),
    );
  }
}
