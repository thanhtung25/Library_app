import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
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
    );
  }

  Widget _buildGrid() {
    return BlocConsumer<FavoriteBloc, FavoriteState>(
      // Reload sau khi add/delete thành công
      listenWhen: (prev, curr) => curr is FavoriteActionSuccess,
      listener: (context, state) {
        context.read<FavoriteBloc>().add(
          GetFavoritesByUserIdEvent(id_user: widget.user.id_user),
        );
      },
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

        return BlocBuilder<BookBloc, BookState>(
          builder: (ctx, bookState) {
            List<BookModel> allBooks = [];
            if (bookState is BookSuccess)           allBooks = bookState.books;
            if (bookState is BookByCategorySuccess) allBooks = bookState.allBooks;

            // Lọc books có trong favorites
            final favBookIds = userFavorites.map((f) => f.id_book).toSet();
            var books = allBooks.where((b) => favBookIds.contains(b.id_book)).toList();

            // Filter search
            if (_searchQuery.isNotEmpty) {
              books = books.where((b) =>
                  b.title.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();
            }

            if (books.isEmpty) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(context.tr('favorite.empty_title'),
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(context.tr('favorite.empty_subtitle'),
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                ],
              ));
            }

            return GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.62,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: books.length,
              itemBuilder: (ctx, i) => _FavCard(
                book: books[i],
                user: widget.user,
                favorites: userFavorites,
                authorFuture: bookService().getAuthorByID(books[i].id_author),
                onReload: () {
                  context.read<BookBloc>().add(GetBookEvent());
                  context.read<FavoriteBloc>().add(
                    GetFavoritesByUserIdEvent(id_user: widget.user.id_user),
                  );
                },
                onReservationLoad: () => context.read<ReservationBloc>()
                    .add(GetReservationsByUserEvent(widget.user.id_user)),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Card ───────────────────────────────────────────────
class _FavCard extends StatelessWidget {
  final BookModel book;
  final UserModel user;
  final List<FavoriteModel> favorites;
  final Future<AuthorModel> authorFuture;
  final VoidCallback onReload, onReservationLoad;

  static const Color _orange   = Color(0xffFF9E74);
  static const Color _textDark = Color(0xff3D2314);

  const _FavCard({
    required this.book,
    required this.user,
    required this.favorites,
    required this.authorFuture,
    required this.onReload,
    required this.onReservationLoad,
  });

  void _deleteFavorite(BuildContext context) {
    final existing = favorites.firstWhere(
          (f) => f.id_book == book.id_book && f.id_user == user.id_user,
      orElse: () => FavoriteModel(id_book: book.id_book, id_user: user.id_user),
    );

    if (existing.id_favorite != null) {
      context.read<FavoriteBloc>().add(
        DeleteFavoriteEvent(id_favorite: existing.id_favorite!),
      );
    } else {
      // Không tìm thấy → reload lại
      context.read<FavoriteBloc>().add(
        GetFavoritesByUserIdEvent(id_user: user.id_user),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.pushNamed(
          context, AppRoutes.bookDetail,
          arguments: {'book': book, 'user': user},
        );
        if (result == true && context.mounted) { onReload(); onReservationLoad(); }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 10, offset: const Offset(0, 4),
          )],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              child: book.image_url.isNotEmpty
                  ? Image.network(
                '${ApiService.baseUrl}${book.image_url}',
                height: 170, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
                  : _placeholder(),
            ),
            // Nút xóa khỏi favorites
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => _deleteFavorite(context),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.1), blurRadius: 6,
                    )],
                  ),
                  child: const Icon(Icons.bookmark_rounded, color: _orange, size: 18),
                ),
              ),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Text(book.title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: FutureBuilder<AuthorModel>(
              future: authorFuture,
              builder: (ctx, snap) => Text(
                snap.hasData ? snap.data!.full_name : '...',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    height: 170, width: double.infinity,
    decoration: const BoxDecoration(
      color: Color(0xffFFEDD8),
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    child: const Icon(Icons.book_rounded, color: _orange, size: 40),
  );
}