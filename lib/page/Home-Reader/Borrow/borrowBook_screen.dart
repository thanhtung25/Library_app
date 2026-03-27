import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/loan/bloc.dart';
import 'package:library_app/bloc/loan/event.dart';
import 'package:library_app/bloc/loan/state.dart';
import 'package:library_app/localization/app_localizations.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/bloc/reservation/state.dart';
import 'package:library_app/model/book_model.dart';
import 'package:library_app/model/reservations_model.dart';
import 'package:library_app/model/user_model.dart';

import '../../../bloc/book_copy/bloc.dart';
import '../../../bloc/book_copy/event.dart';
import '../../../bloc/book_copy/state.dart';
import '../../../model/book_copy_model.dart';
import '../../../model/loan_model.dart';

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
    context.read<LoanBloc>().add(
      GetLoansByUserIdEvent(id_user: widget.user.id_user),
    );
    context.read<BookBloc>().add(GetBookEvent());
    context.read<BookCopyBloc>().add(GetBookCopyEvent());
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day.toString().padLeft(2,'0')}'
        '.${dt.month.toString().padLeft(2,'0')}'
        '.${dt.year}';
  }

  bool _isOverdue(LoanModel r) =>
      r.return_date != null &&
          r.return_date.isBefore(DateTime.now()) &&
          r.status.toLowerCase() != 'returned';

  Color _rowBg(LoanModel r) {
    if (_isOverdue(r))                            return const Color(0xffFFE5E5);
    switch (r.status.toLowerCase()) {
      case 'approved': return const Color(0xffE8F8EC);
      case 'returned': return const Color(0xffF5F5F5);
      default:         return const Color(0xffFFF6EC);  // pending
    }
  }

  Color _badgeColor(LoanModel r) {
    final s = r.status.toLowerCase();

    if (_isOverdue(r) || s == 'overdue') {
      return Colors.red.shade700;
    }

    switch (s) {
      case 'reserved':
        return Colors.orange.shade800;

      case 'borrowed':
        return Colors.green.shade700;

      default:
        return Colors.grey.shade600;
    }
  }

  String _badgeLabel(LoanModel r) {
    final s = r.status.toLowerCase();

    if (_isOverdue(r) || s == 'overdue') {
      return context.tr('borrowed.status.overdue');
    }

    switch (s) {
      case 'reserved':
        return context.tr('borrowed.status.reserved');

      case 'borrowed':
        return context.tr('borrowed.status.borrowed');

      default:
        return context.tr('borrowed.status.unknown');
    }
  }

  List<LoanModel> _sorted(
      List<LoanModel> list,
      Map<int, BookCopyModel> copyMap,
      Map<int, BookModel> bookMap,
      ) {
    final s = List<LoanModel>.from(list);

    s.sort((a, b) {
      int cmp;

      if (_sortField == _SortField.name) {
        final copyA = copyMap[a.id_copy];
        final copyB = copyMap[b.id_copy];

        final titleA =
        copyA != null ? (bookMap[copyA.id_book]?.title ?? '') : '';
        final titleB =
        copyB != null ? (bookMap[copyB.id_book]?.title ?? '') : '';

        cmp = titleA.compareTo(titleB);
      } else {
        final da = a.return_date;
        final db = b.return_date;
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
    return BlocBuilder<LoanBloc, LoanState>(
      builder: (ctx, loanState) {
        if (loanState is LoanLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: _orange,
              strokeWidth: 2.5,
            ),
          );
        }

        if (loanState is LoanError) {
          return Center(
            child: Text(
              loanState.message,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }

        final List<LoanModel> loans =
        loanState is LoanByUserSuccess ? loanState.loans : <LoanModel>[];

        return BlocBuilder<BookCopyBloc, BookCopyState>(
          builder: (ctx, copyState) {
            List<BookCopyModel> allCopies = [];

            if (copyState is BookCopySuccess) {
              allCopies = copyState.bookCopies;
            }

            final copyMap = {
              for (final c in allCopies)
                if (c.id_copy != null) c.id_copy!: c,
            };

            return BlocBuilder<BookBloc, BookState>(
              builder: (ctx, bookState) {
                List<BookModel> allBooks = [];

                if (bookState is BookSuccess) {
                  allBooks = bookState.books;
                } else if (bookState is BookByCategorySuccess) {
                  allBooks = bookState.allBooks;
                }

                final bookMap = {for (final b in allBooks) b.id_book: b};

                final rows = _sorted(loans, copyMap, bookMap);

                return Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                    child: rows.isEmpty
                        ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 60,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.tr('borrowed.empty'),
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                        : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        indent: 14,
                        endIndent: 14,
                        color: Colors.grey.shade200,
                      ),
                      itemBuilder: (ctx, i) {
                        final r = rows[i];
                        final copy = copyMap[r.id_copy];
                        final book =
                        copy != null ? bookMap[copy.id_book] : null;
                        final over = _isOverdue(r);

                        return Container(
                          color: _rowBg(r),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book?.title ??
                                            context.tr(
                                              'borrowed.book_fallback',
                                              params: {
                                                'id': '${r.id_copy}'
                                              },
                                            ),
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: _textDark,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _badgeColor(r)
                                              .withOpacity(0.12),
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          _badgeLabel(r),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: _badgeColor(r),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _fmt(r.issue_date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    _fmt(r.return_date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: over
                                          ? Colors.red.shade700
                                          : Colors.grey.shade600,
                                      fontWeight: over
                                          ? FontWeight.w700
                                          : FontWeight.normal,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
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
