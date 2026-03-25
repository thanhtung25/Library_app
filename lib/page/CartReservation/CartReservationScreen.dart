import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/bloc/reservation/state.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/reservations_model.dart';
import 'package:library_app/model/user_model.dart';
import 'package:library_app/page/CartReservation/widgets/cart_summary.dart';

import '../../api_localhost/ApiService.dart';
import '../../bloc/loan/bloc.dart';
import '../../bloc/loan/event.dart';
import '../../model/loan_model.dart';
import 'cart_helpers.dart';
import 'widgets/cart_book_card.dart';
import 'widgets/delivery_method_card.dart';
import 'widgets/shipping_payment_dialog.dart';

class CartReservationScreen extends StatefulWidget {
  final UserModel userModel;
  const CartReservationScreen({super.key, required this.userModel});

  @override
  State<CartReservationScreen> createState() => _CartReservationScreenState();
}

class _CartReservationScreenState extends State<CartReservationScreen> {
  // ── State ─────────────────────────────────────────────
  String deliveryMethod = 'pickup';
  bool _shippingPaid = false;

  static const double _shippingFee = 300;

  final _addressCtrl = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _noteCtrl    = TextEditingController();

  DateTime? selectedDate;
  String selectedTime = '14:00 - 16:00';

  List<BookModel> reservedBooks = [];
  List<ReservationModel> currentReservations = [];
  bool isLoadingBooks = false;
  bool _booksLoadedOnce = false;

  bool isSubmitting = false;

  // ── Lifecycle ─────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  // ── Data helpers ──────────────────────────────────────
  void _loadReservations() {
    context.read<ReservationBloc>().add(
      GetReservationsByUserEvent(widget.userModel.id_user),
    );
  }

  Future<void> _loadReservedBooks(List<ReservationModel> reservations) async {
    setState(() { isLoadingBooks = true; reservedBooks = []; });
    try {
      final bookBloc = context.read<BookBloc>();
      final valid = reservations.where((r) => r.id_book != null).toList();
      final results = await Future.wait(
        valid.map((r) async {
          try { return await bookBloc.bookservice.getBookById(r.id_book!); }
          catch (_) { return null; }
        }),
      );
      if (!mounted) return;
      setState(() {
        currentReservations = reservations;
        reservedBooks = results.whereType<BookModel>().toList();
        isLoadingBooks = false;
        _booksLoadedOnce = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoadingBooks = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải danh sách sách: $e')),
      );
    }
  }

  // ── Actions ───────────────────────────────────────────
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (result != null) setState(() => selectedDate = result);
  }

  Future<void> _deleteReservationByBook(BookModel book) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Подтверждение'),
        content: Text(
          'Вы уверены, что хотите удалить "${book.title ?? 'эту книгу'}" из корзины?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Нет'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFF9E74),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Да'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final match = currentReservations.firstWhere(
            (r) => r.id_book == book.id_book,
      );
      context.read<ReservationBloc>().add(
        DeleteReservationEvent(match.id_reservation!),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось удалить книгу из корзины')),
      );
    }
  }

  void _confirmReservation() {
    if (reservedBooks.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Корзина пуста')));
      return;
    }
    if (deliveryMethod == 'delivery') {
      if (_addressCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Заполните адрес и телефон для доставки'),
        ));
        return;
      }
      if (!_shippingPaid) { _showShippingDialog(); return; }
    }
    if (deliveryMethod == 'pickup' && selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Выберите дату получения')),
      );
      return;
    }

    _submitLoans();
  }
  Future<void> _submitLoans() async {
    setState(() => isSubmitting = true);

  }


  void _showShippingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ShippingPaymentDialog(
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        shippingFee: _shippingFee,
        formatCurrency: formatCurrency,
        onConfirm: () {
          setState(() => _shippingPaid = true);
          _confirmReservation();
        },
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCBEAF3),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Text('Корзина',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),

            Expanded(
              child: BlocConsumer<ReservationBloc, ReservationState>(
                listener: (context, state) {
                  if (state is ReservationLoaded) {
                    currentReservations = state.reservations;
                    if (!_booksLoadedOnce ||
                        reservedBooks.length != state.reservations.length) {
                      _loadReservedBooks(state.reservations);
                    }
                  }
                  if (state is ReservationDeleted) {
                    _booksLoadedOnce = false;
                    _loadReservations();
                  }
                  if (state is ReservationError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(state.error)),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is ReservationLoading && !_booksLoadedOnce) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is ReservationError && !_booksLoadedOnce) {
                    return Center(
                        child: Text(state.error, textAlign: TextAlign.center));
                  }
                  if (state is ReservationLoaded &&
                      state.reservations.isEmpty &&
                      !isLoadingBooks) {
                    return const Center(
                      child: Text('Корзина пуста',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                    );
                  }
                  if (isLoadingBooks) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  return _buildContent();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // ── Book list ──
        ...reservedBooks.map((book) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: CartBookCard(
            title: book.title ?? 'Без названия',
            imagePath: '${ApiService.baseUrl}${book.image_url}',
            selected: true,
            onSelect: () {},
            onDelete: () => _deleteReservationByBook(book),
            authorFuture: context
                .read<BookBloc>()
                .bookservice
                .getAuthorByID(book.id_author),
          ),
        )),

        const SizedBox(height: 18),

        // ── Delivery method ──
        const Text('Способ получения',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        DeliveryMethodCard(
          title: 'Доставка',
          subtitle: 'Получение книги по указанному адресу',
          icon: Icons.local_shipping_outlined,
          value: 'delivery',
          selectedValue: deliveryMethod,
          onChanged: (v) => setState(() {
            deliveryMethod = v;
            _shippingPaid = false;
          }),
        ),
        const SizedBox(height: 10),
        DeliveryMethodCard(
          title: 'Самовывоз из библиотеки',
          subtitle: 'Получение книги в библиотеке',
          icon: Icons.location_on_outlined,
          value: 'pickup',
          selectedValue: deliveryMethod,
          onChanged: (v) => setState(() {
            deliveryMethod = v;
            _shippingPaid = false;
          }),
        ),

        const SizedBox(height: 20),

        // ── Delivery fields ──
        if (deliveryMethod == 'delivery') ...[
          const Text('Данные для доставки',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          CartTextField(
            controller: _addressCtrl,
            hintText: 'Адрес доставки',
            icon: Icons.home_outlined,
          ),
          const SizedBox(height: 12),
          CartTextField(
            controller: _phoneCtrl,
            hintText: 'Контактный телефон',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],

        // ── Pickup fields ──
        if (deliveryMethod == 'pickup') ...[
          const Text('Данные для получения',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          // Date picker
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedDate == null
                        ? 'Выберите дату получения'
                        : formatPickupDate(selectedDate),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          // Time picker
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTime,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: const [
                  DropdownMenuItem(value: '10:00 - 12:00', child: Text('10:00 - 12:00')),
                  DropdownMenuItem(value: '12:00 - 14:00', child: Text('12:00 - 14:00')),
                  DropdownMenuItem(value: '14:00 - 16:00', child: Text('14:00 - 16:00')),
                  DropdownMenuItem(value: '16:00 - 18:00', child: Text('16:00 - 18:00')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => selectedTime = v);
                },
              ),
            ),
          ),
        ],

        const SizedBox(height: 20),

        // ── Note ──
        const Text('Комментарий',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        CartTextField(
          controller: _noteCtrl,
          hintText: 'Введите комментарий',
          icon: Icons.edit_note_outlined,
          maxLines: 3,
        ),

        const SizedBox(height: 20),

        // ── Summary ──
        CartSummary(
          bookCount: reservedBooks.length,
          deliveryMethod: deliveryMethod,
          pickupDate: formatPickupDate(selectedDate),
          pickupTime: selectedTime,
          shippingFee: _shippingFee,
          shippingPaid: _shippingPaid,
          formatCurrency: formatCurrency,
        ),

        const SizedBox(height: 28),

        // ── Confirm button ──
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _confirmReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFF9E74),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Подтвердить бронирование',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}