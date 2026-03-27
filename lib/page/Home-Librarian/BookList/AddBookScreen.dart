import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/book/bloc.dart';
import '../../../bloc/book/event.dart';
import '../../../bloc/book/state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Palette (nhất quán với toàn app)
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

  // ── Controllers ────────────────────────────────────────────────────────────
  final _titleCtrl       = TextEditingController();
  final _isbnCtrl        = TextEditingController();
  final _languageCtrl    = TextEditingController();
  final _yearCtrl        = TextEditingController();
  final _descCtrl        = TextEditingController();
  final _imageUrlCtrl    = TextEditingController();
  final _idCategoryCtrl  = TextEditingController();
  final _idAuthorCtrl    = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _isbnCtrl.dispose();
    _languageCtrl.dispose();
    _yearCtrl.dispose();
    _descCtrl.dispose();
    _imageUrlCtrl.dispose();
    _idCategoryCtrl.dispose();
    _idAuthorCtrl.dispose();
    super.dispose();
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<BookBloc>().add(
      CreateBookEvent(
        id_category:  int.parse(_idCategoryCtrl.text.trim()),
        id_author:    int.parse(_idAuthorCtrl.text.trim()),
        title:        _titleCtrl.text.trim(),
        isbn:         _isbnCtrl.text.trim(),
        language:     _languageCtrl.text.trim(),
        publish_year: int.tryParse(_yearCtrl.text.trim()) ?? 0,
        description:  _descCtrl.text.trim(),
        image_url:    _imageUrlCtrl.text.trim(),
        created_at:   DateTime.now(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookBloc, BookState>(
      listener: (context, state) {
        if (state is BookCreatedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm sách thành công!'),
              backgroundColor: _orange,
            ),
          );
          Navigator.pop(context, true);
        }
        if (state is BookError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${state.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is BookLoading;

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
                  // ── Cover placeholder + image url ────────────────────────
                  _buildCoverSection(),
                  const SizedBox(height: 24),

                  // ── Section: Thông tin sách ──────────────────────────────
                  _SectionHeader(
                    icon: Icons.menu_book_rounded,
                    label: 'Thông tin sách',
                  ),
                  const SizedBox(height: 12),
                  _buildCard([
                    _FormField(
                      controller: _titleCtrl,
                      label: 'Tên sách',
                      hint: 'Nhập tên sách',
                      icon: Icons.title,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Vui lòng nhập tên sách' : null,
                    ),
                    _dividerLine(),
                    _FormField(
                      controller: _isbnCtrl,
                      label: 'ISBN',
                      hint: 'Nhập mã ISBN',
                      icon: Icons.qr_code,
                      validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Vui lòng nhập ISBN' : null,
                    ),
                    _dividerLine(),
                    _FormField(
                      controller: _languageCtrl,
                      label: 'Ngôn ngữ',
                      hint: 'Ví dụ: Tiếng Việt',
                      icon: Icons.translate,
                    ),
                    _dividerLine(),
                    _FormField(
                      controller: _yearCtrl,
                      label: 'Năm xuất bản',
                      hint: 'Ví dụ: 2023',
                      icon: Icons.calendar_today,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nhập năm xuất bản';
                        if (int.tryParse(v.trim()) == null) return 'Năm không hợp lệ';
                        return null;
                      },
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Section: Phân loại ───────────────────────────────────
                  _SectionHeader(
                    icon: Icons.category_rounded,
                    label: 'Phân loại',
                  ),
                  const SizedBox(height: 12),
                  _buildCard([
                    _FormField(
                      controller: _idCategoryCtrl,
                      label: 'ID Thể loại',
                      hint: 'Nhập ID thể loại',
                      icon: Icons.category,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nhập ID thể loại';
                        if (int.tryParse(v.trim()) == null) return 'ID không hợp lệ';
                        return null;
                      },
                    ),
                    _dividerLine(),
                    _FormField(
                      controller: _idAuthorCtrl,
                      label: 'ID Tác giả',
                      hint: 'Nhập ID tác giả',
                      icon: Icons.person,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Nhập ID tác giả';
                        if (int.tryParse(v.trim()) == null) return 'ID không hợp lệ';
                        return null;
                      },
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Section: Mô tả ───────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.description_rounded,
                    label: 'Mô tả',
                  ),
                  const SizedBox(height: 12),
                  _buildCard([
                    _FormField(
                      controller: _descCtrl,
                      label: 'Mô tả sách',
                      hint: 'Nhập mô tả nội dung sách…',
                      icon: Icons.notes,
                      maxLines: 4,
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Submit button ────────────────────────────────────────
                  _SubmitButton(
                    label: 'Thêm sách',
                    isLoading: isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────
  AppBar _buildAppBar(bool isLoading) => AppBar(
    backgroundColor: _bg,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: _brown),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Thêm sách mới',
      style: TextStyle(
          color: _brown, fontWeight: FontWeight.bold, fontSize: 17),
    ),
  );

  // ── Cover section ──────────────────────────────────────────────────────────
  Widget _buildCoverSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Cover preview
        Container(
          width: 100,
          height: 138,
          decoration: BoxDecoration(
            color: _orange.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _orange.withOpacity(0.5), width: 1.5),
          ),
          child: ValueListenableBuilder(
            valueListenable: _imageUrlCtrl,
            builder: (_, v, __) {
              final url = v.text.trim();
              return ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: url.isNotEmpty
                    ? Image.network(url, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _coverPlaceholder())
                    : _coverPlaceholder(),
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('URL ảnh bìa',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _brown)),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: TextFormField(
                  controller: _imageUrlCtrl,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                  decoration: const InputDecoration(
                    hintText: 'https://...',
                    hintStyle:
                    TextStyle(color: Colors.black38, fontSize: 13),
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: InputBorder.none,
                    suffixIcon:
                    Icon(Icons.link, color: _orange, size: 18),
                  ),
                ),
              ),
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
      Text('Ảnh bìa',
          style: TextStyle(
              fontSize: 11,
              color: _orange.withOpacity(0.7))),
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
//  Shared helper widgets  (dùng lại ở AddBookCopyScreen)
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
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _brown)),
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
        crossAxisAlignment: maxLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 14 : 0),
            child: Icon(icon, color: _orange, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller:   controller,
              maxLines:     maxLines,
              readOnly:     readOnly,
              keyboardType: keyboardType,
              validator:    validator,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
              decoration: InputDecoration(
                labelText:  label,
                labelStyle: const TextStyle(
                    fontSize: 12, color: Colors.black45),
                hintText:  hint,
                hintStyle: const TextStyle(
                    color: Colors.black26, fontSize: 13),
                border:        InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12),
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
      {required this.label,
        required this.isLoading,
        required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _orange,
        elevation: 2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
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
          const Icon(Icons.add_circle_outline,
              color: _white, size: 20),
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