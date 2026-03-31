import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/api_localhost/ApiService.dart';
import 'package:library_app/bloc/author/bloc.dart';
import 'package:library_app/bloc/author/state.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book_copy/event.dart' as copy_event;

import '../../../bloc/author/event.dart';
import '../../../bloc/book/bloc.dart';
import '../../../bloc/book/state.dart';
import '../../../bloc/book_copy/bloc.dart';
import '../../../bloc/book_copy/state.dart' as copy_state;
import '../../../model/book_copy_model.dart';
import '../../../model/book_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Color palette
// ─────────────────────────────────────────────────────────────────────────────
const _orange = Color(0xffFF9E74);
const _bg     = Color(0xffFBEEE4);
const _brown  = Color(0xff5A3A1A);
const _white  = Colors.white;

// ─────────────────────────────────────────────────────────────────────────────
//  BookDetailManager
// ─────────────────────────────────────────────────────────────────────────────
class BookDetailManager extends StatefulWidget {
  final BookModel book;
  final List<BookCopyModel> copies;

  const BookDetailManager({
    super.key,
    required this.book,
    required this.copies,
  });

  @override
  State<BookDetailManager> createState() => _BookDetailManagerState();
}

class _BookDetailManagerState extends State<BookDetailManager> {
  // ── Text controllers ───────────────────────────────────────────────────────
  late final TextEditingController _titleCtrl;
  late final TextEditingController _isbnCtrl;
  late final TextEditingController _languageCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _quantityCtrl;

  // ── Local UI state ─────────────────────────────────────────────────────────
  String? _authorName;
  bool    _authorLoading = true;

  // ── Image upload ───────────────────────────────────────────────────────────
  final ImagePicker _picker = ImagePicker();
  File? _pickedImageFile;
  bool  _imageUploading = false;

  // Trạng thái của BookCopy (khớp với giá trị status trong BookCopyModel)
  static const _copyStatuses = [
    'available',
    'borrowed',
    'reserved',
  ];

  static const _copyStatusLabels = {
    'available':   'Доступный',
    'borrowed':    'Заимствованный',
    'reserved':    'Зарезервированное место',
  };

  late String _selectedCopyStatus;

  // ── Tracking update progress (Book + mỗi BookCopy) ────────────────────────
  bool _bookUpdateDone  = false;
  int  _copyDoneCount   = 0;   // đếm số copy đã update xong

  // ──────────────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    final b = widget.book;

    _titleCtrl    = TextEditingController(text: b.title);
    _isbnCtrl     = TextEditingController(text: b.isbn);
    _languageCtrl = TextEditingController(text: b.language);
    _yearCtrl     = TextEditingController(text: b.publish_year.toString());
    _descCtrl     = TextEditingController(text: b.description);
    _quantityCtrl = TextEditingController(text: widget.copies.length.toString());
    // Lấy status từ bản sao đầu tiên; fallback về 'available' nếu không hợp lệ
    final firstStatus = widget.copies.isNotEmpty
        ? widget.copies.first.status ?? 'available'
        : 'available';
    _selectedCopyStatus = _copyStatuses.contains(firstStatus)
        ? firstStatus
        : 'available';

    // ── Lấy tên tác giả qua BLoC ──────────────────────────────────────────
    context.read<AuthorBloc>().add(
      GetAuthorByIdBookEvent(id_author: b.id_author),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _isbnCtrl.dispose();
    _languageCtrl.dispose();
    _yearCtrl.dispose();
    _descCtrl.dispose();
    _quantityCtrl.dispose();
    super.dispose();
  }

  // ── Dispatch UpdateBookEvent + UpdateBookCopyEvent ────────────────────────
  void _dispatchUpdate() {
    // Reset cờ
    setState(() {
      _bookUpdateDone = false;
      _copyDoneCount  = 0;
    });

    // 1. Cập nhật Book
    context.read<BookBloc>().add(
      UpdateBookEvent(
        id_book:      widget.book.id_book,
        id_category:  widget.book.id_category,
        id_author:    widget.book.id_author,
        title:        _titleCtrl.text.trim(),
        isbn:         _isbnCtrl.text.trim(),
        language:     _languageCtrl.text.trim(),
        publish_year: int.tryParse(_yearCtrl.text.trim()) ?? widget.book.publish_year,
        description:  _descCtrl.text.trim(),
        image_url:    widget.book.image_url,
        created_at:   widget.book.created_at,
      ),
    );

    // 2. Cập nhật status cho từng BookCopy
    for (final copy in widget.copies) {
      context.read<BookCopyBloc>().add(
        copy_event.UpdateBookCopyEvent(
          id_copy:       copy.id_copy!,
          id_book:       copy.id_book,
          barcode:       copy.barcode,
          qr_code:       copy.qr_code,
          location:      copy.location,
          received_date: copy.received_date,
          condition:     copy.condition,
          status:        _selectedCopyStatus,
        ),
      );
    }
  }

  /// Pop về màn hình trước khi cả Book lẫn mọi BookCopy đều đã lưu xong
  void _checkAllDone() {
    final totalCopies = widget.copies.isEmpty ? 1 : widget.copies.length;
    final copyDone    = widget.copies.isEmpty ? true : _copyDoneCount >= totalCopies;
    if (_bookUpdateDone && copyDone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Обновление прошло успешно!'),
          backgroundColor: _orange,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  // ── Pick & upload image ───────────────────────────────────────────────────
  Future<void> _pickAndUploadImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;
    final file = File(picked.path);
    setState(() {
      _pickedImageFile = file;
      _imageUploading  = true;
    });
    context.read<BookBloc>().add(
      UploadImgBookSubmitted(
        id_book:   widget.book.id_book,
        imageFile: file,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
        listeners: [
          // Lắng nghe kết quả upload ảnh + update sách từ BookBloc
          BlocListener<BookBloc, BookState>(
            listener: (context, state) {
              if (state is ImgBookUploadSuccess) {
                setState(() => _imageUploading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ảnh đã được cập nhật!'),
                    backgroundColor: _orange,
                  ),
                );
              }
              if (state is BookUpdatedSuccess) {
                setState(() => _bookUpdateDone = true);
                _checkAllDone();
              }
              if (state is BookError) {
                setState(() => _imageUploading = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ошибка: ${state.message}'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
          ),
        ],
        child: BlocListener<BookCopyBloc, copy_state.BookCopyState>(
          // ── Lắng nghe BookCopyBloc ──────────────────────────────────────────
          listener: (context, copyState) {
            if (copyState is copy_state.BookCopyUpdatedSuccess) {
              setState(() => _copyDoneCount++);
              _checkAllDone();
            }
            if (copyState is copy_state.BookCopyError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка экземпляра: ${copyState.message}'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          // child: BlocConsumer<BookBloc, BookState>(
          //   // ── Lắng nghe BookBloc ────────────────────────────────────────────
          //   listener: (context, state) {
          //     if (state is AuthorLoadedState) {
          //       setState(() {
          //         _authorName    = state.author.full_name;
          //         _authorLoading = false;
          //       });
          //     }
          //     if (state is BookUpdatedSuccess) {
          //       setState(() => _bookUpdateDone = true);
          //       _checkAllDone();
          //     }
          //     if (state is BookError) {
          //       setState(() => _authorLoading = false);
          //       ScaffoldMessenger.of(context).showSnackBar(
          //         SnackBar(
          //           content: Text('Ошибка: ${state.message}'),
          //           backgroundColor: Colors.redAccent,
          //         ),
          //       );
          //     }
          //   },
          child: BlocConsumer<AuthorBloc, AuthorState>
            (listener: (context,state){
            if(state is AuthorLoadedState){
              setState(() {
                _authorName = state.author.full_name;
                _authorLoading = false;
              });
            }
          },
            // ── UI ─────────────────────────────────────────────────────────────
            builder: (context, state) {
              final isSaving = state is BookLoading;

              return Scaffold(
                backgroundColor: _bg,
                appBar: _buildAppBar(isSaving),
                body: SingleChildScrollView(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCoverRow(),
                      const SizedBox(height: 24),

                      _FieldLabel('Название книги:'),
                      _EditField(controller: _titleCtrl, hint: 'Введите название книги'),
                      const SizedBox(height: 14),

                      _FieldLabel('Автор:'),
                      _authorLoading
                          ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: LinearProgressIndicator(color: _orange),
                      )
                          : _EditField(
                        controller: TextEditingController(text: _authorName ?? '—'),
                        hint: 'Автор',
                        readOnly: true,
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel('ISBN:'),
                      _EditField(controller: _isbnCtrl, hint: 'Импорт ISBN'),
                      const SizedBox(height: 14),

                      _FieldLabel('Язык:'),
                      _EditField(controller: _languageCtrl, hint: 'Язык'),
                      const SizedBox(height: 14),

                      _FieldLabel('Год публикации:'),
                      _EditField(
                        controller: _yearCtrl,
                        hint: 'Год',
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel('Количество экземпляров:'),
                      _EditField(
                        controller: _quantityCtrl,
                        hint: '0',
                        keyboardType: TextInputType.number,
                        readOnly: true,
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel('Статус:'),
                      _StatusDropdown(
                        value:     _selectedCopyStatus,
                        items:     _copyStatuses,
                        labels:    _copyStatusLabels,
                        onChanged: (v) => setState(
                                () => _selectedCopyStatus = v ?? 'available'),
                      ),
                      const SizedBox(height: 14),

                      _FieldLabel('Описывать:'),
                      _EditField(
                        controller: _descCtrl,
                        hint: 'Введите описание книги…',
                        maxLines: 5,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          ), // BlocConsumer
        )  // BlocListener
    );   // MultiBlocListener
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(bool isSaving) => AppBar(
    backgroundColor: _bg,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: _brown),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Отредактируйте книгу',
      style: TextStyle(
          color: _brown, fontWeight: FontWeight.bold, fontSize: 17),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 10),
        child: isSaving
            ? const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                color: _orange, strokeWidth: 2.5),
          ),
        )
            : TextButton(
          style: TextButton.styleFrom(
            backgroundColor: _orange,
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 8),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _dispatchUpdate,
          child: const Text(
            'Сохранять',
            style: TextStyle(
                color: _white,
                fontWeight: FontWeight.bold,
                fontSize: 14),
          ),
        ),
      ),
    ],
  );

  // ── Cover row ──────────────────────────────────────────────────────────────
  Widget _buildCoverRow() => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 110,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xff2B4A6A),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _pickedImageFile != null
              ? Image.file(_pickedImageFile!, fit: BoxFit.cover)
              : widget.book.image_url.isNotEmpty
              ? Image.network(
            "${ApiService.baseUrl}${widget.book.image_url}",
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Center(
              child: Icon(Icons.menu_book, color: Colors.white54, size: 36),
            ),
          )
              : const Center(
            child: Icon(Icons.menu_book, color: Colors.white54, size: 36),
          ),
        ),
      ),
      const SizedBox(width: 16),
      OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: _orange),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 10),
        ),
        onPressed: _imageUploading ? null : _pickAndUploadImage,
        icon: _imageUploading
            ? const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _orange),
        )
            : const Icon(Icons.upload_file, color: _orange, size: 18),
        label: Text(
          _imageUploading ? 'Загрузка…' : 'Импорт изображения',
          style: const TextStyle(color: _orange, fontSize: 13),
        ),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600, fontSize: 14, color: _brown)),
  );
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool readOnly;
  final TextInputType? keyboardType;

  const _EditField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.readOnly = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2)),
      ],
    ),
    child: TextField(
      controller:   controller,
      maxLines:     maxLines,
      readOnly:     readOnly,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText:  hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: InputBorder.none,
        suffixIcon: readOnly
            ? null
            : const Icon(Icons.edit, color: _orange, size: 18),
      ),
    ),
  );
}

class _StatusDropdown extends StatelessWidget {
  final String value;
  final List<String> items;
  final Map<String, String> labels; // value → label hiển thị
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: _white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2)),
      ],
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value:      value,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down, color: _orange),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        items: items
            .map((s) => DropdownMenuItem(
          value: s,
          child: Text(labels[s] ?? s),
        ))
            .toList(),
        onChanged: onChanged,
      ),
    ),
  );
}