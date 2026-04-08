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

class BookListScreen extends StatefulWidget {
  final UserModel user;
  const BookListScreen({super.key, required this.user});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  static const _orange = Color(0xffFF9E74);
  static const _bg = Color(0xffFBEEE4);
  static const _brown = Color(0xff5A3A1A);

  List<BookModel> _allBooks = [];
  Map<int, List<BookCopyModel>> _copyMap = {};
  final Set<int> _loadedIds = {};

  final _searchCtrl = TextEditingController();

  List<BookModel> get _filtered {
    final titleQ = _searchCtrl.text.trim().toLowerCase();
    return _allBooks.where((b) {
      final matchTitle =
          titleQ.isEmpty || b.title.toLowerCase().contains(titleQ);
      return matchTitle;
    }).toList();
  }

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

  void _lazyLoadCopies(List<BookModel> books) {
    for (final book in books) {
      if (!_loadedIds.contains(book.id_book)) {
        _loadedIds.add(book.id_book);
        context.read<BookCopyBloc>().add(
          GetBookByIdBookEvent(id_book: book.id_book),
        );
      }
    }
  }

  int _copyCount(int idBook) => _copyMap[idBook]?.length ?? 0;

  String _receivedDate(int idBook) {
    final copies = _copyMap[idBook];
    if (copies == null || copies.isEmpty) return '—';
    final dt = copies.first.received_date;
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }

  String _bookStatus(int idBook) {
    final copies = _copyMap[idBook];
    if (copies == null || copies.isEmpty) return 'unknown';
    return copies.first.status ?? 'unknown';
  }

  Future<void> _openAddBook() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<BookBloc>()),
          ],
          child: const AddBookScreen(),
        ),
      ),
    );

    if (result == true) _fetchBooks();
  }

  void _goToDetail(BookModel book) {
    final copies = _copyMap[book.id_book] ?? [];
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookDetailManager(book: book, copies: copies),
      ),
    );
  }

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

    if (result == true) {
      _loadedIds.remove(book.id_book);
      context.read<BookCopyBloc>().add(
        GetBookByIdBookEvent(id_book: book.id_book),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWebLayout = width >= 700;

    return MultiBlocListener(
      listeners: [
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
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
        BlocListener<BookCopyBloc, BookCopyState>(
          listener: (context, state) {
            if (state is BookCopyByIdBookSuccess) {
              setState(() => _copyMap = state.bookCopybyIdBook);
            }

            if (state is BookCopyError) {
              debugPrint('BookCopyError: ${state.message}');
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: _bg,
        appBar: _buildAppBar(isWebLayout),
        body: isWebLayout ? _buildWebBody() : _buildMobileBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isWebLayout) {
    return AppBar(
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
        if (isWebLayout)
          TextButton.icon(
            onPressed: _fetchBooks,
            icon: const Icon(Icons.refresh, color: _orange),
            label: const Text(
              'Обновить',
              style: TextStyle(color: _orange),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh, color: _orange),
            onPressed: _fetchBooks,
            tooltip: 'Обновить',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMobileBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: _searchBox(
                  _searchCtrl,
                  'Название книги',
                  Icons.search,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.filter_alt_off, color: _orange),
                tooltip: 'Удалить фильтр',
                onPressed: () => _searchCtrl.clear(),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add, color: _orange),
                tooltip: 'Добавить книги',
                onPressed: _openAddBook,
              ),
            ],
          ),
        ),
        _buildMobileHeader(),
        Expanded(
          child: BlocBuilder<BookBloc, BookState>(
            builder: (context, state) {
              if (state is BookLoading && _allBooks.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: _orange),
                );
              }

              if (_filtered.isEmpty) {
                return const Center(child: Text('Книг нет.'));
              }

              return RefreshIndicator(
                onRefresh: () async => _fetchBooks(),
                color: _orange,
                child: ListView.builder(
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => _buildMobileRow(_filtered[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWebBody() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              _buildWebToolbar(),
              const SizedBox(height: 16),
              Expanded(
                child: BlocBuilder<BookBloc, BookState>(
                  builder: (context, state) {
                    if (state is BookLoading && _allBooks.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: _orange),
                      );
                    }

                    if (_filtered.isEmpty) {
                      return const Center(child: Text('Книг нет.'));
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _fetchBooks(),
                      color: _orange,
                      child: _buildWebTable(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWebToolbar() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: _searchBox(
            _searchCtrl,
            'Название книги',
            Icons.search,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 150,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _searchCtrl.clear(),
            icon: const Icon(Icons.filter_alt_off, color: _orange, size: 18),
            label: const Text(
              'Сбросить',
              style: TextStyle(color: _orange),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: _orange),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 180,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _openAddBook,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'Добавить книгу',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebTable() {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1100),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(_orange),
                columnSpacing: 28,
                headingRowHeight: 56,
                dataRowMinHeight: 72,
                dataRowMaxHeight: 84,
                columns: const [
                  DataColumn(
                    label: Text(
                      'Книга',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'ISBN',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Дата получения',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Количество',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Статус',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  DataColumn(
                    label: Text(
                      'Действия',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                rows: _filtered.map(_buildWebDataRow).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  DataRow _buildWebDataRow(BookModel book) {
    final count = _copyCount(book.id_book);
    final dateStr = _receivedDate(book.id_book);
    final status = _bookStatus(book.id_book);
    final isLoaded = _loadedIds.contains(book.id_book);

    return DataRow(
      cells: [
        DataCell(
          SizedBox(
            width: 260,
            child: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            book.isbn.isEmpty ? '—' : book.isbn,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        DataCell(
          !isLoaded
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              color: _orange,
            ),
          )
              : Text(
            dateStr,
            style: const TextStyle(fontSize: 13),
          ),
        ),
        DataCell(
          !isLoaded
              ? const SizedBox.shrink()
              : Text(
            count.toString(),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        DataCell(_buildStatusChip(status)),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Редактировать',
                onPressed: () => _goToDetail(book),
                icon: const Icon(Icons.edit_outlined, color: _orange),
              ),
              IconButton(
                tooltip: 'Добавить экземпляр',
                onPressed: () => _goToAddCopy(book),
                icon: const Icon(Icons.add_circle_outline, color: _orange),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (v) {
                  if (v == 'detail') _goToDetail(book);
                  if (v == 'add_copy') _goToAddCopy(book);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'detail',
                    child: Text('Просмотреть информацию'),
                  ),
                  PopupMenuItem(
                    value: 'add_copy',
                    child: Text('Добавить копию'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    String label;
    Color fg;
    Color bg;

    switch (status.toLowerCase()) {
      case 'available':
        label = 'Доступно';
        fg = Colors.orange.shade800;
        bg = Colors.orange.shade100;
        break;
      case 'borrowed':
        label = 'Выдано';
        fg = Colors.cyan.shade800;
        bg = Colors.cyan.shade100;
        break;
      case 'reserved':
        label = 'Зарезервировано';
        fg = Colors.purple.shade800;
        bg = Colors.purple.shade100;
        break;
      default:
        label = '—';
        fg = Colors.grey.shade700;
        bg = Colors.grey.shade200;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _searchBox(TextEditingController ctrl, String hint, IconData icon) {
    return SizedBox(
      height: 48,
      child: TextField(
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
      ),
    );
  }

  Widget _buildMobileHeader() {
    return Container(
      color: _orange,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: const Row(
        children: [
          Expanded(flex: 3, child: _HeaderCell('Книга')),
          Expanded(flex: 3, child: _HeaderCell('Дата получения')),
          Expanded(flex: 1, child: _HeaderCell('Количество')),
          SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildMobileRow(BookModel book) {
    final count = _copyCount(book.id_book);
    final dateStr = _receivedDate(book.id_book);
    final isLoaded = _loadedIds.contains(book.id_book);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
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
          Expanded(
            flex: 3,
            child: !isLoaded
                ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: _orange,
              ),
            )
                : Text(
              dateStr,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: !isLoaded
                ? const SizedBox.shrink()
                : Text(
              count.toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onSelected: (v) {
              if (v == 'detail') _goToDetail(book);
              if (v == 'add_copy') _goToAddCopy(book);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'detail',
                child: ListTile(
                  leading: Icon(Icons.info_outline, color: _orange),
                  title: Text('Просмотреть информацию'),
                  dense: true,
                ),
              ),
              PopupMenuItem(
                value: 'add_copy',
                child: ListTile(
                  leading: Icon(Icons.add_circle_outline, color: _orange),
                  title: Text('Добавить копию'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontFamily: 'Times New Roman',
        fontSize: 13,
      ),
    );
  }
}