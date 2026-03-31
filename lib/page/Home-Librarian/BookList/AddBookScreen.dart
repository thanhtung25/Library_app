import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../bloc/author/bloc.dart';
import '../../../bloc/author/event.dart' as author_event;
import '../../../bloc/author/state.dart' as author_state;
import '../../../bloc/category/bloc.dart';
import '../../../bloc/category/event.dart' as category_event;
import '../../../bloc/category/state.dart' as category_state;
import '../../../bloc/book/bloc.dart';
import '../../../bloc/book/event.dart';
import '../../../bloc/book/state.dart';
import '../../../model/author_model.dart';
import '../../../model/category_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Palette
// ─────────────────────────────────────────────────────────────────────────────
const _orange  = Color(0xffFF9E74);
const _bg      = Color(0xffFBEEE4);
const _brown   = Color(0xff5A3A1A);
const _white   = Colors.white;
const _cardBg  = Color(0xffFFFFFF);
const _divider = Color(0xffF0E0D0);

// ─────────────────────────────────────────────────────────────────────────────
//  AddBookScreen
// ─────────────────────────────────────────────────────────────────────────────
class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  File? _pickedImageFile;
  bool _bookCreated = false;

  // ── Выбранные значения ──────────────────────────────────────────────────────
  CategoryModel? _selectedCategory;
  AuthorModel?   _selectedAuthor;
  int?           _selectedYear;

  // ── Controllers ────────────────────────────────────────────────────────────
  final _titleCtrl    = TextEditingController();
  final _isbnCtrl     = TextEditingController();
  final _languageCtrl = TextEditingController();
  final _descCtrl     = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Загружаем списки жанров и авторов при открытии экрана
    context.read<CategoryBloc>().add(category_event.GetAllCategoryEvent());
    context.read<AuthorBloc>().add(author_event.GetAllAuthorsEvent());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _isbnCtrl.dispose();
    _languageCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      _showSnack('Выберите жанр', Colors.redAccent);
      return;
    }
    if (_selectedAuthor == null) {
      _showSnack('Выберите автора', Colors.redAccent);
      return;
    }
    if (_selectedYear == null) {
      _showSnack('Выберите год издания', Colors.redAccent);
      return;
    }
    // Reset flag trước mỗi lần submit để tránh lỗi từ lần trước ảnh hưởng
    _bookCreated = false;
    context.read<BookBloc>().add(
      CreateBookEvent(
        id_category:  _selectedCategory!.id_category,
        id_author:    _selectedAuthor!.id_author,
        title:        _titleCtrl.text.trim(),
        isbn:         _isbnCtrl.text.trim(),
        language:     _languageCtrl.text.trim(),
        publish_year: _selectedYear!,
        description:  _descCtrl.text.trim(),
        image_url:    '',
        created_at:   DateTime.now(),
      ),
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ── Выбор года ──────────────────────────────────────────────────────────────
  Future<void> _pickYear() async {
    final now = DateTime.now().year;
    int tempYear = _selectedYear ?? now;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Год издания',
            style: TextStyle(color: _brown, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            height: 200,
            width: 200,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return ListWheelScrollView.useDelegate(
                  itemExtent: 44,
                  perspective: 0.005,
                  diameterRatio: 1.6,
                  physics: const FixedExtentScrollPhysics(),
                  controller: FixedExtentScrollController(
                    initialItem: now - tempYear,
                  ),
                  onSelectedItemChanged: (i) {
                    setDialogState(() => tempYear = now - i);
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: now - 1800 + 1,
                    builder: (context, i) {
                      final y = now - i;
                      final selected = y == tempYear;
                      return Center(
                        child: Text(
                          '$y',
                          style: TextStyle(
                            fontSize: selected ? 20 : 15,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            color: selected ? _orange : _brown.withOpacity(0.5),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена', style: TextStyle(color: Colors.black45)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() => _selectedYear = tempYear);
                Navigator.pop(ctx);
              },
              child: const Text('Выбрать', style: TextStyle(color: _white)),
            ),
          ],
        );
      },
    );
  }

  // ── Выбор жанра — читаем из CategoryBloc state ──────────────────────────────
  Future<void> _pickCategory() async {
    final categoryState = context.read<CategoryBloc>().state;

    if (categoryState is category_state.CategoryLoading) {
      _showSnack('Загрузка жанров…', _orange);
      return;
    }

    final List<CategoryModel> categories =
    categoryState is category_state.CategorySuccess
        ? categoryState.category
        : [];

    if (categories.isEmpty) {
      _showSnack('Список жанров пуст', Colors.black54);
      return;
    }

    final result = await showModalBottomSheet<CategoryModel>(
      context: context,
      backgroundColor: _cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SelectBottomSheet<CategoryModel>(
        title: 'Выбрать жанр',
        items: categories,
        labelBuilder: (c) => c.name,
        subtitleBuilder: (c) => c.description.isNotEmpty ? c.description : null,
        selected: _selectedCategory,
        onCreateNew: () => _showCreateCategoryDialog(context),
      ),
    );
    if (result != null) setState(() => _selectedCategory = result);
  }

  // ── Выбор автора — читаем из AuthorBloc state ───────────────────────────────
  Future<void> _pickAuthor() async {
    final authorState = context.read<AuthorBloc>().state;

    if (authorState is author_state.AuthorLoading) {
      _showSnack('Загрузка авторов…', _orange);
      return;
    }

    final List<AuthorModel> authors =
    authorState is author_state.AuthorListLoaded
        ? authorState.authors
        : [];

    if (authors.isEmpty) {
      _showSnack('Список авторов пуст', Colors.black54);
      return;
    }

    final result = await showModalBottomSheet<AuthorModel>(
      context: context,
      backgroundColor: _cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _SelectBottomSheet<AuthorModel>(
        title: 'Выбрать автора',
        items: authors,
        labelBuilder: (a) => a.full_name,
        subtitleBuilder: (a) => a.biography.isNotEmpty ? a.biography : null,
        selected: _selectedAuthor,
        onCreateNew: () => _showCreateAuthorDialog(context),
      ),
    );
    if (result != null) setState(() => _selectedAuthor = result);
  }

  // ── Выбор фото ──────────────────────────────────────────────────────────────
  Future<void> _pickImagePreview() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile == null) return;
      setState(() => _pickedImageFile = File(pickedFile.path));
    } catch (e) {
      _showSnack('Ошибка выбора изображения: $e', Colors.redAccent);
    }
  }

  Future<void> pickAndUploadimg(int id_book) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pickedFile == null) return;
      final file = File(pickedFile.path);
      setState(() => _pickedImageFile = file);
      context.read<BookBloc>().add(
        UploadImgBookSubmitted(id_book: id_book, imageFile: file),
      );
    } catch (e) {
      _showSnack('Ошибка выбора изображения: $e', Colors.redAccent);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          // Lắng nghe khi tạo tác giả thành công → reload + snack
          BlocListener<AuthorBloc, author_state.AuthorState>(
            listener: (context, state) {
              if (state is author_state.AuthorCreatedSuccess) {
                context.read<AuthorBloc>().add(author_event.GetAllAuthorsEvent());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tác giả đã được thêm!'),
                    backgroundColor: _orange,
                  ),
                );
              }
              if (state is author_state.AuthorError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${state.message}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
          // Lắng nghe khi tạo category thành công → reload + snack
          BlocListener<CategoryBloc, category_state.CategoryState>(
            listener: (context, state) {
              if (state is category_state.CategoryCreatedSuccess) {
                context.read<CategoryBloc>().add(category_event.GetAllCategoryEvent());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Thể loại đã được thêm!'),
                    backgroundColor: _orange,
                  ),
                );
              }
              if (state is category_state.CategoryError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: ${state.message}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocConsumer<BookBloc, BookState>(
          listener: (context, state) {
            if (state is BookCreatedSuccess) {
              if (_pickedImageFile != null) {
                _bookCreated = true;
                context.read<BookBloc>().add(
                  UploadImgBookSubmitted(
                    id_book: state.book.id_book,
                    imageFile: _pickedImageFile!,
                  ),
                );
              } else {
                _showSnack('Книга успешно добавлена!', _orange);
                Navigator.pop(context, true);
              }
            }

            if (state is ImgBookUploadSuccess) {
              _showSnack('Книга успешно добавлена!', _orange);
              Navigator.pop(context, true);
            }
            if (state is BookError) {
              if (_bookCreated) {
                _bookCreated = false;
                _showSnack('Книга добавлена, но не удалось загрузить изображение', Colors.orange);
                Navigator.pop(context, true);
              } else {
                _showSnack('Ошибка: ${state.message}', Colors.redAccent);
              }
            }
          },
          builder: (context, state) {
            final isLoading = state is BookLoading || state is UploadImageLoading;
            return Scaffold(
              backgroundColor: _bg,
              appBar: _buildAppBar(isLoading),
              body: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Обложка ────────────────────────────────────────────────
                      _buildCoverSection(),
                      const SizedBox(height: 24),

                      // ── Информация о книге ─────────────────────────────────────
                      const _SectionHeader(
                        icon: Icons.menu_book_rounded,
                        label: 'Информация о книге',
                      ),
                      const SizedBox(height: 12),
                      _buildCard([
                        _FormField(
                          controller: _titleCtrl,
                          label: 'Название книги',
                          hint: 'Введите название',
                          icon: Icons.title,
                          validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Введите название книги' : null,
                        ),
                        _dividerLine(),
                        _FormField(
                          controller: _isbnCtrl,
                          label: 'ISBN',
                          hint: 'Введите код ISBN',
                          icon: Icons.qr_code,
                          validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Введите ISBN' : null,
                        ),
                        _dividerLine(),
                        _FormField(
                          controller: _languageCtrl,
                          label: 'Язык',
                          hint: 'Например: Русский',
                          icon: Icons.translate,
                        ),
                        _dividerLine(),
                        _YearPickerTile(
                          selectedYear: _selectedYear,
                          onTap: _pickYear,
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Жанр и автор ──────────────────────────────────────────
                      const _SectionHeader(
                        icon: Icons.category_rounded,
                        label: 'Жанр и автор',
                      ),
                      const SizedBox(height: 12),
                      _buildCard([
                        // Индикатор загрузки жанров
                        BlocBuilder<CategoryBloc, category_state.CategoryState>(
                          builder: (context, catState) {
                            return _SelectorTile(
                              icon: Icons.category,
                              label: 'Жанр',
                              value: _selectedCategory?.name,
                              placeholder: catState is category_state.CategoryLoading
                                  ? 'Загрузка…'
                                  : 'Выбрать жанр',
                              isLoading: catState is category_state.CategoryLoading,
                              onTap: _pickCategory,
                            );
                          },
                        ),
                        _dividerLine(),
                        // Индикатор загрузки авторов
                        BlocBuilder<AuthorBloc, author_state.AuthorState>(
                          builder: (context, authState) {
                            return _SelectorTile(
                              icon: Icons.person,
                              label: 'Автор',
                              value: _selectedAuthor?.full_name,
                              placeholder: authState is author_state.AuthorLoading
                                  ? 'Загрузка…'
                                  : 'Выбрать автора',
                              isLoading: authState is author_state.AuthorLoading,
                              onTap: _pickAuthor,
                            );
                          },
                        ),
                      ]),

                      const SizedBox(height: 20),

                      // ── Описание ──────────────────────────────────────────────
                      const _SectionHeader(
                        icon: Icons.description_rounded,
                        label: 'Описание',
                      ),
                      const SizedBox(height: 12),
                      _buildCard([
                        _FormField(
                          controller: _descCtrl,
                          label: 'Описание книги',
                          hint: 'Введите краткое описание…',
                          icon: Icons.notes,
                          maxLines: 4,
                        ),
                      ]),

                      const SizedBox(height: 28),

                      // ── Кнопка добавления ─────────────────────────────────────
                      _SubmitButton(
                        label: 'Добавить книгу',
                        isLoading: isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ) // end BlocConsumer
    ); // end MultiBlocListener
  } // end build

  // ── AppBar ─────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(bool isLoading) => AppBar(
    backgroundColor: _bg,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: _brown),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Добавить книгу',
      style: TextStyle(color: _brown, fontWeight: FontWeight.bold, fontSize: 17),
    ),
  );

  // ── Секция обложки ─────────────────────────────────────────────────────────
  Widget _buildCoverSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 100,
          height: 138,
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _orange.withOpacity(0.5), width: 1.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _pickedImageFile != null
                ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
                : _coverPlaceholder(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Обложка книги',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600, color: _brown)),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImagePreview,
                  icon: const Icon(Icons.upload_rounded, color: _orange, size: 18),
                  label: Text(
                    _pickedImageFile == null ? 'Выбрать изображение' : 'Изменить фото',
                    style: const TextStyle(
                        color: _brown, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _orange.withOpacity(0.7)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: _cardBg,
                  ),
                ),
              ),
              if (_pickedImageFile != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text('Изображение выбрано',
                        style: TextStyle(fontSize: 11, color: Colors.green)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverPlaceholder() => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.menu_book_rounded, color: _orange.withOpacity(0.5), size: 32),
      const SizedBox(height: 6),
      Text('Обложка',
          style: TextStyle(fontSize: 11, color: _orange.withOpacity(0.7))),
    ],
  );

  Widget _buildCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: _cardBg,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 10,
            offset: const Offset(0, 3)),
      ],
    ),
    child: Column(children: children),
  );

  Widget _dividerLine() =>
      Divider(height: 1, color: _divider, indent: 16, endIndent: 16);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Плитка выбора года
// ─────────────────────────────────────────────────────────────────────────────
class _YearPickerTile extends StatelessWidget {
  final int? selectedYear;
  final VoidCallback onTap;
  const _YearPickerTile({required this.selectedYear, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: _orange, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Год издания',
                      style: TextStyle(fontSize: 12, color: Colors.black45)),
                  const SizedBox(height: 2),
                  Text(
                    selectedYear != null ? '$selectedYear' : 'Нажмите, чтобы выбрать',
                    style: TextStyle(
                      fontSize: 14,
                      color: selectedYear != null ? Colors.black87 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.expand_more, color: _orange, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Плитка выбора жанра / автора
// ─────────────────────────────────────────────────────────────────────────────
class _SelectorTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String placeholder;
  final bool isLoading;
  final VoidCallback onTap;

  const _SelectorTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: _orange, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 12, color: Colors.black45)),
                  const SizedBox(height: 2),
                  Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      color: value != null ? Colors.black87 : Colors.black26,
                    ),
                  ),
                ],
              ),
            ),
            isLoading
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _orange),
            )
                : Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    value != null ? Icons.edit_outlined : Icons.add,
                    color: _orange,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    value != null ? 'Изменить' : 'Добавить',
                    style: const TextStyle(
                        fontSize: 12,
                        color: _orange,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper — mở dialog tạo Author / Category
// ─────────────────────────────────────────────────────────────────────────────
Future<void> _showCreateAuthorDialog(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => _CreateAuthorDialog(),
    );

Future<void> _showCreateCategoryDialog(BuildContext context) =>
    showDialog<void>(
      context: context,
      builder: (_) => _CreateCategoryDialog(),
    );

// ─────────────────────────────────────────────────────────────────────────────
//  Dialog tạo Author mới  (StatefulWidget — lifecycle an toàn)
// ─────────────────────────────────────────────────────────────────────────────
class _CreateAuthorDialog extends StatefulWidget {
  const _CreateAuthorDialog();
  @override
  State<_CreateAuthorDialog> createState() => _CreateAuthorDialogState();
}

class _CreateAuthorDialogState extends State<_CreateAuthorDialog> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _bioCtrl  = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthorBloc>().add(
      author_event.CreateAuthorEvent(
        full_name: _nameCtrl.text.trim(),
        biography: _bioCtrl.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Thêm tác giả mới',
        style: TextStyle(color: _brown, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: _inputDecoration('Họ tên tác giả *', Icons.person_outline),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              decoration: _inputDecorationMultiline('Tiểu sử (tùy chọn)', Icons.notes_outlined),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.black45)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submit,
          child: const Text('Tạo', style: TextStyle(color: _white)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dialog tạo Category mới  (StatefulWidget — lifecycle an toàn)
// ─────────────────────────────────────────────────────────────────────────────
class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog();
  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final _formKey  = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<CategoryBloc>().add(
      category_event.CreateCategoryEvent(
        name:        _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Thêm thể loại mới',
        style: TextStyle(color: _brown, fontWeight: FontWeight.bold, fontSize: 16),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              autofocus: true,
              decoration: _inputDecoration('Tên thể loại *', Icons.category_outlined),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Vui lòng nhập tên' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: _inputDecorationMultiline('Mô tả (tùy chọn)', Icons.notes_outlined),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy', style: TextStyle(color: Colors.black45)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _submit,
          child: const Text('Tạo', style: TextStyle(color: _white)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers tạo InputDecoration dùng chung
// ─────────────────────────────────────────────────────────────────────────────
InputDecoration _inputDecoration(String label, IconData icon) => InputDecoration(
  labelText: label,
  labelStyle: const TextStyle(fontSize: 13, color: Colors.black45),
  prefixIcon: Icon(icon, color: _orange, size: 20),
  filled: true,
  fillColor: _bg,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide.none,
  ),
  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
);

InputDecoration _inputDecorationMultiline(String label, IconData icon) =>
    InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 13, color: Colors.black45),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(bottom: 40),
        child: Icon(icon, color: _orange, size: 20),
      ),
      filled: true,
      fillColor: _bg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
    );

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom sheet выбора из списка
// ─────────────────────────────────────────────────────────────────────────────
class _SelectBottomSheet<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) labelBuilder;
  final String? Function(T)? subtitleBuilder;
  final T? selected;
  /// Callback hiển thị khi nhấn nút "Tạo mới" — null thì không hiện nút
  final VoidCallback? onCreateNew;

  const _SelectBottomSheet({
    required this.title,
    required this.items,
    required this.labelBuilder,
    this.subtitleBuilder,
    this.selected,
    this.onCreateNew,
  });

  @override
  State<_SelectBottomSheet<T>> createState() => _SelectBottomSheetState<T>();
}

class _SelectBottomSheetState<T> extends State<_SelectBottomSheet<T>> {
  late List<T> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _searchCtrl.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.items
          .where((i) => widget.labelBuilder(i).toLowerCase().contains(q))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(widget.title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: _brown)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Поиск…',
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: _orange, size: 20),
                filled: true,
                fillColor: _bg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // ── Nút tạo mới ──────────────────────────────────────────────────
          if (widget.onCreateNew != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // đóng bottom sheet trước
                    widget.onCreateNew!();
                  },
                  icon: const Icon(Icons.add_circle_outline, color: _orange, size: 18),
                  label: const Text(
                    'Tạo mới',
                    style: TextStyle(color: _orange, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _orange),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 4),
          Divider(height: 1, color: _divider),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.45,
            ),
            child: _filtered.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Ничего не найдено',
                  style: TextStyle(color: Colors.black38)),
            )
                : ListView.separated(
              shrinkWrap: true,
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: _divider, indent: 16, endIndent: 16),
              itemBuilder: (ctx, i) {
                final item = _filtered[i];
                final isSelected = item == widget.selected;
                final subtitle = widget.subtitleBuilder?.call(item);
                return ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _orange.withOpacity(0.2)
                          : _orange.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isSelected ? Icons.check : Icons.label_outline,
                      color: _orange,
                      size: 18,
                    ),
                  ),
                  title: Text(widget.labelBuilder(item),
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                          color: _brown)),
                  subtitle: subtitle != null
                      ? Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45))
                      : null,
                  onTap: () => Navigator.pop(ctx, item),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Общие вспомогательные виджеты
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: _orange.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: _orange, size: 16),
      ),
      const SizedBox(width: 8),
      Text(label,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14, color: _brown)),
    ],
  );
}

class _FormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final bool readOnly;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _FormField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.readOnly = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        crossAxisAlignment:
        maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
            child: Icon(icon, color: _orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: maxLines,
              readOnly: readOnly,
              keyboardType: keyboardType,
              validator: validator,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                labelText: label,
                labelStyle:
                const TextStyle(fontSize: 12, color: Colors.black45),
                hintText: hint,
                hintStyle:
                const TextStyle(color: Colors.black26, fontSize: 13),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                errorStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _SubmitButton(
      {required this.label, required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _orange,
        elevation: 2,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              color: _white, strokeWidth: 2.5))
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline, color: _white, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: _white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    ),
  );
}