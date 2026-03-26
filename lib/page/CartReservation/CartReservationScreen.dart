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

class CartReservationScreen extends StatefulWidget {
  final UserModel userModel;

  const CartReservationScreen({
    super.key,
    required this.userModel,
  });

  @override
  State<CartReservationScreen> createState() => _CartReservationScreenState();
}

class _CartReservationScreenState extends State<CartReservationScreen> {
  String deliveryMethod = 'pickup';

  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  late Future<AuthorModel> futureAuthor;
  DateTime? selectedDate;
  String selectedTime = '14:00 - 16:00';

  List<BookModel> reservedBooks = [];
  List<ReservationModel> currentReservations = [];

  bool isLoadingBooks = false;
  bool isSubmitting = false;
  bool _booksLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  void _loadReservations() {
    context.read<ReservationBloc>().add(
      GetReservationsByUserEvent(widget.userModel.id_user),
    );
  }

  @override
  void dispose() {
    addressController.dispose();
    phoneController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  Future<void> _loadReservedBooks(List<ReservationModel> reservations) async {
    setState(() {
      isLoadingBooks = true;
      reservedBooks = [];
    });

    try {
      final bookBloc = context.read<BookBloc>();

      final validReservations = reservations
          .where((r) => r.id_book != null)
          .toList();

      final futures = validReservations.map((reservation) async {
        try {
          return await bookBloc.bookservice.getBookById(reservation.id_book!);
        } catch (_) {
          return null;
        }
      }).toList();

      final results = await Future.wait(futures);
      final books = results.whereType<BookModel>().toList();

      if (!mounted) return;

      setState(() {
        currentReservations = reservations;
        reservedBooks = books;
        isLoadingBooks = false;
        _booksLoadedOnce = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingBooks = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('cart.load_books_error', params: {'error': '$e'}),
          ),
        ),
      );
    }
  }

  Future<void> _deleteReservationByBook(BookModel book) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(context.tr('cart.delete_title')),
          content: Text(
            context.tr(
              'cart.delete_confirm',
              params: {'title': book.title},
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(context.tr('cart.no')),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
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
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      final matchedReservation = currentReservations.firstWhere(
            (r) => r.id_book == book.id_book,
      );

      context.read<ReservationBloc>().add(
        DeleteReservationEvent(matchedReservation.id_reservation!),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('cart.delete_failed')),
        ),
      );
    }
  }

  void _confirmReservation() {
    if (reservedBooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('cart.empty')),
        ),
      );
      return;
    }

    if (deliveryMethod == 'delivery') {
      if (addressController.text.trim().isEmpty ||
          phoneController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('cart.fill_delivery_info')),
          ),
        );
        return;
      }
    }

    if (deliveryMethod == 'pickup') {
      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('cart.select_pickup_date')),
          ),
        );
        return;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.tr('cart.success')),
      ),
    );
  }

  String _formatPickupDate() {
    if (selectedDate == null) return context.tr('cart.not_selected');
    return '${selectedDate!.day.toString().padLeft(2, '0')}.'
        '${selectedDate!.month.toString().padLeft(2, '0')}.'
        '${selectedDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFCBEAF3),
      body: SafeArea(
        child: Column(
          children: [
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
                      child: Text(
                        state.error,
                        textAlign: TextAlign.center,
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

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      if (reservedBooks.isNotEmpty) ...[
                        ...reservedBooks.map((book) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _buildBookCard(
                              title: book.title,
                              imagePath: "${ApiService.baseUrl}${book.image_url}" ?? '',
                              selected: true,
                              onSelect: () {},
                              onDelete: () => _deleteReservationByBook(book),
                              authorFuture: context.read<BookBloc>().bookservice.getAuthorByID(book.id_author),
                            ),
                          );
                        }),
                      ],

                      const SizedBox(height: 18),

                      Text(
                        context.tr('cart.method_title'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildMethodCard(
                        title: context.tr('cart.delivery_title'),
                        subtitle: context.tr('cart.delivery_subtitle'),
                        icon: Icons.local_shipping_outlined,
                        value: 'delivery',
                      ),
                      const SizedBox(height: 10),
                      _buildMethodCard(
                        title: context.tr('cart.pickup_title'),
                        subtitle: context.tr('cart.pickup_subtitle'),
                        icon: Icons.location_on_outlined,
                        value: 'pickup',
                      ),

                      const SizedBox(height: 20),

                      if (deliveryMethod == 'delivery') ...[
                        Text(
                          context.tr('cart.delivery_info'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: addressController,
                          hintText: context.tr('cart.delivery_address'),
                          icon: Icons.home_outlined,
                        ),
                        const SizedBox(height: 12),
                        _buildTextField(
                          controller: phoneController,
                          hintText: context.tr('cart.delivery_phone'),
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],

                      if (deliveryMethod == 'pickup') ...[
                        Text(
                          context.tr('cart.pickup_info'),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    selectedDate == null
                                        ? context.tr('cart.pickup_date_hint')
                                        : _formatPickupDate(),
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
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
                                  value: '10:00 - 12:00',
                                  child: Text('10:00 - 12:00'),
                                ),
                                DropdownMenuItem(
                                  value: '12:00 - 14:00',
                                  child: Text('12:00 - 14:00'),
                                ),
                                DropdownMenuItem(
                                  value: '14:00 - 16:00',
                                  child: Text('14:00 - 16:00'),
                                ),
                                DropdownMenuItem(
                                  value: '16:00 - 18:00',
                                  child: Text('16:00 - 18:00'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedTime = value;
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      Text(
                        context.tr('cart.comment'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: noteController,
                        hintText: context.tr('cart.comment_hint'),
                        icon: Icons.edit_note_outlined,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('cart.summary_title'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryRow(
                              context.tr('cart.summary_books'),
                              reservedBooks.length.toString(),
                            ),
                            _buildSummaryRow(
                              context.tr('cart.summary_method'),
                              deliveryMethod == 'delivery'
                                  ? context.tr('cart.method_delivery')
                                  : context.tr('cart.method_pickup'),
                            ),
                            if (deliveryMethod == 'pickup')
                              _buildSummaryRow(
                                context.tr('cart.summary_pickup_date'),
                                _formatPickupDate(),
                              ),
                            if (deliveryMethod == 'pickup')
                              _buildSummaryRow(
                                context.tr('cart.summary_time'),
                                selectedTime,
                              ),
                            _buildSummaryRow(
                              context.tr('cart.summary_duration'),
                              context.tr('cart.summary_duration_value'),
                            ),
                            _buildSummaryRow(
                              context.tr('cart.summary_status'),
                              context.tr('cart.summary_status_value'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

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
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            context.tr('cart.confirm_button'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookCard({
    required String title,
    required String imagePath,
    required bool selected,
    required VoidCallback onSelect,
    required VoidCallback onDelete,
    required Future<AuthorModel> authorFuture,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4F1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black26),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onSelect,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.4),
              ),
              child: selected
                  ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imagePath.startsWith('http')
                ? Image.network(
              imagePath,
              width: 46,
              height: 62,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 46,
                height: 62,
                color: Colors.grey.shade300,
                child: const Icon(Icons.book, size: 24),
              ),
            )
                : Image.asset(
              imagePath.isEmpty ? 'assets/images/book_placeholder.png' : imagePath,
              width: 46,
              height: 62,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 46,
                height: 62,
                color: Colors.grey.shade300,
                child: const Icon(Icons.book, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder(
                  future: authorFuture,
                  builder: (context, asyncSnapshot) {
                    if (asyncSnapshot.connectionState == ConnectionState.waiting) {
                      return Text(context.tr('common.loading'));
                    }

                    if (asyncSnapshot.hasError) {
                      return Text(context.tr('common.author_error'));
                    }

                    if (!asyncSnapshot.hasData) {
                      return Text(context.tr('common.author_unavailable'));
                    }
                    return Text(
                        asyncSnapshot.data!.full_name,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xffE5835E),
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('cart.book_duration'),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline,
              size: 24,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = deliveryMethod == value;

    return InkWell(
      onTap: () {
        setState(() {
          deliveryMethod = value;
        });
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1EA) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? const Color(0xffFF9E74) : Colors.black12,
            width: 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xffFF9E74) : Colors.black87,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xffFF9E74) : Colors.black54,
                  width: 1.4,
                ),
              ),
              child: isSelected
                  ? Center(
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffFF9E74),
                  ),
                ),
              )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: Color(0xffFF9E74),
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
