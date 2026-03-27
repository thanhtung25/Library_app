import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/book/event.dart';
import 'package:library_app/bloc/book/state.dart';
import 'package:library_app/bloc/book_copy/event.dart';
import 'package:library_app/bloc/category/bloc.dart';
import 'package:library_app/bloc/category/event.dart';
import 'package:library_app/bloc/category/state.dart';
import 'package:library_app/bloc/reservation/bloc.dart';
import 'package:library_app/bloc/reservation/event.dart';
import 'package:library_app/localization/app_localizations.dart';

import '../../api_localhost/ApiService.dart';
import '../../api_localhost/AuthService.dart';
import '../../api_localhost/BookService.dart';
import '../../bloc/book/bloc.dart';
import '../../bloc/book_copy/bloc.dart';
import '../../bloc/book_copy/state.dart';
import '../../model/book_copy_model.dart';
import '../../model/user_model.dart';
import 'Books/book_card.dart';

class HomeTab extends StatefulWidget {
  final UserModel user;
  final Function(int) onChangeTab;

  const HomeTab({super.key, required this.user, required this.onChangeTab});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  // ─── constants ─────────────────────────────────────────
  static const Color _orange   = Color(0xffFF9E74);
  static const Color _bg       = Color(0xffF8EDE3);
  static const Color _textDark = Color(0xff3D2314);

  // ─── state ─────────────────────────────────────────────
  late Future<UserModel> _futureUser;
  int    _catIndex    = 0;
  String _catSelected = '';

  // ─── BookService instance ───────────────────────────────
  final bookService _bookService = bookService();

  @override
  void initState() {
    super.initState();
    _futureUser = AuthService().getUserbyId(widget.user.id_user);
    context.read<BookBloc>().add(GetBookEvent());
    context.read<CategoryBloc>().add(GetAllCategoryEvent());
    context.read<BookCopyBloc>().add(GetBookCopyEvent());
  }

  // ─── build ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverToBoxAdapter(child: _searchBar()),
          SliverToBoxAdapter(child: _bannerCard()),
          SliverToBoxAdapter(child: _quickActions()),
          SliverToBoxAdapter(child: _bookSection()),
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════
  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 56, 22, 28),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xffFF6D40), Color(0xffFF9E74)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
              ),
              child:  CircleAvatar(
                radius: 24,
                backgroundImage:  NetworkImage('${ApiService.baseUrl}${widget.user.avatar_url}'),
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            FutureBuilder<UserModel>(
              future: _futureUser,
              builder: (context, snap) {
                final name = snap.hasData ? snap.data!.fullName : '...';
                return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    context.tr('home.greeting'),
                    style: const TextStyle(color: Colors.white70, fontSize: 20),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 19,
                      fontWeight: FontWeight.bold, fontFamily: 'Nunito',
                    ),
                  ),
                ]);
              },
            ),
          ]),

          Stack(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
            ),
            Positioned(
              right: 9, top: 7,
              child: Container(
                width: 9, height: 9,
                decoration: BoxDecoration(
                  color: Colors.red.shade400, shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SEARCH BAR
  // ═══════════════════════════════════════════════════════
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: GestureDetector(
        onTap: () => widget.onChangeTab(1),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.brown.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(children: [
            const Icon(Icons.search_rounded, color: _orange, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                context.tr('home.search_hint'),
                style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.tune_rounded, color: _orange, size: 18),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BANNER CARD
  // ═══════════════════════════════════════════════════════
  Widget _bannerCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff5C35D9), Color(0xff9B72EF)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: const Color(0xff5C35D9).withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                context.tr('home.banner_title'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('home.banner_subtitle'),
                style: TextStyle(color: Colors.white.withOpacity(0.82), fontSize: 12, height: 1.45),
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => widget.onChangeTab(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    context.tr('home.banner_action'),
                    style: const TextStyle(
                      color: Color(0xff5C35D9),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ]),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset('assets/images/book1.png', height: 90, width: 68, fit: BoxFit.cover),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // QUICK ACTIONS
  // ═══════════════════════════════════════════════════════
  Widget _quickActions() {
    final items = [
      _Action(Icons.book_rounded, context.tr('home.action.borrow'), const Color(0xffFF9E74), 2),
      _Action(Icons.assignment_return_rounded, context.tr('home.action.return'), const Color(0xff74B9FF), 3),
      _Action(Icons.bookmark_add_rounded, context.tr('home.action.reserve'), const Color(0xff00CBA0), 1),
      _Action(Icons.history_rounded, context.tr('home.action.favorite'), const Color(0xffFDCB6E), 3),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          context.tr('home.quick_actions'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.map((a) => _ActionBtn(
            icon: a.icon, label: a.label, color: a.color,
            onTap: () => widget.onChangeTab(a.tab),
          )).toList(),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════

  // CATEGORY CHIPS
  // ═══════════════════════════════════════════════════════
  Widget _categorySection() {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            context.tr('home.categories'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark),
          ),
        ),
        const SizedBox(height: 14),
        BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            final cats = <String>[context.tr('home.all')];
            if (state is CategorySuccess) {
              cats.addAll(state.category.map((c) => c.name));
            }
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: List.generate(cats.length, (i) {
                  final sel = _catIndex == i;
                  return GestureDetector(
                    onTap: () {
                      setState(() { _catIndex = i; _catSelected = i == 0 ? '' : cats[i]; });
                      if (i == 0) {
                        context.read<BookBloc>().add(GetBookEvent());
                      } else {
                        context.read<BookBloc>().add(GetBookByCategoryEvent(category: cats[i]));
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? _orange : Colors.white,
                        borderRadius: BorderRadius.circular(50),
                        boxShadow: [BoxShadow(
                          color: sel ? _orange.withOpacity(0.38) : Colors.black.withOpacity(0.06),
                          blurRadius: sel ? 10 : 6,
                          offset: const Offset(0, 4),
                        )],
                      ),
                      child: Text(
                        cats[i],
                        style: TextStyle(
                          color: sel ? Colors.white : Colors.grey.shade500,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          },
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════
  // BOOK LIST
  // ═══════════════════════════════════════════════════════
  Widget _bookSection() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('home.suggestions'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textDark),
              ),
              GestureDetector(
                onTap: () => widget.onChangeTab(1),
                child: Text(
                  context.tr('home.see_all'),
                  style: const TextStyle(color: _orange, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Lắng nghe đồng thời BookBloc + BookCopyBloc ──
        BlocBuilder<BookCopyBloc, BookCopyState>(
          builder: (context, copyState) {
            final Map<int, BookCopyModel> copyByBook = {};

            if (copyState is BookCopyByIdBookSuccess) {
              // Ưu tiên bản sao 'available', fallback về first
              copyState.bookCopybyIdBook.forEach((idBook, list) {
                if (list.isNotEmpty) {
                  copyByBook[idBook] = list.firstWhere(
                        (c) => c.status == 'available',
                    orElse: () => list.first,
                  );
                }
              });
            } else if (copyState is BookCopySuccess) {
              // Ưu tiên bản sao 'available' cho mỗi id_book
              for (final copy in copyState.bookCopies) {
                if (!copyByBook.containsKey(copy.id_book)) {
                  copyByBook[copy.id_book] = copy;
                } else if (copy.status == 'available' &&
                    copyByBook[copy.id_book]!.status != 'available') {
                  copyByBook[copy.id_book] = copy;
                }
              }
            }

            return BlocBuilder<BookBloc, BookState>(
              builder: (context, bookState) {
                if (bookState is BookLoading || copyState is BookCopyLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 50),
                    child: Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5)),
                  );
                }
                if (bookState is BookError) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(bookState.message, style: const TextStyle(color: Colors.redAccent)),
                  );
                }

                List books = [];
                if (bookState is BookSuccess) {
                  books = bookState.books;
                } else if (bookState is BookByCategorySuccess) {
                  books = _catIndex == 0
                      ? bookState.allBooks
                      : (bookState.booksByCategory[_catSelected] ?? bookState.allBooks);
                }
                if (books.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                      context.tr('home.no_books'),
                      style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: books.map((book) {
                      // Gọi GetBookByIdBookEvent nếu chưa có bản copy cho book này
                      if (!copyByBook.containsKey(book.id_book)) {
                        context.read<BookCopyBloc>().add(
                          GetBookByIdBookEvent(id_book: book.id_book),
                        );
                      }

                      // Lấy bookCopy tương ứng; nếu chưa có thì dùng placeholder
                      final BookCopyModel bookCopy = copyByBook[book.id_book] ??
                          BookCopyModel(
                            id_book: book.id_book,
                            barcode: '',
                            status: 'unknown',
                          );

                      return BookCard(
                        book: book,
                        user: widget.user,
                        bookCopy: bookCopy,
                        authorFuture: _bookService.getAuthorByID(book.id_author),
                        onReload: () => context.read<BookBloc>().add(GetBookEvent()),
                        onReservationLoad: () => context.read<ReservationBloc>()
                            .add(GetReservationsByUserEvent(widget.user.id_user)),
                      );
                    }).toList(),
                  ),
                );
              },
            );
          },
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════
// DATA CLASS
// ═══════════════════════════════════════════════════════
class _Action {
  final IconData icon;
  final String   label;
  final Color    color;
  final int      tab;
  const _Action(this.icon, this.label, this.color, this.tab);
}

// ═══════════════════════════════════════════════════════
// QUICK ACTION BUTTON WIDGET
// ═══════════════════════════════════════════════════════
class _ActionBtn extends StatelessWidget {
  final IconData     icon;
  final String       label;
  final Color        color;
  final VoidCallback onTap;

  const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 62, height: 62,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: color.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xff5A4030)),
          textAlign: TextAlign.center,
        ),
      ]),
    );
  }
}