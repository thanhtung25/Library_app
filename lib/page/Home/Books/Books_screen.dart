import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/category/bloc.dart';
import 'package:library_app/bloc/category/event.dart';
import 'package:library_app/bloc/category/state.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/bloc/reservation/state.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/user_model.dart';
import '../../../Router/AppRoutes.dart';
import '../../../api_localhost/ApiService.dart';
import '../../../api_localhost/BookService.dart';
import 'book_card.dart';

class BooksScreen extends StatefulWidget {
  final UserModel user;
  const BooksScreen({super.key, required this.user});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  static const Color _orange   = Color(0xffFF9E74);
  static const Color _bg       = Color(0xffF8EDE3);
  static const Color _textDark = Color(0xff3D2314);

  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery     = '';
  int    _selectedCatIdx  = 0;
  String _selectedCatName = '';
  String _filterLanguage  = '';   // '' = все языки
  int?   _filterYear;              // null = все годы

  // Кэш всех книг для извлечения уникальных значений
  List<BookModel> _cachedAllBooks = [];

  @override
  void initState() {
    super.initState();
    context.read<BookBloc>().add(GetBookEvent());
    context.read<CategoryBloc>().add(GetCategoriesHasBookEvent());
    context.read<ReservationBloc>().add(
      GetReservationsByUserEvent(widget.user.id_user),
    );
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.trim());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Уникальные языки / годы из кэша ──────────────────
  List<String> get _languages => _cachedAllBooks
      .map((b) => b.language.trim())
      .where((l) => l.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<int> get _years => _cachedAllBooks
      .map((b) => b.publish_year)
      .where((y) => y > 0)
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));  // убывание

  bool get _hasExtraFilter => _filterLanguage.isNotEmpty || _filterYear != null;
  bool get _hasAnyFilter   =>
      _searchQuery.isNotEmpty || _selectedCatIdx > 0 || _hasExtraFilter;

  // ── Применить все фильтры к списку ───────────────────
  List<BookModel> _applyFilters(List<BookModel> src) {
    var list = src;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((b) => b.title.toLowerCase().contains(q)).toList();
    }
    if (_filterLanguage.isNotEmpty) {
      list = list.where((b) => b.language.trim() == _filterLanguage).toList();
    }
    if (_filterYear != null) {
      list = list.where((b) => b.publish_year == _filterYear).toList();
    }
    return list;
  }

  // ════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _topBar(),
            _searchBar(),
            if (_hasExtraFilter) _activeFilterChips(),
            _categoryChips(),
            const SizedBox(height: 4),
            Expanded(child: _content()),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // TOP BAR
  // ════════════════════════════════════════════════════
  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              'Каталог книг',
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: _textDark, fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Найдите книги, которые вам нравятся',
              style: TextStyle(fontSize: 12, color: Colors.brown.shade400),
            ),
          ]),

          // Корзина с бейджем
          BlocBuilder<ReservationBloc, ReservationState>(
            builder: (context, state) {
              int count = 0;
              if (state is ReservationLoaded) count = state.reservations.length;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                  context, AppRoutes.cardRecervation, arguments: widget.user,
                ),
                child: Stack(clipBehavior: Clip.none, children: [
                  Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                        color: Colors.brown.withOpacity(0.10),
                        blurRadius: 8, offset: const Offset(0, 3),
                      )],
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, color: _orange, size: 22),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -3, top: -3,
                      child: Container(
                        width: 18, height: 18,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.red.shade500, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text('$count', style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold,
                        )),
                      ),
                    ),
                ]),
              );
            },
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // SEARCH BAR  (кнопка фильтра открывает bottom sheet)
  // ════════════════════════════════════════════════════
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 12, offset: const Offset(0, 4),
          )],
        ),
        child: Row(children: [
          const SizedBox(width: 14),
          const Icon(Icons.search_rounded, color: _orange, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 14, color: _textDark),
              decoration: InputDecoration(
                hintText: 'Поиск по названию книги...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
              onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); },
            ),
          // ── Кнопка фильтра ──
          GestureDetector(
            onTap: () => _showFilterSheet(),
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hasExtraFilter ? _orange : _orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune_rounded,
                color: _hasExtraFilter ? Colors.white : _orange,
                size: 18,
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // АКТИВНЫЕ ФИЛЬТРЫ (показывается под поиском)
  // ════════════════════════════════════════════════════
  Widget _activeFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Wrap(spacing: 8, runSpacing: 6, children: [
        if (_filterLanguage.isNotEmpty)
          _removableChip(
            '🌐 $_filterLanguage',
                () => setState(() => _filterLanguage = ''),
          ),
        if (_filterYear != null)
          _removableChip(
            '📅 $_filterYear',
                () => setState(() => _filterYear = null),
          ),
      ]),
    );
  }

  Widget _removableChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
      decoration: BoxDecoration(
        color: _orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _orange.withOpacity(0.4)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: const TextStyle(
          fontSize: 12, color: _orange, fontWeight: FontWeight.w600,
        )),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 14, color: _orange),
        ),
      ]),
    );
  }

  // ════════════════════════════════════════════════════
  // CATEGORY CHIPS
  // ════════════════════════════════════════════════════
  Widget _categoryChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          final cats = <String>['Все'];
          if (state is CategorySuccess) {
            cats.addAll(state.category.map((c) => c.name));
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: List.generate(cats.length, (i) {
                final sel = _selectedCatIdx == i;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCatIdx  = i;
                    _selectedCatName = i == 0 ? '' : cats[i];
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: sel ? _orange : Colors.white,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [BoxShadow(
                        color: sel ? _orange.withOpacity(0.35) : Colors.black.withOpacity(0.07),
                        blurRadius: sel ? 10 : 6,
                        offset: const Offset(0, 3),
                      )],
                    ),
                    child: Text(cats[i], style: TextStyle(
                      color: sel ? Colors.white : Colors.grey.shade600,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    )),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // ОСНОВНОЙ КОНТЕНТ
  // ════════════════════════════════════════════════════
  Widget _content() {
    return BlocListener<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategorySuccess) {
          for (final c in state.category) {
            context.read<BookBloc>().add(GetBookByCategoryEvent(category: c.name));
          }
        }
      },
      child: BlocBuilder<BookBloc, BookState>(
        builder: (context, bookState) {
          if (bookState is BookLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5),
            );
          }
          if (bookState is BookError) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              Text(bookState.message, style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
            ]));
          }

          // Извлечь данные
          List<BookModel> allBooks = [];
          Map<String, List<BookModel>> byCategory = {};

          if (bookState is BookSuccess) {
            allBooks = bookState.books;
          } else if (bookState is BookByCategorySuccess) {
            allBooks   = bookState.allBooks;
            byCategory = bookState.booksByCategory;
          }

          // Кэш для bottom sheet
          if (allBooks.isNotEmpty) _cachedAllBooks = allBooks;

          // База для фильтрации
          final base = _selectedCatIdx > 0
              ? (byCategory[_selectedCatName] ?? [])
              : allBooks;

          // Применить фильтры
          final filtered = _applyFilters(base);

          // Маршрутизация отображения
          if (_hasAnyFilter) {
            // Есть хотя бы один фильтр → плоский список
            return _filteredListView(filtered);
          }
          // Нет фильтров → группировка по категориям
          return _groupedView(byCategory, allBooks);
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // ВИД 1 – ГРУППИРОВКА ПО КАТЕГОРИЯМ (по умолчанию)
  // ════════════════════════════════════════════════════
  Widget _groupedView(
      Map<String, List<BookModel>> byCategory,
      List<BookModel> allBooks,
      ) {
    if (byCategory.isEmpty) {
      if (allBooks.isEmpty) {
        return const Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5));
      }
      return _horizontalScroll(allBooks, () => context.read<BookBloc>().add(GetBookEvent()));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 6, 0, 20),
      physics: const BouncingScrollPhysics(),
      itemCount: byCategory.length,
      itemBuilder: (context, i) {
        final catName = byCategory.keys.elementAt(i);
        final books   = byCategory[catName] ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(
              padding: const EdgeInsets.only(right: 20, bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      width: 4, height: 20,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(color: _orange, borderRadius: BorderRadius.circular(2)),
                    ),
                    Text(catName, style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700, color: _textDark,
                    )),
                  ]),
                  Text('${books.length} книг',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (books.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: books.map((book) => BookCard(
                    book: book, user: widget.user,
                    authorFuture: bookService().getAuthorByID(book.id_author),
                    onReload: () => context.read<BookBloc>()
                        .add(GetBookByCategoryEvent(category: catName)),
                    onReservationLoad: () => context.read<ReservationBloc>()
                        .add(GetReservationsByUserEvent(widget.user.id_user)),
                  )).toList(),
                ),
              ),
          ]),
        );
      },
    );
  }

  Widget _horizontalScroll(List<BookModel> books, VoidCallback onReload) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: books.map((book) => BookCard(
          book: book, user: widget.user,
          authorFuture: bookService().getAuthorByID(book.id_author),
          onReload: onReload,
          onReservationLoad: () => context.read<ReservationBloc>()
              .add(GetReservationsByUserEvent(widget.user.id_user)),
        )).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // ВИД 2 – ОТФИЛЬТРОВАННЫЙ СПИСОК (поиск / фильтры)
  // ════════════════════════════════════════════════════
  Widget _filteredListView(List<BookModel> books) {
    // Заголовок результата
    String subtitle;
    if (_searchQuery.isNotEmpty) {
      subtitle = '${books.length} результатов по запросу "$_searchQuery"';
    } else if (_selectedCatIdx > 0) {
      subtitle = '${books.length} книг в категории "$_selectedCatName"';
    } else {
      subtitle = '${books.length} книг найдено';
    }

    if (books.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 14),
        Text(
          _searchQuery.isNotEmpty
              ? 'Книги не найдены\n"$_searchQuery"'
              : 'Книги не найдены\nпо заданным фильтрам',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade400, fontSize: 14, height: 1.5),
        ),
      ]));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        child: Text(subtitle, style: TextStyle(
          fontSize: 13, color: Colors.grey.shade500, fontWeight: FontWeight.w500,
        )),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: books.length,
          itemBuilder: (context, i) => _SearchItem(
            book: books[i], user: widget.user,
            authorFuture: bookService().getAuthorByID(books[i].id_author),
            onReload: () => context.read<BookBloc>().add(GetBookEvent()),
            onReservationLoad: () => context.read<ReservationBloc>()
                .add(GetReservationsByUserEvent(widget.user.id_user)),
          ),
        ),
      ),
    ]);
  }

  // ════════════════════════════════════════════════════
  // BOTTOM SHEET ФИЛЬТРА
  // ════════════════════════════════════════════════════
  void _showFilterSheet() {
    // Локальное состояние внутри листа
    String tempLang = _filterLanguage;
    int?   tempYear = _filterYear;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Хэндл
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Заголовок
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Фильтры', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: _textDark,
                    )),
                    TextButton(
                      onPressed: () => setSheet(() { tempLang = ''; tempYear = null; }),
                      child: const Text('Сбросить всё',
                          style: TextStyle(color: _orange, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── ЯЗЫК ──────────────────────────────
                const Text('Язык', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _textDark,
                )),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(children: [
                    _sheetChip('Все языки', tempLang.isEmpty, () => setSheet(() => tempLang = '')),
                    ..._languages.map((lang) => _sheetChip(
                      lang, tempLang == lang,
                          () => setSheet(() => tempLang = lang),
                    )),
                  ]),
                ),
                const SizedBox(height: 22),

                // ── ГОД ИЗДАНИЯ ───────────────────────
                const Text('Год издания', style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, color: _textDark,
                )),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(children: [
                    _sheetChip('Все годы', tempYear == null, () => setSheet(() => tempYear = null)),
                    ..._years.map((year) => _sheetChip(
                      '$year', tempYear == year,
                          () => setSheet(() => tempYear = year),
                    )),
                  ]),
                ),
                const SizedBox(height: 28),

                // ── Кнопка ПРИМЕНИТЬ ──────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _filterLanguage = tempLang;
                        _filterYear     = tempYear;
                      });
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Применить',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sheetChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _orange : const Color(0xffFFF0E6),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: selected ? _orange : Colors.transparent,
          ),
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : Colors.grey.shade600,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        )),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// КОМПАКТНАЯ КАРТОЧКА РЕЗУЛЬТАТА ПОИСКА
// ════════════════════════════════════════════════════
class _SearchItem extends StatelessWidget {
  final BookModel book;
  final UserModel user;
  final Future<AuthorModel> authorFuture;
  final VoidCallback onReload;
  final VoidCallback onReservationLoad;

  const _SearchItem({
    required this.book, required this.user,
    required this.authorFuture,
    required this.onReload, required this.onReservationLoad,
  });

  static const Color _orange   = Color(0xffFF9E74);
  static const Color _textDark = Color(0xff3D2314);

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.brown.withOpacity(0.07),
            blurRadius: 10, offset: const Offset(0, 4),
          )],
        ),
        child: Row(children: [
          // Обложка
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: book.image_url.isNotEmpty
                ? Image.network(
              '${ApiService.baseUrl}${book.image_url}',
              width: 60, height: 84, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _placeholder(),
            )
                : _placeholder(),
          ),
          const SizedBox(width: 14),

          // Информация
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(book.title, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: _textDark,
            ), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            FutureBuilder<AuthorModel>(
              future: authorFuture,
              builder: (context, snap) => Text(
                snap.hasData ? snap.data!.full_name : '...',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _chip(book.language.toUpperCase(), Icons.language_rounded),
              _chip('${book.publish_year}',      Icons.calendar_today_rounded),
            ]),
          ])),

          const Icon(Icons.chevron_right_rounded, color: Color(0xffFFCCA8), size: 24),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 60, height: 84,
    decoration: BoxDecoration(
      color: const Color(0xffFFEDD8), borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.book_rounded, color: _orange, size: 30),
  );

  Widget _chip(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xffFFF0E6), borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: _orange),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: _orange, fontWeight: FontWeight.w600)),
    ]),
  );
}
