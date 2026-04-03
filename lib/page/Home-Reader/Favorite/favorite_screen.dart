import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/api_localhost/AuthorService.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/favorite/bloc.dart';
import 'package:library_app/bloc/favorite/event.dart';
import 'package:library_app/bloc/favorite/state.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/localization/app_localizations.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/favorite_model.dart';
import 'package:library_app/model/user_model.dart';
import '../../../Router/AppRoutes.dart';
import '../../../api_localhost/ApiService.dart';
import '../../../api_localhost/BookService.dart';
import '../../../bloc/book_copy/bloc.dart';
import '../../../bloc/book_copy/event.dart';
import '../../../bloc/book_copy/state.dart';
import '../../../model/book_copy_model.dart';
import '../Books/book_card.dart';

class FavoriteScreen extends StatefulWidget {
  final UserModel user;
  const FavoriteScreen({super.key, required this.user});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  static const Color _orange   = Color(0xffFF9E74);
  static const Color _bg       = Color(0xffF8EDE3);
  static const Color _textDark = Color(0xff3D2314);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Load books + favorites theo user
    context.read<BookCopyBloc>().add(GetBookCopyEvent());
    context.read<BookBloc>().add(GetBookEvent());
    context.read<FavoriteBloc>().add(
      GetFavoritesByUserIdEvent(id_user: widget.user.id_user),
    );
    _searchCtrl.addListener(() =>
        setState(() => _searchQuery = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
  Map<int, BookCopyModel> _buildCopyMap(BookCopyState copyState) {
    final Map<int, BookCopyModel> copyByBook = {};

    if (copyState is BookCopyByIdBookSuccess) {
      copyState.bookCopybyIdBook.forEach((idBook, list) {
        if (list.isNotEmpty) {
          copyByBook[idBook] = list.firstWhere(
                (c) => c.status == 'available',
            orElse: () => list.first,
          );
        }
      });
    } else if (copyState is BookCopySuccess) {
      for (final copy in copyState.bookCopies) {
        if (!copyByBook.containsKey(copy.id_book)) {
          copyByBook[copy.id_book] = copy;
        } else if (copy.status == 'available' &&
            copyByBook[copy.id_book]!.status != 'available') {
          copyByBook[copy.id_book] = copy;
        }
      }
    }

    return copyByBook;
  }

  final Set<int> _pendingCopyRequests = {};

  BookCopyModel _getCopy(
      BuildContext context,
      int idBook,
      Map<int, BookCopyModel> copyByBook,
      ) {
    if (!copyByBook.containsKey(idBook) && !_pendingCopyRequests.contains(idBook)) {
      _pendingCopyRequests.add(idBook);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BookCopyBloc>().add(GetBookByIdBookEvent(id_book: idBook));
        }
      });
    }
    return copyByBook[idBook] ??
        BookCopyModel(id_book: idBook, barcode: '', status: 'unknown');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.tr('favorite.title'), style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: _textDark, fontFamily: 'Nunito',
              )),
              const SizedBox(height: 2),
              Text(context.tr('favorite.subtitle'),
                  style: TextStyle(fontSize: 12, color: Colors.brown.shade400)),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: Colors.brown.withOpacity(0.08),
                  blurRadius: 12, offset: const Offset(0, 4),
                )],
              ),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 14, color: _textDark),
                decoration: InputDecoration(
                  hintText: context.tr('favorite.search_hint'),
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: _orange, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
                    onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          Expanded(child: _buildGrid()),
        ]),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return BlocBuilder<FavoriteBloc, FavoriteState>(
      buildWhen: (prev, curr) =>
      curr is FavoriteByUserSuccess ||
          curr is FavoriteLoading ||
          curr is FavoriteInitial,
      builder: (ctx, favState) {
        // Loading
        if (favState is FavoriteLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Lấy danh sách favorites của user
        final List<FavoriteModel> userFavorites = favState is FavoriteByUserSuccess
            ? favState.favoritesByUser[widget.user.id_user] ?? []
            : [];

        // Empty state
        if (userFavorites.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_border_rounded, size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 14),
              Text('Нет сохранённых книг',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('Нажмите 🔖 на книге, чтобы добавить',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  textAlign: TextAlign.center),
            ],
          ));
        }

        return BlocBuilder<BookCopyBloc, BookCopyState>(
          builder: (context, copyState) {
            final copyByBook = _buildCopyMap(copyState);

            return BlocBuilder<BookBloc, BookState>(
              builder: (ctx, bookState) {
                List<BookModel> allBooks = [];
                if (bookState is BookSuccess) allBooks = bookState.books;
                if (bookState is BookByCategorySuccess) allBooks = bookState.allBooks;

                final favBookIds = userFavorites.map((f) => f.id_book).toSet();
                var books = allBooks.where((b) => favBookIds.contains(b.id_book)).toList();

                if (_searchQuery.isNotEmpty) {
                  books = books.where((b) =>
                      b.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
                }

                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          context.tr('favorite.empty_title'),
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr('favorite.empty_subtitle'),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: books.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: BookCard(
                      book: books[i],
                      user: widget.user,
                      bookCopy: _getCopy(context, books[i].id_book, copyByBook),
                      authorFuture: Authorservice().getAuthorByID(books[i].id_author),
                      onReload: () {
                        context.read<BookBloc>().add(GetBookEvent());
                        context.read<BookCopyBloc>().add(GetBookCopyEvent());
                        context.read<FavoriteBloc>().add(
                          GetFavoritesByUserIdEvent(id_user: widget.user.id_user),
                        );
                      },
                      onReservationLoad: () => context.read<ReservationBloc>()
                          .add(GetReservationsByUserEvent(widget.user.id_user)),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

