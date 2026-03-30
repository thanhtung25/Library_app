import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/author/bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/localization/app_localizations.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/bloc/reservation/state.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/reservations_model.dart';
import 'package:library_app/model/user_model.dart';

import '../../../api_localhost/ApiService.dart';
import '../../../api_localhost/BookCopyService.dart';
import '../../../api_localhost/LoanService.dart';
import '../../../model/book_copy_model.dart';
import '../../../model/loan_model.dart';
import 'cart_helpers.dart';
import 'widgets/cart_book_card.dart';
import 'widgets/cart_summary.dart';
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
  // ── Services ──────────────────────────────────────────
  final _bookCopyService = BookCopyService();
  final _loanService = LoanService();

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
    setState(() {
      isLoadingBooks = true;
      reservedBooks = [];
    });
    try {
      final bookBloc = context.read<BookBloc>();
      final valid = reservations.where((r) => r.id_book != null).toList();
      final results = await Future.wait(
        valid.map((r) async {
          try {
            return await bookBloc.bookservice.getBookById(r.id_book!);
          } catch (_) {
            return null;
          }
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
        SnackBar(
          content: Text(
            context.tr('cart.load_books_error', params: {'error': '$e'}),
          ),
        ),
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
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('cart.delete_title')),
        content: Text(
          context.tr('cart.delete_confirm', params: {'title': book.title}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(context.tr('cart.no')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFF9E74),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(context.tr('cart.yes')),
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
        SnackBar(content: Text(context.tr('cart.delete_failed'))),
      );
    }
  }

  void _confirmReservation() {
    if (reservedBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cart.empty'))),
      );
      return;
    }

    if (deliveryMethod == 'delivery') {
      if (_addressCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('cart.fill_delivery_info'))),
        );
        return;
      }
      if (!_shippingPaid) {
        _showShippingDialog();
        return;
      }
    }

    if (deliveryMethod == 'pickup' && selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cart.select_pickup_date'))),
      );
      return;
    }

    _submitLoans();
  }
  Future<void> _submitLoans() async {
    setState(() => isSubmitting = true);

    final now = DateTime.now();
    final returnDate = now.add(const Duration(days: 14));

    try {
      for (final reservation in List<ReservationModel>.from(currentReservations)) {
        if (reservation.id_book == null) continue;

        // 1. Lấy danh sách bản sao của sách
        final List<BookCopyModel> copies =
        await _bookCopyService.getBookCopyByIdBook(reservation.id_book!);

        // 2. Tìm bản sao 'available'
        final available = copies.where((c) => c.status == 'available').toList();
        if (available.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không còn bản sao sẵn sàng cho một trong các sách'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() => isSubmitting = false);
          return;
        }

        final BookCopyModel copy = available.first;

        // 3. Tạo loan (mượn sách)
        await _loanService.addLoan(LoanModel(
          id_user: widget.userModel.id_user,
          id_copy: copy.id_copy!,
          issue_date: selectedDate,
          return_date: returnDate,
          status: 'reserved',
        ));

        // 4. Cập nhật trạng thái bản sao → 'borrowed'
        await _bookCopyService.updateBookCopy(
          copy.copyWith(status: 'reserved'),
        );

        // 5. Xóa reservation khỏi rổ
        if (reservation.id_reservation != null && mounted) {
          context.read<ReservationBloc>().add(
            DeleteReservationEvent(reservation.id_reservation!),
          );
        }
      }

      if (!mounted) return;
      setState(() => isSubmitting = false);

      // ── Dialog thành công ──────────────────────────────
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Thành công!'),
            ],
          ),
          content: Text(
            deliveryMethod == 'pickup'
                ? 'Đã đăng ký mượn sách thành công.\n'
                'Vui lòng đến thư viện vào '
                '${formatPickupDate(selectedDate)} lúc $selectedTime.'
                : 'Đã đặt và thanh toán thành công.\n'
                'Sách sẽ được giao đến địa chỉ bạn đã cung cấp.',
            style: const TextStyle(fontSize: 15, height: 1.5),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // đóng dialog
                Navigator.pop(context); // quay lại màn hình trước
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffFF9E74),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      context.tr('cart.title'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E8),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 42,
                                color: Colors.orange.shade400,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Корзина пуста',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF3D2314),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'У вас пока нет забронированных книг.\nДобавьте книги в корзину, чтобы они появились здесь.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9E74).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                '📚 Перейдите в каталог и выберите книгу',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF9E74),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (state is ReservationLoaded &&
                      state.reservations.isEmpty &&
                      !isLoadingBooks) {
                    return Center(
                      child: Text(
                        context.tr('cart.empty'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  // ── Content ───────────────────────────────────────────
  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        // ── Book list ──
        ...reservedBooks.map((book) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: CartBookCard(
            title: book.title,
            imagePath: '${ApiService.baseUrl}${book.image_url}',
            selected: true,
            onSelect: () {},
            onDelete: () => _deleteReservationByBook(book),
            authorFuture: context
                .read<AuthorBloc>()
                .authorservice
                .getAuthorByID(book.id_author),
          ),
        )),

        const SizedBox(height: 18),

        // ── Delivery method ──
        Text(
          context.tr('cart.method_title'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        DeliveryMethodCard(
          title: context.tr('cart.delivery_title'),
          subtitle: context.tr('cart.delivery_subtitle'),
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
          title: context.tr('cart.pickup_title'),
          subtitle: context.tr('cart.pickup_subtitle'),
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
          Text(
            context.tr('cart.delivery_info'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          CartTextField(
            controller: _addressCtrl,
            hintText: context.tr('cart.delivery_address'),
            icon: Icons.home_outlined,
          ),
          const SizedBox(height: 12),
          CartTextField(
            controller: _phoneCtrl,
            hintText: context.tr('cart.delivery_phone'),
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
        ],

        // ── Pickup fields ──
        if (deliveryMethod == 'pickup') ...[
          Text(
            context.tr('cart.pickup_info'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          // Date picker
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    formatPickupDate(selectedDate),
                    style: TextStyle(
                      fontSize: 15,
                      color: selectedDate == null
                          ? Colors.grey.shade500
                          : Colors.black87,
                    ),
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
                  DropdownMenuItem(
                      value: '10:00 - 12:00', child: Text('10:00 - 12:00')),
                  DropdownMenuItem(
                      value: '12:00 - 14:00', child: Text('12:00 - 14:00')),
                  DropdownMenuItem(
                      value: '14:00 - 16:00', child: Text('14:00 - 16:00')),
                  DropdownMenuItem(
                      value: '16:00 - 18:00', child: Text('16:00 - 18:00')),
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
        Text(
          context.tr('cart.comment'),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        CartTextField(
          controller: _noteCtrl,
          hintText: context.tr('cart.comment_hint'),
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
            onPressed: isSubmitting ? null : _confirmReservation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffFF9E74),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: isSubmitting
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
                : Text(
              context.tr('cart.confirm_button'),
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}