import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/api_localhost/AuthorService.dart';
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
import '../../model/author_model.dart';
import '../../model/book_copy_model.dart';
import '../../model/notification_model.dart';
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

  List<NotificationModel> _notifications = [];
  bool _notifLoading = false;
  Timer? _notifTimer;

  // ─── BookService instance ───────────────────────────────
  final bookService _bookService = bookService();
  final Authorservice _authorservice = Authorservice();

  final Map<int, Future<AuthorModel>> _authorFutures = {};



  @override
  void initState() {
    super.initState();
    _futureUser = AuthService().getUserbyId(widget.user.id_user);
    context.read<BookBloc>().add(GetBookEvent());
    context.read<CategoryBloc>().add(GetAllCategoryEvent());
    context.read<BookCopyBloc>().add(GetBookCopyEvent());

    // ── Notifications ──
    _fetchNotifications();
    _notifTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _fetchNotifications(),
    );
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }
  // ─── Fetch notifications cho user hiện tại ──────────────────────────
  Future<void> _fetchNotifications() async {
    if (_notifLoading || !mounted) return;
    _notifLoading = true;
    try {
      final data = await ApiService.get('/notifications-management/notifications');
      if (!mounted) return;
      final all = (data is List ? data : (data['notifications'] as List? ?? []))
      as List;
      final mine = all
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .where((n) => n.id_user == widget.user.id_user)
          .toList()
        ..sort((a, b) => (b.sent_at ?? DateTime(0))
            .compareTo(a.sent_at ?? DateTime(0)));
      if (mounted) setState(() => _notifications = mine);
    } catch (_) {}
    _notifLoading = false;
  }

// ─── Đánh dấu đã đọc ────────────────────────────────────────────────
  Future<void> _markRead(NotificationModel n) async {
    if (n.is_read || n.id_notification == null) return;
    try {
      await ApiService.put(
        '/notifications-management/notification/${n.id_notification}',
        {'is_read': true},
      );
      if (!mounted) return;
      setState(() {
        _notifications = _notifications
            .map((x) => x.id_notification == n.id_notification
            ? x.copyWith(is_read: true)
            : x)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    final unread = _notifications.where((n) => !n.is_read).toList();
    for (final n in unread) await _markRead(n);
  }

// ─── Panel thông báo ────────────────────────────────────────────────
  void _showNotificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final unread = _notifications.where((n) => !n.is_read).length;
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // ── Handle ──
                const SizedBox(height: 10),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // ── Header ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Text(
                          'Уведомления',
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: Color(0xff3D2314),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('$unread',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ]),
                      if (unread > 0)
                        TextButton(
                          onPressed: () async {
                            await _markAllRead();
                            setSheet(() {});
                          },
                          child: const Text(
                            'Прочитать все',
                            style: TextStyle(
                                color: _orange, fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // ── List ──
                Expanded(
                  child: _notifications.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_rounded,
                            size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Нет уведомлений',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                      : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 70),
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      return _NotifTile(
                        notif: n,
                        onTap: () async {
                          await _markRead(n);
                          setSheet(() {});
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
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

          GestureDetector(
            onTap: _showNotificationSheet,
            child: Stack(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 22),
              ),
              // Badge số thông báo chưa đọc
              Builder(builder: (_) {
                final unread =
                    _notifications.where((n) => !n.is_read).length;
                if (unread == 0) return const SizedBox.shrink();
                return Positioned(
                  right: 6, top: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    constraints:
                    const BoxConstraints(minWidth: 16, minHeight: 16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.red.shade500,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ]),
          ),

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
                    // ✅ Code mới
                    children: books.map((book) {
                      // Cache future tác giả — không tạo mới mỗi lần build
                      _authorFutures.putIfAbsent(
                        book.id_author,
                            () => _authorservice.getAuthorByID(book.id_author),
                      );

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
                        authorFuture: _authorFutures[book.id_author]!,  // Dùng cache
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


class _NotifTile extends StatelessWidget {
  final NotificationModel notif;
  final VoidCallback onTap;
  const _NotifTile({required this.notif, required this.onTap});

  // ── Tách phần text và barcode từ message ──────────────────────────
  String get _messageText {
    final idx = notif.message.indexOf('|BARCODE:');
    return idx >= 0 ? notif.message.substring(0, idx) : notif.message;
  }

  String? get _barcodeValue {
    final idx = notif.message.indexOf('|BARCODE:');
    if (idx < 0) return null;
    final val = notif.message.substring(idx + 9);
    return val.isNotEmpty ? val : null;
  }

  // ── Icon / color / label theo type ───────────────────────────────
  IconData get _icon {
    switch (notif.type) {
      case 'loan_ready': return Icons.check_circle_outline_rounded;
      case 'overdue':    return Icons.warning_amber_rounded;
      case 'due_soon':   return Icons.access_time_rounded;
      default:           return Icons.notifications_outlined;
    }
  }

  Color get _color {
    switch (notif.type) {
      case 'loan_ready': return Colors.green;
      case 'overdue':    return Colors.red;
      case 'due_soon':   return const Color(0xffFF9E74);
      default:           return Colors.blueGrey;
    }
  }

  String get _typeLabel {
    switch (notif.type) {
      case 'loan_ready': return 'Книга готова';
      case 'overdue':    return 'Просрочка';
      case 'due_soon':   return 'Скоро истекает';
      default:           return notif.type;
    }
  }

  void _showQrSheet(BuildContext context, String code) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Код для сканирования',
              style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: Color(0xff3D2314),
              ),
            ),
            const SizedBox(height: 20),
            // QR code
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.network(
                'https://api.qrserver.com/v1/create-qr-code/'
                    '?size=200x200&data=${Uri.encodeComponent(code)}',
                width: 200, height: 200,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                  width: 200, height: 200,
                  child: Center(child: CircularProgressIndicator()),
                ),
                errorBuilder: (_, __, ___) => const SizedBox(
                  width: 200, height: 200,
                  child: Icon(Icons.qr_code_2, size: 80, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Barcode text
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                code,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Предъявите этот код библиотекарю',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final barcode = _barcodeValue;
    final timeStr = notif.sent_at != null
        ? '${notif.sent_at!.day.toString().padLeft(2, '0')}/'
        '${notif.sent_at!.month.toString().padLeft(2, '0')}/'
        '${notif.sent_at!.year}  '
        '${notif.sent_at!.hour.toString().padLeft(2, '0')}:'
        '${notif.sent_at!.minute.toString().padLeft(2, '0')}'
        : '';

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: notif.is_read ? Colors.transparent : _color.withOpacity(0.05),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Icon ──
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, color: _color, size: 20),
            ),
            const SizedBox(width: 12),

            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type label + unread dot
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _typeLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _color,
                        ),
                      ),
                      if (!notif.is_read)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                              color: _color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  // Message text (không hiện phần BARCODE)
                  Text(
                    _messageText,
                    style: TextStyle(
                      fontSize: 13,
                      color: notif.is_read
                          ? Colors.grey.shade500
                          : const Color(0xff3D2314),
                      height: 1.4,
                    ),
                  ),

                  // ── QR preview cho loan_ready ──
                  if (barcode != null) ...[
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => _showQrSheet(context, barcode),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code_2_rounded,
                                size: 28, color: Colors.green),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Показать QR-код',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green,
                                  ),
                                ),
                                Text(
                                  barcode.length > 16
                                      ? '${barcode.substring(0, 16)}…'
                                      : barcode,
                                  style: TextStyle(
                                    fontFamily: 'Courier',
                                    fontSize: 11,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.chevron_right_rounded,
                                color: Colors.green.shade400, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],

                  if (timeStr.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(timeStr,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

