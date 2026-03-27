import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/book_copy_model.dart';
import 'package:library_app/model/user_model.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/book_copy/bloc.dart';
import 'package:library_app/bloc/book_copy/event.dart';
import 'package:library_app/bloc/book_copy/state.dart';

import 'BookDetailManager.dart';
import 'AddBookScreen.dart';
import 'AddBookCopyScreen.dart';


// ─── Screen ───────────────────────────────────────────────────────────────────
class BookListScreen extends StatefulWidget {
  final UserModel user;
  const BookListScreen({super.key, required this.user});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  static const _orange = Color(0xffFF9E74);
  static const _bg     = Color(0xffFBEEE4);

  // ── Dữ liệu Book ──────────────────────────────────────────────────────────
  List<BookModel> _allBooks = [];

  // ── Dữ liệu BookCopy: id_book → danh sách bản sao ─────────────────────────
  Map<int, List<BookCopyModel>> _copyMap = {};

  // id_book đã được gọi lazy-load, tránh gọi lặp
  final Set<int> _loadedIds = {};

  // ── Search ────────────────────────────────────────────────────────────────
  final _searchCtrl = TextEditingController();
  List<BookModel> get _filtered {
    final titleQ  = _searchCtrl.text.trim().toLowerCase();
    return _allBooks.where((b) {
      final matchTitle  = titleQ.isEmpty  || b.title.toLowerCase().contains(titleQ);
      return matchTitle ;
    }).toList();
  }

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    _fetchBooks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _fetchBooks() {
    _loadedIds.clear();
    context.read<BookBloc>().add(GetBookEvent());
  }

  /// Lazy-load BookCopy cho từng book chưa được load
  void _lazyLoadCopies(List<BookModel> books) {
    for (final book in books) {
      if (!_loadedIds.contains(book.id_book)) {
        _loadedIds.add(book.id_book);
        context
            .read<BookCopyBloc>()
            .add(GetBookByIdBookEvent(id_book: book.id_book));
      }
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  int _copyCount(int idBook) => _copyMap[idBook]?.length ?? 0;

  String _receivedDate(int idBook) {
    final copies = _copyMap[idBook];
    if (copies == null || copies.isEmpty) return '—';
    final dt = copies.first.received_date;
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}'
        '.${dt.month.toString().padLeft(2, '0')}'
        '.${dt.year}';
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // ── BookBloc listener ────────────────────────────────────────────────
        BlocListener<BookBloc, BookState>(
          listener: (context, state) {
            if (state is BookSuccess) {
              setState(() => _allBooks = state.books);
              _lazyLoadCopies(state.books);
            }
            if (state is BookCreatedSuccess ||
                state is BookUpdatedSuccess ||
                state is BookDeletedSuccess) {
              _fetchBooks();
            }
            if (state is BookError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red),
              );
            }
          },
        ),
        // ── BookCopyBloc listener ─────────────────────────────────────────────
        BlocListener<BookCopyBloc, BookCopyState>(
          listener: (context, state) {
            if (state is BookCopyByIdBookSuccess) {
              setState(() => _copyMap = state.bookCopybyIdBook);
            }
            if (state is BookCopyError) {
              // im lặng — không làm gián đoạn UI chính
              debugPrint('BookCopyError: ${state.message}');
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: _bg,
          elevation: 0,
          title: const Text(
            'Список книг',
            style: TextStyle(
              fontFamily: 'Times New Roman',
              fontWeight: FontWeight.bold,
              color: _orange,
              fontSize: 22,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: _orange),
              onPressed: _fetchBooks,
              tooltip: 'Làm mới',
            ),
          ],
        ),

        body: Column(
          children: [
            // ── Search bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                      child: _searchBox(_searchCtrl, 'Название книги', Icons.search)),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off, color: _orange),
                    tooltip: 'Xóa bộ lọc',
                    onPressed: () {
                      _searchCtrl.clear();
                    },
                  ), const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add, color: _orange),
                    tooltip: 'Thêm sách',
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MultiBlocProvider(
                            providers: [
                              BlocProvider.value(
                                  value: context.read<BookBloc>()),
                            ],
                            child: const AddBookScreen(),
                          ),
                        ),
                      );
                      if (result == true) _fetchBooks();
                    },
                  ),
                ],
              ),
            ),

            // ── Table header ─────────────────────────────────────────────────
            _tableHeader(),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: BlocBuilder<BookBloc, BookState>(
                builder: (context, state) {
                  if (state is BookLoading && _allBooks.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(color: _orange));
                  }
                  if (_filtered.isEmpty) {
                    return const Center(child: Text('Không có sách nào'));
                  }
                  return RefreshIndicator(
                    onRefresh: () async => _fetchBooks(),
                    color: _orange,
                    child: ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => _bookRow(_filtered[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ───────────────────────────────────────────────────────────────

  Widget _searchBox(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: _orange),
        suffixIcon: ctrl.text.isNotEmpty
            ? GestureDetector(
          onTap: () => ctrl.clear(),
          child: const Icon(Icons.close, size: 16, color: Colors.grey),
        )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
        const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      color: _orange,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('Книга')),
          Expanded(flex: 3, child: _HeaderCell('Дата получения')),
          Expanded(flex: 1, child: _HeaderCell('Количество')),
          SizedBox(width: 40), // chỗ cho icon menu
        ],
      ),
    );
  }

  Widget _bookRow(BookModel book) {
    final count    = _copyCount(book.id_book);
    final dateStr  = _receivedDate(book.id_book);
    final isLoaded = _loadedIds.contains(book.id_book);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // ── Tên sách ──────────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
              child: Text(
                book.title,
                style: const TextStyle(
                  fontFamily: 'Times New Roman',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),

          // ── Ngày nhận ─────────────────────────────────────────────────────
          Expanded(
            flex: 3,
            child: !isLoaded
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: _orange),
            )
                : Text(
              dateStr,
              style: const TextStyle(
                  fontSize: 12, color: Colors.black87),
            ),
          ),

          // ── Số lượng ──────────────────────────────────────────────────────
          Expanded(
            flex: 1,
            child: !isLoaded
                ? const SizedBox.shrink()
                : Text(
              count.toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // ── Menu ─────────────────────────────────────────────────────────
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onSelected: (v) {
              if (v == 'detail')    _goToDetail(book);
              if (v == 'add_copy')  _goToAddCopy(book);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'detail',
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: _orange),
                  title: Text('Xem thông tin'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'add_copy',
                child: ListTile(
                  leading: Icon(Icons.add_circle_outline, color: _orange),
                  title: Text('Thêm bản sao'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Navigate to detail ────────────────────────────────────────────────────
  void _goToDetail(BookModel book) {
    final copies = _copyMap[book.id_book] ?? [];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailManager(book: book, copies: copies),
      ),
    );
  }

  // ─── Navigate to AddBookCopy ───────────────────────────────────────────────
  void _goToAddCopy(BookModel book) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<BookCopyBloc>()),
          ],
          child: AddBookCopyScreen(idBook: book.id_book),
        ),
      ),
    );
    // Reload bản sao của sách này nếu thêm thành công
    if (result == true) {
      _loadedIds.remove(book.id_book);
      context
          .read<BookCopyBloc>()
          .add(GetBookByIdBookEvent(id_book: book.id_book));
    }
  }
}   // end _BookListScreenState


class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontFamily: 'Times New Roman',
      fontSize: 13,
    ),
  );
}