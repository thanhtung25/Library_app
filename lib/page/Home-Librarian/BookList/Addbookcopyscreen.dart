import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../bloc/book_copy/bloc.dart';
import '../../../bloc/book_copy/event.dart';
import '../../../bloc/book_copy/state.dart';

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
//  Status & Condition maps
// ─────────────────────────────────────────────────────────────────────────────
const _copyStatuses = ['available', 'borrowed', 'lost', 'maintenance'];
const _copyStatusLabels = {
  'available':   'Доступен',
  'borrowed':    'Выдан',
  'lost':        'Утерян',
  'maintenance': 'На обслуживании',
};

const _conditions = ['new', 'good', 'fair', 'poor'];
const _conditionLabels = {
  'new':  'Новый',
  'good': 'Хорошее',
  'fair': 'Среднее',
  'poor': 'Изношенный',
};

// ─────────────────────────────────────────────────────────────────────────────
//  AddBookCopyScreen
// ─────────────────────────────────────────────────────────────────────────────
class AddBookCopyScreen extends StatefulWidget {
  final int idBook;
  const AddBookCopyScreen({super.key, required this.idBook});

  @override
  State<AddBookCopyScreen> createState() => _AddBookCopyScreenState();
}

class _AddBookCopyScreenState extends State<AddBookCopyScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ────────────────────────────────────────────────────────────
  final _barcodeCtrl  = TextEditingController();
  final _qrCtrl       = TextEditingController();
  final _locationCtrl = TextEditingController();

  // ── Dropdowns ──────────────────────────────────────────────────────────────
  String _selectedStatus    = 'available';
  String _selectedCondition = 'new';

  // ── Date picker ────────────────────────────────────────────────────────────
  DateTime? _receivedDate;

  @override
  void dispose() {
    _barcodeCtrl.dispose();
    _qrCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ── Date picker ────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context:     context,
      initialDate: _receivedDate ?? DateTime.now(),
      firstDate:   DateTime(2000),
      lastDate:    DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: _orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _receivedDate = picked);
  }

  // ── Submit ──────────────────────────────────────────────────────────────────
  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_receivedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Пожалуйста, выберите дату получения'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    context.read<BookCopyBloc>().add(
      AddBookCopyEvent(
        id_book:       widget.idBook,
        barcode:       _barcodeCtrl.text.trim(),
        qr_code:       _qrCtrl.text.trim(),
        location:      _locationCtrl.text.trim(),
        received_date: _receivedDate!,
        condition:     _selectedCondition,
        status:        _selectedStatus,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BookCopyBloc, BookCopyState>(
      listener: (context, state) {
        if (state is BookCopyAddedSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Экземпляр успешно добавлен!'),
              backgroundColor: _orange,
            ),
          );
          Navigator.pop(context, true);
        }
        if (state is BookCopyError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка: ${state.message}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is BookCopyLoading;

        return Scaffold(
          backgroundColor: _bg,
          appBar: _buildAppBar(),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── ID Book badge ────────────────────────────────────────
                  _IdBookBadge(idBook: widget.idBook),
                  const SizedBox(height: 20),

                  // ── Section: Идентификаторы ──────────────────────────────
                  _SectionHeader(
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Идентификаторы'),
                  const SizedBox(height: 12),
                  _buildCard([
                    _FormField(
                      controller: _barcodeCtrl,
                      label: 'Штрих-код',
                      hint:  'Введите штрих-код',
                      icon:  Icons.barcode_reader,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Введите штрих-код'
                          : null,
                    ),
                    _dividerLine(),
                    _FormField(
                      controller: _qrCtrl,
                      label: 'QR-код',
                      hint:  'Введите QR-код',
                      icon:  Icons.qr_code_2,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Введите QR-код'
                          : null,
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Section: Расположение и дата получения ───────────────
                  _SectionHeader(
                      icon: Icons.location_on_rounded,
                      label: 'Расположение и дата получения'),
                  const SizedBox(height: 12),
                  _buildCard([
                    _FormField(
                      controller: _locationCtrl,
                      label: 'Место на полке',
                      hint:  'Например: Полка A - Этаж 2',
                      icon:  Icons.shelves,
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Введите место на полке'
                          : null,
                    ),
                    _dividerLine(),
                    // Date picker row
                    InkWell(
                      onTap: _pickDate,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month,
                                color: _orange, size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Дата получения',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _receivedDate != null
                                        ? '${_receivedDate!.day.toString().padLeft(2, '0')}'
                                        '.${_receivedDate!.month.toString().padLeft(2, '0')}'
                                        '.${_receivedDate!.year}'
                                        : 'Выберите дату',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _receivedDate != null
                                          ? Colors.black87
                                          : Colors.black38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right,
                                color: Colors.black26, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ]),

                  const SizedBox(height: 20),

                  // ── Section: Состояние и статус ──────────────────────────
                  _SectionHeader(
                      icon: Icons.tune_rounded,
                      label: 'Состояние и статус'),
                  const SizedBox(height: 12),
                  _buildCard([
                    _DropdownRow(
                      icon:      Icons.star_outline_rounded,
                      label:     'Состояние',
                      value:     _selectedCondition,
                      items:     _conditions,
                      labels:    _conditionLabels,
                      onChanged: (v) =>
                          setState(() => _selectedCondition = v ?? 'new'),
                    ),
                    _dividerLine(),
                    _DropdownRow(
                      icon:      Icons.info_outline_rounded,
                      label:     'Статус',
                      value:     _selectedStatus,
                      items:     _copyStatuses,
                      labels:    _copyStatusLabels,
                      onChanged: (v) =>
                          setState(() => _selectedStatus = v ?? 'available'),
                    ),
                  ]),

                  const SizedBox(height: 28),

                  // ── Submit ───────────────────────────────────────────────
                  _SubmitButton(
                    label:     'Добавить экземпляр',
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

  AppBar _buildAppBar() => AppBar(
    backgroundColor: _bg,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: _brown),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      'Добавить экземпляр',
      style: TextStyle(
          color: _brown, fontWeight: FontWeight.bold, fontSize: 17),
    ),
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
//  Widgets dùng riêng cho AddBookCopyScreen
// ─────────────────────────────────────────────────────────────────────────────

class _IdBookBadge extends StatelessWidget {
  final int idBook;
  const _IdBookBadge({required this.idBook});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color:        _orange.withOpacity(0.13),
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: _orange.withOpacity(0.35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.menu_book_rounded, color: _orange, size: 18),
        const SizedBox(width: 8),
        Text(
          'Книга #$idBook',
          style: const TextStyle(
              color: _brown, fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ],
    ),
  );
}

class _DropdownRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> items;
  final Map<String, String> labels;
  final ValueChanged<String?> onChanged;

  const _DropdownRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.items,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        Icon(icon, color: _orange, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: InputDecoration(
              labelText:      label,
              labelStyle:     const TextStyle(fontSize: 12, color: Colors.black45),
              border:         InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: _orange, size: 20),
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
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared helper widgets
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
          color:        _orange.withOpacity(0.15),
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
    this.maxLines    = 1,
    this.readOnly    = false,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Padding(
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
              labelText:      label,
              labelStyle:     const TextStyle(fontSize: 12, color: Colors.black45),
              hintText:       hint,
              hintStyle:      const TextStyle(color: Colors.black26, fontSize: 13),
              border:         InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              errorStyle:     const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onPressed;
  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width:  double.infinity,
    height: 52,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _orange,
        elevation:       2,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
          width:  22,
          height: 22,
          child:  CircularProgressIndicator(
              color: _white, strokeWidth: 2.5))
          : Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_circle_outline,
              color: _white, size: 20),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color:      _white,
                  fontWeight: FontWeight.bold,
                  fontSize:   15)),
        ],
      ),
    ),
  );
}
