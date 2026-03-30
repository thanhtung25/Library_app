import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/api_localhost/AuthorService.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/category/bloc.dart';
import 'package:library_app/bloc/category/event.dart';
import 'package:library_app/bloc/category/state.dart';
import 'package:library_app/localization/app_localizations.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/bloc/reservation/state.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/user_model.dart';
import '../../../Router/AppRoutes.dart';
import '../../../api_localhost/ApiService.dart';
import '../../../api_localhost/BookService.dart';
import '../../../bloc/book_copy/bloc.dart';
import '../../../bloc/book_copy/event.dart';
import '../../../bloc/book_copy/state.dart';
import '../../../model/author_model.dart';
import '../../../model/book_copy_model.dart';
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

  // ── BookService instance ─────────────────────────────
  final bookService _bookService = bookService();

  // ── 3 bộ lọc ─────────────────────────────────────
  String _searchQuery        = '';
  int?   _filterCategory;
  String _filterCategoryName = '';
  String _filterLanguage     = '';
  int?   _filterYear;

  List<BookModel> _cachedAllBooks = [];

  @override
  void initState() {
    super.initState();
    context.read<BookBloc>().add(GetBookEvent());
    context.read<CategoryBloc>().add(GetAllCategoryEvent());
    context.read<ReservationBloc>()
        .add(GetReservationsByUserEvent(widget.user.id_user));
    context.read<BookCopyBloc>().add(GetBookCopyEvent());
    _searchCtrl.addListener(
            () => setState(() => _searchQuery = _searchCtrl.text.trim()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Giá trị duy nhất cho picker ──────────────────
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
    ..sort((a, b) => b.compareTo(a));

  // ── Trạng thái filter ────────────────────────────
  bool get _hasFilter =>
      _searchQuery.isNotEmpty ||
          _filterCategory != null ||
          _filterLanguage.isNotEmpty ||
          _filterYear != null;

  void _clearAllFilters() => setState(() {
    _filterCategory     = null;
    _filterCategoryName = '';
    _filterLanguage     = '';
    _filterYear         = null;
    _searchCtrl.clear();
    _searchQuery        = '';
  });

  // ── Áp dụng tất cả bộ lọc ───────────────────────
  List<BookModel> _applyFilters(List<BookModel> src) {
    var list = src;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((b) => b.title.toLowerCase().contains(q)).toList();
    }
    if (_filterCategory != null) {
      list = list.where((b) => b.id_category == _filterCategory).toList();
    }
    if (_filterLanguage.isNotEmpty) {
      list = list.where((b) => b.language.trim() == _filterLanguage).toList();
    }
    if (_filterYear != null) {
      list = list.where((b) => b.publish_year == _filterYear).toList();
    }
    return list;
  }

  // ── Helper: build copyByBook map từ state ────────
  Map<int, BookCopyModel> _buildCopyMap(BookCopyState copyState) {
    final Map<int, BookCopyModel> copyByBook = {};

    if (copyState is BookCopyByIdBookSuccess) {
      // Ưu tiên bản sao 'available', fallback về first
      copyState.bookCopybyIdBook.forEach((idBook, list) {
        if (list.isNotEmpty) {
          copyByBook[idBook] = list.firstWhere(
                (c) => c.status == 'available',
            orElse: () => list.first,
          );
        }
      });
    } else if (copyState is BookCopySuccess) {
      // Ưu tiên bản sao 'available' cho mỗi id_book
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


  // ── Helper: lấy BookCopyModel, tự dispatch nếu chưa có ──
  BookCopyModel _getCopy(
      BuildContext context,
      int idBook,
      Map<int, BookCopyModel> copyByBook,
      ) {
    if (!copyByBook.containsKey(idBook)) {
      context.read<BookCopyBloc>().add(GetBookByIdBookEvent(id_book: idBook));
    }
    return copyByBook[idBook] ??
        BookCopyModel(id_book: idBook, barcode: '', status: 'unknown');
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
            const SizedBox(height: 10),
            _filterChipRow(),
            if (_hasFilter) _activeTagRow(),
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
            Text(
              context.tr('books.catalog_title'),
              style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w800,
                color: _textDark, fontFamily: 'Nunito',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.tr('books.catalog_subtitle'),
              style: TextStyle(fontSize: 12, color: Colors.brown.shade400),
            ),

          ]),
          BlocBuilder<ReservationBloc, ReservationState>(
            builder: (context, state) {
              int count = 0;
              if (state is ReservationLoaded) count = state.reservations.length;
              return GestureDetector(
                onTap: () => Navigator.pushNamed(
                    context, AppRoutes.cardRecervation, arguments: widget.user),
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
                    child: const Icon(Icons.shopping_bag_outlined,
                        color: _orange, size: 22),
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
                            color: Colors.white, fontSize: 10,
                            fontWeight: FontWeight.bold)),
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
  // SEARCH BAR
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
                hintText: context.tr('books.search_hint'),
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.grey, size: 20),
              onPressed: () {
                _searchCtrl.clear();
                setState(() => _searchQuery = '');
              },
            ),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // FILTER CHIP ROW
  // ════════════════════════════════════════════════════
  Widget _filterChipRow() {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, catState) {
        final categories = catState is CategorySuccess
            ? catState.category.map((c) => c.name).toList()
            : <String>[];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              // ── 1. КАТЕГОРИЯ ──────────────────────
              _FilterDropChip(
                icon: Icons.category_rounded,
                label: _filterCategory != null ? _filterCategoryName : 'Категория',
                active: _filterCategory != null,
                orange: _orange,
                onTap: categories.isEmpty
                    ? null
                    : () => _showCategoryPickerSheet(catState as CategorySuccess),
              ),
              const SizedBox(width: 8),

              // ── 2. ГОД ИЗДАНИЯ ────────────────────
              _FilterDropChip(
                icon: Icons.calendar_today_rounded,
                label: _filterYear != null ? '$_filterYear' : 'Год',
                active: _filterYear != null,
                orange: _orange,
                onTap: _cachedAllBooks.isEmpty
                    ? null
                    : () => _showPickerSheet(
                  title: 'Год издания',
                  icon: Icons.calendar_today_rounded,
                  items: _years.map((y) => '$y').toList(),
                  selected: _filterYear != null ? '$_filterYear' : '',
                  allLabel: 'Все годы',
                  onApply: (v) => setState(
                          () => _filterYear = v.isEmpty ? null : int.tryParse(v)),
                ),
              ),
              const SizedBox(width: 8),

              // ── 3. ЯЗЫК ───────────────────────────
              _FilterDropChip(
                icon: Icons.language_rounded,
                label: _filterLanguage.isNotEmpty ? _filterLanguage : 'Язык',
                active: _filterLanguage.isNotEmpty,
                orange: _orange,
                onTap: _cachedAllBooks.isEmpty
                    ? null
                    : () => _showPickerSheet(
                  title: 'Язык',
                  icon: Icons.language_rounded,
                  items: _languages,
                  selected: _filterLanguage,
                  allLabel: 'Все языки',
                  onApply: (v) => setState(() => _filterLanguage = v),
                ),
              ),

              // ── 4. СБРОСИТЬ ──────────────────────
              if (_filterCategory != null ||
                  _filterLanguage.isNotEmpty ||
                  _filterYear != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() {
                    _filterCategory     = null;
                    _filterCategoryName = '';
                    _filterLanguage     = '';
                    _filterYear         = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.filter_alt_off_rounded,
                          size: 14, color: Colors.red.shade400),
                      const SizedBox(width: 4),
                      Text('Сбросить',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade400,
                              fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ════════════════════════════════════════════════════
  // ACTIVE TAG ROW
  // ════════════════════════════════════════════════════
  Widget _activeTagRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Wrap(spacing: 8, runSpacing: 6, children: [
        if (_filterCategory != null)
          _removeTag('📚 $_filterCategoryName',
                  () => setState(() { _filterCategory = null; _filterCategoryName = ''; })),
        if (_filterLanguage.isNotEmpty)
          _removeTag('🌐 $_filterLanguage',
                  () => setState(() => _filterLanguage = '')),
        if (_filterYear != null)
          _removeTag('📅 $_filterYear',
                  () => setState(() => _filterYear = null)),
        if (_searchQuery.isNotEmpty)
          _removeTag('🔍 "$_searchQuery"', () {
            _searchCtrl.clear();
            setState(() => _searchQuery = '');
          }),
      ]),
    );
  }

  Widget _removeTag(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 4, 5),
      decoration: BoxDecoration(
        color: _orange.withOpacity(0.13),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _orange.withOpacity(0.35)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: _orange, fontWeight: FontWeight.w600)),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onRemove,
          child: const Icon(Icons.close_rounded, size: 14, color: _orange),
        ),
      ]),
    );
  }
  // ════════════════════════════════════════════════════
  // BOTTOM SHEET — CATEGORY PICKER
  // ════════════════════════════════════════════════════
  void _showCategoryPickerSheet(CategorySuccess catState) {
    int?   tempId   = _filterCategory;
    String tempName = _filterCategoryName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.category_rounded,
                          size: 18, color: _orange),
                    ),
                    const SizedBox(width: 10),
                    const Text('Категория', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      color: _textDark,
                    )),
                  ]),
                  TextButton(
                    onPressed: () =>
                        setSheet(() { tempId = null; tempName = ''; }),
                    child: const Text('Сбросить',
                        style: TextStyle(
                            color: _orange, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pickerChip(
                    label: 'Все категории',
                    selected: tempId == null,
                    onTap: () => setSheet(() { tempId = null; tempName = ''; }),
                  ),
                  ...catState.category.map((cat) => _pickerChip(
                    label: cat.name,
                    selected: tempId == cat.id_category,
                    onTap: () => setSheet(() {
                      tempId   = cat.id_category;
                      tempName = cat.name;
                    }),
                  )),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _filterCategory     = tempId;
                      _filterCategoryName = tempName;
                    });
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Применить',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



  // ════════════════════════════════════════════════════
  // BOTTOM SHEET PICKER — dùng chung cho Year & Language
  // ════════════════════════════════════════════════════
  void _showPickerSheet({
    required String title,
    required IconData icon,
    required List<String> items,
    required String selected,
    required String allLabel,
    required ValueChanged<String> onApply,
  }) {
    String temp = selected;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 18, color: _orange),
                    ),
                    const SizedBox(width: 10),
                    Text(title, style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: _textDark,
                    )),
                  ]),
                  TextButton(
                    onPressed: () => setSheet(() => temp = ''),
                    child: const Text('Сбросить',
                        style: TextStyle(
                            color: _orange, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _pickerChip(
                    label: allLabel,
                    selected: temp.isEmpty,
                    onTap: () => setSheet(() => temp = ''),
                  ),
                  ...items.map((item) => _pickerChip(
                    label: item,
                    selected: temp == item,
                    onTap: () => setSheet(() => temp = item),
                  )),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onApply(temp);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Применить',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pickerChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? _orange : const Color(0xffFFF0E6),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? _orange : Colors.transparent),
          boxShadow: selected
              ? [BoxShadow(
              color: _orange.withOpacity(0.30),
              blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(label, style: TextStyle(
          color: selected ? Colors.white : Colors.grey.shade600,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 13,
        )),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // CONTENT
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
      // ── Wrap BookCopyBloc ở đây để toàn bộ content dùng chung copyByBook ──
      child: BlocBuilder<BookCopyBloc, BookCopyState>(
        builder: (context, copyState) {
          final copyByBook = _buildCopyMap(copyState);

          return BlocBuilder<BookBloc, BookState>(
            builder: (context, bookState) {
              if (bookState is BookLoading) {
                return const Center(
                    child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5));
              }
              if (bookState is BookError) {
                return Center(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(bookState.message,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 14)),
                    ]));
              }

              List<BookModel> allBooks = [];
              Map<String, List<BookModel>> byCategory = {};

              if (bookState is BookSuccess) {
                allBooks = bookState.books;
              } else if (bookState is BookByCategorySuccess) {
                allBooks   = bookState.allBooks;
                byCategory = bookState.booksByCategory;
              }

              if (allBooks.isNotEmpty) _cachedAllBooks = allBooks;

              if (_hasFilter) {
                return _filteredListView(_applyFilters(allBooks), copyByBook);
              }
              return _groupedView(byCategory, allBooks, copyByBook);
            },
          );
        },
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // VIEW 1 – GROUPED BY CATEGORY
  // ════════════════════════════════════════════════════
  Widget _groupedView(
      Map<String, List<BookModel>> byCategory,
      List<BookModel> allBooks,
      Map<int, BookCopyModel> copyByBook,
      ) {
    if (byCategory.isEmpty) {
      if (allBooks.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5));
      }
      return _horizontalScroll(
        allBooks,
        copyByBook,
            () => context.read<BookBloc>().add(GetBookEvent()),
      );
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
                      decoration: BoxDecoration(
                          color: _orange,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    Text(catName, style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: _textDark)),
                  ]),
                  Text(
                      context.tr('books.count', params: {'count': '${books.length}'}),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (books.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator(
                    color: _orange, strokeWidth: 2)),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: books.map((book) => BookCard(
                    book: book,
                    user: widget.user,
                    bookCopy: _getCopy(context, book.id_book, copyByBook),
                    authorFuture: Authorservice().getAuthorByID(book.id_author),
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

  // ════════════════════════════════════════════════════
  // HORIZONTAL SCROLL (dùng khi chưa có category)
  // ════════════════════════════════════════════════════
  Widget _horizontalScroll(
      List<BookModel> books,
      Map<int, BookCopyModel> copyByBook,
      VoidCallback onReload,
      ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: books.map((book) => BookCard(
          book: book,
          user: widget.user,
          bookCopy: _getCopy(context, book.id_book, copyByBook),
          authorFuture: Authorservice().getAuthorByID(book.id_author),
          onReload: onReload,
          onReservationLoad: () => context.read<ReservationBloc>()
              .add(GetReservationsByUserEvent(widget.user.id_user)),
        )).toList(),
      ),
    );
  }

  // ════════════════════════════════════════════════════
  // VIEW 2 – FILTERED LIST
  Widget _filteredListView(
      List<BookModel> books,
      Map<int, BookCopyModel> copyByBook,
      ) {
    final parts = <String>[];
    if (_filterCategory != null)    parts.add('"$_filterCategoryName"');
    if (_filterLanguage.isNotEmpty) parts.add(_filterLanguage);
    if (_filterYear != null)        parts.add('$_filterYear');
    if (_searchQuery.isNotEmpty)    parts.add('"$_searchQuery"');

    final subtitle = parts.isEmpty
        ? '${books.length} книг найдено'
        : '${books.length} книг · ${parts.join(' · ')}';

    if (books.isEmpty) {
      return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(context.tr('books.not_found_query'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade400, fontSize: 14, height: 1.5)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                    color: _orange, borderRadius: BorderRadius.circular(50)),
                child: Text(context.tr('books.reset_filters'),
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ]));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        child: Text(subtitle, style: TextStyle(
            fontSize: 13, color: Colors.grey.shade500,
            fontWeight: FontWeight.w500)),
      ),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          physics: const BouncingScrollPhysics(),
          itemCount: books.length,
          itemBuilder: (context, i) => _SearchItem(
            book: books[i],
            user: widget.user,
            bookCopy: _getCopy(context, books[i].id_book, copyByBook),
            authorFuture: Authorservice().getAuthorByID(books[i].id_author),
            onReload: () => context.read<BookBloc>().add(GetBookEvent()),
            onReservationLoad: () => context.read<ReservationBloc>()
                .add(GetReservationsByUserEvent(widget.user.id_user)),
          ),
        ),
      ),
    ]);
  }
}

// ════════════════════════════════════════════════════
// WIDGET: Nút chip filter có icon + label + mũi tên ▾
// ════════════════════════════════════════════════════
class _FilterDropChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color orange;
  final VoidCallback? onTap;

  const _FilterDropChip({
    required this.icon,
    required this.label,
    required this.active,
    required this.orange,
    required this.onTap,
  });


  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey.shade100
              : active ? orange : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: disabled
                ? Colors.grey.shade200
                : active ? orange : Colors.grey.shade300,
            width: 1.2,
          ),
          boxShadow: active
              ? [BoxShadow(
              color: orange.withOpacity(0.30),
              blurRadius: 8, offset: const Offset(0, 2))]
              : [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14,
              color: disabled
                  ? Colors.grey.shade400
                  : active ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: disabled
                ? Colors.grey.shade400
                : active ? Colors.white : Colors.grey.shade700,
          )),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16,
              color: disabled
                  ? Colors.grey.shade300
                  : active ? Colors.white : Colors.grey.shade500),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════
// COMPACT SEARCH RESULT ITEM
// ════════════════════════════════════════════════════
class _SearchItem extends StatelessWidget {
  final BookModel book;
  final UserModel user;
  final BookCopyModel bookCopy;
  final Future<AuthorModel> authorFuture;
  final VoidCallback onReload;
  final VoidCallback onReservationLoad;

  const _SearchItem({
    required this.book, required this.user,
    required this.authorFuture,
    required this.onReload, required this.onReservationLoad,required this.bookCopy,
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
        if (result == true && context.mounted) {
          onReload();
          onReservationLoad();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: Colors.brown.withOpacity(0.07),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
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

          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(book.title, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700,
                    color: _textDark),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
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
                  _chip('${book.publish_year}', Icons.calendar_today_rounded),_statusChip(bookCopy.status),
                ]),
              ])),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xffFFCCA8), size: 24),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    width: 60, height: 84,
    decoration: BoxDecoration(
      color: const Color(0xffFFEDD8),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.book_rounded, color: _orange, size: 30),
  );

  Widget _chip(String label, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: const Color(0xffFFF0E6),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: _orange),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
          fontSize: 11, color: _orange, fontWeight: FontWeight.w600)),
    ]),
  );

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return Colors.green;
      case 'borrowed':
        return Colors.red;
      case 'reserved':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Доступный';
      case 'borrowed':
        return 'Заимствованный';
      case 'reserved':
        return 'Заказ размещен';
      default:
        return 'Не определено';
    }
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 7, color: color),
          const SizedBox(width: 5),
          Text(
            _statusLabel(status),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}