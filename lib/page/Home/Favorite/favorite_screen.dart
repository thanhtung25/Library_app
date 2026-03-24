import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/favorite_manager.dart';
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
    context.read<BookBloc>().add(GetBookEvent());
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
          // ── Заголовок ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Сохранённые книги', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: _textDark, fontFamily: 'Nunito',
              )),
              const SizedBox(height: 2),
              Text('Ваши избранные книги',
                  style: TextStyle(fontSize: 12, color: Colors.brown.shade400)),
            ]),
          ),

          // ── Поиск ──────────────────────────────────
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
                  hintText: 'Поиск книги...',
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
    return BlocBuilder<BookBloc, BookState>(
      builder: (ctx, bookState) {
        List<BookModel> allBooks = [];
        if (bookState is BookSuccess)           allBooks = bookState.books;
        if (bookState is BookByCategorySuccess) allBooks = bookState.allBooks;

        return ValueListenableBuilder<Set<int>>(
          valueListenable: FavoriteManager.notifier,
          builder: (ctx, favorites, _) {
            // Фильтр: только избранные
            var books = allBooks
                .where((b) => favorites.contains(b.id_book))
                .toList();

            // Поиск по названию
            if (_searchQuery.isNotEmpty) {
              books = books
                  .where((b) => b.title.toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
                  .toList();
            }

            // Пустое состояние
            if (favorites.isEmpty) {
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

            if (books.isEmpty) {
              return Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text('Книги не найдены',
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
                authorFuture: bookService().getAuthorByID(books[i].id_author),
                onReload: () => context.read<BookBloc>().add(GetBookEvent()),
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

// ── Карточка избранной книги ───────────────────────────
class _FavCard extends StatelessWidget {
  final BookModel book;
  final UserModel user;
  final Future<AuthorModel> authorFuture;
  final VoidCallback onReload, onReservationLoad;

  static const Color _orange   = Color(0xffFF9E74);
  static const Color _textDark = Color(0xff3D2314);

  const _FavCard({
    required this.book, required this.user,
    required this.authorFuture,
    required this.onReload, required this.onReservationLoad,
  });

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
          // Обложка + кнопка удалить из избранного
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
            Positioned(
              top: 8, right: 8,
              child: GestureDetector(
                onTap: () => FavoriteManager.toggle(book.id_book),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                  ),
                  child: const Icon(Icons.bookmark_rounded, color: _orange, size: 18),
                ),
              ),
            ),
          ]),
          // Название
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
            child: Text(book.title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textDark),
                maxLines: 2, overflow: TextOverflow.ellipsis),
          ),
          // Автор
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
