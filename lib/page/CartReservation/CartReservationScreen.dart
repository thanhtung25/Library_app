import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/localization/app_localizations.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/bloc/reservation/state.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/reservations_model.dart';
import 'package:library_app/model/user_model.dart';

import '../../api_localhost/ApiService.dart';
import '../../bloc/loan/bloc.dart';
import '../../bloc/loan/event.dart';
import '../../model/loan_model.dart';
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

    ///_submitLoans();
  }
  //
  // Future<void> _submitLoans() async {
  //   setState(() => isSubmitting = true);
  //   try {
  //     final loanBloc = context.read<LoanBloc>();
  //     for (final reservation in currentReservations) {
  //       loanBloc.add(
  //         CreateLoanEvent(
  //           LoanModel(
  //             id_reservation: reservation.id_reservation,
  //             delivery_method: deliveryMethod,
  //             address: deliveryMethod == 'delivery'
  //                 ? _addressCtrl.text.trim()
  //                 : null,
  //             phone: deliveryMethod == 'delivery'
  //                 ? _phoneCtrl.text.trim()
  //                 : null,
  //             pickup_date: deliveryMethod == 'pickup' ? selectedDate : null,
  //             pickup_time: deliveryMethod == 'pickup' ? selectedTime : null,
  //             note: _noteCtrl.text.trim(),
  //           ),
  //         ),
  //       );
  //     }
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(context.tr('cart.success'))),
  //     );
  //     Navigator.pop(context, true);
  //   } catch (e) {
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           context.tr('cart.submit_error', params: {'error': '$e'}),
  //         ),
  //       ),
  //     );
  //   } finally {
  //     if (mounted) setState(() => isSubmitting = false);
  //   }
  // }

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
                      child: Text(state.error, textAlign: TextAlign.center),
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
                .read<BookBloc>()
                .bookservice
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