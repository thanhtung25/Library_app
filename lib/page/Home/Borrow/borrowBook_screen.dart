import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/localization/app_localizations.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/bloc/reservation/state.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/reservations_model.dart';
import 'package:library_app/model/user_model.dart';

class BorrowbookScreen extends StatefulWidget {
  final UserModel user;
  const BorrowbookScreen({super.key, required this.user});

  @override
  State<BorrowbookScreen> createState() => _BorrowbookScreenState();
}

enum _SortField { name, returnDate }
enum _SortDir   { asc, desc }

class _BorrowbookScreenState extends State<BorrowbookScreen> {
  static const Color _orange   = Color(0xffFF9E74);
  static const Color _bg       = Color(0xffF8EDE3);
  static const Color _textDark = Color(0xff3D2314);

  _SortField _sortField = _SortField.returnDate;
  _SortDir   _sortDir   = _SortDir.asc;

  @override
  void initState() {
    super.initState();
    context.read<ReservationBloc>().add(
      GetReservationsByUserEvent(widget.user.id_user),
    );
    context.read<BookBloc>().add(GetBookEvent());
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2,'0')}'
        '.${dt.month.toString().padLeft(2,'0')}'
        '.${dt.year}';
  }

  bool _isOverdue(ReservationModel r) =>
      r.expiration_date != null &&
          r.expiration_date!.isBefore(DateTime.now()) &&
          r.status.toLowerCase() != 'returned';

  Color _rowBg(ReservationModel r) {
    if (_isOverdue(r))                            return const Color(0xffFFE5E5);
    switch (r.status.toLowerCase()) {
      case 'approved': return const Color(0xffE8F8EC);
      case 'returned': return const Color(0xffF5F5F5);
      default:         return const Color(0xffFFF6EC);  // pending
    }
  }

  Color _badgeColor(ReservationModel r) {
    if (_isOverdue(r))                            return Colors.red.shade700;
    switch (r.status.toLowerCase()) {
      case 'approved': return Colors.green.shade700;
      case 'returned': return Colors.grey.shade600;
      default:         return Colors.orange.shade800;
    }
  }

  String _badgeLabel(ReservationModel r) {
    if (_isOverdue(r))                            return context.tr('borrowed.status.overdue');
    switch (r.status.toLowerCase()) {
      case 'approved': return context.tr('borrowed.status.approved');
      case 'returned': return context.tr('borrowed.status.returned');
      default:         return context.tr('borrowed.status.pending');
    }
  }

  List<ReservationModel> _sorted(
      List<ReservationModel> list,
      Map<int, BookModel> bookMap,
      ) {
    final s = List<ReservationModel>.from(list);
    s.sort((a, b) {
      int cmp;
      if (_sortField == _SortField.name) {
        cmp = (bookMap[a.id_book]?.title ?? '')
            .compareTo(bookMap[b.id_book]?.title ?? '');
      } else {
        final da = a.expiration_date ?? DateTime(9999);
        final db = b.expiration_date ?? DateTime(9999);
        cmp = da.compareTo(db);
      }
      return _sortDir == _SortDir.asc ? cmp : -cmp;
    });
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Заголовок ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(context.tr('borrowed.title'), style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: _textDark, fontFamily: 'Nunito',
                )),
                const SizedBox(height: 2),
                Text(context.tr('borrowed.subtitle'),
                    style: TextStyle(fontSize: 12, color: Colors.brown.shade400)),
              ]),
            ),

            // ── Сортировка ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(children: [
                Text(context.tr('borrowed.sorting'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(width: 10),
                _SortChip(
                  label: context.tr('borrowed.sort_book'),
                  selected: _sortField == _SortField.name,
                  ascending: _sortDir == _SortDir.asc,
                  onTap: () => setState(() {
                    if (_sortField == _SortField.name) {
                      _sortDir = _sortDir == _SortDir.asc ? _SortDir.desc : _SortDir.asc;
                    } else { _sortField = _SortField.name; _sortDir = _SortDir.asc; }
                  }),
                ),
                const SizedBox(width: 8),
                _SortChip(
                  label: context.tr('borrowed.sort_return_date'),
                  selected: _sortField == _SortField.returnDate,
                  ascending: _sortDir == _SortDir.asc,
                  onTap: () => setState(() {
                    if (_sortField == _SortField.returnDate) {
                      _sortDir = _sortDir == _SortDir.asc ? _SortDir.desc : _SortDir.asc;
                    } else { _sortField = _SortField.returnDate; _sortDir = _SortDir.asc; }
                  }),
                ),
              ]),
            ),

            // ── Шапка таблицы ──────────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              decoration: const BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    context.tr('borrowed.column_book'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.tr('borrowed.column_issue_date'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    context.tr('borrowed.column_return_date'),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              ]),
            ),

            // ── Тело таблицы ───────────────────────────
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (ctx, resState) {
        if (resState is ReservationLoading) {
          return const Center(
            child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5),
          );
        }
        if (resState is ReservationError) {
          return Center(child: Text(resState.error,
              style: const TextStyle(color: Colors.redAccent)));
        }

        final reservations =
        resState is ReservationLoaded ? resState.reservations : <ReservationModel>[];

        return BlocBuilder<BookBloc, BookState>(
          builder: (ctx, bookState) {
            List<BookModel> allBooks = [];
            if (bookState is BookSuccess) allBooks = bookState.books;
            if (bookState is BookByCategorySuccess) allBooks = bookState.allBooks;
            final bookMap = {for (final b in allBooks) b.id_book: b};

            final rows = _sorted(reservations, bookMap);

            final body = Container(
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                boxShadow: [BoxShadow(
                  color: Colors.brown.withOpacity(0.07),
                  blurRadius: 10, offset: const Offset(0, 4),
                )],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: rows.isEmpty
                    ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: Column(children: [
                    Icon(Icons.inbox_rounded, size: 60, color: Colors.grey.shade300),
                    const SizedBox(height: 10),
                    Text(context.tr('borrowed.empty'),
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 14)),
                  ])),
                )
                    : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, indent: 14, endIndent: 14, color: Colors.grey.shade200),
                  itemBuilder: (ctx, i) {
                    final r    = rows[i];
                    final book = bookMap[r.id_book];
                    final over = _isOverdue(r);

                    return Container(
                      color: _rowBg(r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          // Книга + статус
                          Expanded(flex: 3, child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  book?.title ?? context.tr(
                                    'borrowed.book_fallback',
                                    params: {'id': '${r.id_book}'},
                                  ),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark),
                                  maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _badgeColor(r).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(_badgeLabel(r), style: TextStyle(
                                  fontSize: 10, fontWeight: FontWeight.w700,
                                  color: _badgeColor(r),
                                )),
                              ),
                            ],
                          )),
                          // Дата выдачи
                          Expanded(flex: 2, child: Text(_fmt(r.reservation_date),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              textAlign: TextAlign.center)),
                          // Дата возврата
                          Expanded(flex: 2, child: Text(_fmt(r.expiration_date),
                              style: TextStyle(
                                fontSize: 12,
                                color: over ? Colors.red.shade700 : Colors.grey.shade600,
                                fontWeight: over ? FontWeight.w700 : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center)),
                        ]),
                      ),
                    );
                  },
                ),
              ),
            );
            return body;
          },
        );
      },
    );
  }
}

// ── Sort chip widget ───────────────────────────────────
class _SortChip extends StatelessWidget {
  final String label;
  final bool selected, ascending;
  final VoidCallback onTap;
  static const Color _orange = Color(0xffFF9E74);

  const _SortChip({required this.label, required this.selected,
    required this.ascending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? _orange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
            color: selected ? _orange.withOpacity(0.30) : Colors.black.withOpacity(0.06),
            blurRadius: 6, offset: const Offset(0, 2),
          )],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade600,
          )),
          if (selected) ...[
            const SizedBox(width: 4),
            Icon(ascending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12, color: Colors.white),
          ],
        ]),
      ),
    );
  }
}
