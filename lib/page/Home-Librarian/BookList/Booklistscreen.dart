import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';
import 'package:library_app/model/user_model.dart';

// ─── Simple model ─────────────────────────────────────────────────────────────
class _Book {
  final int id;
  final String title;
  final String author;
  final String category;
  final int quantity;
  final String receivedDate;

  _Book({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.quantity,
    required this.receivedDate,
  });

  factory _Book.fromJson(Map<String, dynamic> j) => _Book(
    id: j['id_book'] ?? 0,
    title: j['title'] ?? '',
    author: j['author'] ?? '',
    category: j['category'] ?? '',
    quantity: j['quantity'] ?? 0,
    receivedDate: j['received_date'] ?? '',
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class BookListScreen extends StatefulWidget {
  final UserModel user;
  const BookListScreen({super.key, required this.user});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  static const _orange = Color(0xffFF9E74);
  static const _bg = Color(0xffFBEEE4);

  final _searchCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();

  List<_Book> _books = [];
  List<_Book> _filtered = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBooks();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _authorCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchBooks() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.get('/books-management/books');
      final list = (data['books'] as List? ?? data as List)
          .map((e) => _Book.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() { _books = list; _filtered = list; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    final a = _authorCtrl.text.toLowerCase();
    setState(() {
      _filtered = _books.where((b) {
        final matchTitle  = q.isEmpty || b.title.toLowerCase().contains(q);
        final matchAuthor = a.isEmpty || b.author.toLowerCase().contains(a);
        return matchTitle && matchAuthor;
      }).toList();
    });
  }

  // ── Add / Edit dialog ──────────────────────────────────────────────────────
  Future<void> _showBookDialog({_Book? book}) async {
    final titleCtrl  = TextEditingController(text: book?.title  ?? '');
    final authorCtrl = TextEditingController(text: book?.author ?? '');
    final qtyCtrl    = TextEditingController(text: book?.quantity.toString() ?? '1');
    final isEdit     = book != null;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? 'Chỉnh sửa sách' : 'Thêm sách mới',
          style: const TextStyle(fontFamily: 'Times New Roman', color: _orange),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(titleCtrl,  'Tên sách'),
            const SizedBox(height: 12),
            _dialogField(authorCtrl, 'Tác giả'),
            const SizedBox(height: 12),
            _dialogField(qtyCtrl,    'Số lượng', keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                if (isEdit) {
                  await ApiService.put('/books-management/book/${book.id}', {
                    'title': titleCtrl.text.trim(),
                    'author': authorCtrl.text.trim(),
                    'quantity': int.tryParse(qtyCtrl.text.trim()) ?? 1,
                  });
                } else {
                  await ApiService.post('/books-management/book', {
                    'title': titleCtrl.text.trim(),
                    'author': authorCtrl.text.trim(),
                    'quantity': int.tryParse(qtyCtrl.text.trim()) ?? 1,
                  });
                }
                _fetchBooks();
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: Text(
              isEdit ? 'Lưu' : 'Thêm',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBook(_Book book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xoá',
            style: TextStyle(fontFamily: 'Times New Roman')),
        content: Text('Xoá sách "${book.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.delete('/books-management/book/${book.id}');
        _fetchBooks();
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Danh sách sách',
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
          ),
        ],
      ),

      // ── Search bar ─────────────────────────────────────────────────────────
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Expanded(child: _searchBox(_searchCtrl, 'Tên sách', Icons.search)),
                const SizedBox(width: 8),
                Expanded(child: _searchBox(_authorCtrl, 'Tác giả', Icons.person)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_alt, color: _orange),
                  onPressed: _applyFilter,
                ),
              ],
            ),
          ),

          // ── Table header ─────────────────────────────────────────────────
          _tableHeader(),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _orange))
                : _error != null
                ? Center(child: Text(_error!,
                style: const TextStyle(color: Colors.red)))
                : _filtered.isEmpty
                ? const Center(child: Text('Không có sách nào'))
                : RefreshIndicator(
              onRefresh: _fetchBooks,
              color: _orange,
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _bookRow(_filtered[i]),
              ),
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: _orange,
        onPressed: () => _showBookDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _searchBox(TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      onChanged: (_) => _applyFilter(),
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: _orange),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
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
          Expanded(flex: 3, child: _HeaderCell('Sách')),
          Expanded(flex: 2, child: _HeaderCell('Ngày nhập')),
          Expanded(flex: 1, child: _HeaderCell('SL')),
          SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _bookRow(_Book book) {
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
              child: Text(book.title,
                  style: const TextStyle(fontFamily: 'Times New Roman',
                      fontSize: 13)),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(book.receivedDate,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          Expanded(
            flex: 1,
            child: Text(book.quantity.toString(),
                style: const TextStyle(fontSize: 13)),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onSelected: (v) {
              if (v == 'edit')   _showBookDialog(book: book);
              if (v == 'delete') _deleteBook(book);
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit',
                  child: ListTile(leading: Icon(Icons.edit), title: Text('Sửa'))),
              PopupMenuItem(value: 'delete',
                  child: ListTile(leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Xoá', style: TextStyle(color: Colors.red)))),
            ],
          ),
        ],
      ),
    );
  }

  TextField _dialogField(TextEditingController ctrl, String label,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: _orange),
        ),
      ),
    );
  }
}

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