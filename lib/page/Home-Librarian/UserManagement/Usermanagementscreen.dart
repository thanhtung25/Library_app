import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';
import 'package:library_app/model/user_model.dart';
import 'package:library_app/page/Home-Librarian/UserManagement/user_detail_screen.dart';

// ─── Display model ────────────────────────────────────────────────────────────
class _LibUser {
  final int    id;
  final String fullName;
  final String username;
  final String role;
  final String status;
  final String phone;
  final String libraryCard;
  final String email;
  final String birthDay;
  final String createdAt;
  final String gender;
  final String address;
  final String avatarUrl;
  final Map<String, dynamic> rawData;

  _LibUser({
    required this.id,
    required this.fullName,
    required this.username,
    required this.role,
    required this.status,
    required this.phone,
    required this.libraryCard,
    required this.email,
    required this.birthDay,
    required this.createdAt,
    required this.gender,
    required this.address,
    required this.avatarUrl,
    required this.rawData,
  });

  factory _LibUser.fromJson(Map<String, dynamic> j) => _LibUser(
    id:          j['id_user']      ?? 0,
    fullName:    j['full_name']    ?? '',
    username:    j['username']     ?? '',
    role:        j['role']         ?? '',
    status:      j['status']       ?? 'active',
    phone:       j['phone']        ?? '',
    libraryCard: j['library_card'] ?? '',
    email:       j['email']        ?? '',
    birthDay:    _fmtDate(j['birth_day']?.toString()),
    createdAt:   _fmtDate(j['created_at']?.toString()),
    gender:      j['gender']       ?? '',
    address:     j['address']      ?? '',
    avatarUrl:   j['avatar_url']   ?? '',
    rawData:     j,
  );

  static String _fmtDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}.'
          '${dt.month.toString().padLeft(2, '0')}.'
          '${dt.year}';
    } catch (_) { return raw; }
  }

  String get genderLabel {
    switch (gender.toLowerCase()) {
      case 'male':   return 'Мужской';
      case 'female': return 'Женский';
      default:       return gender;
    }
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class UserManagementScreen extends StatefulWidget {
  final UserModel user;
  const UserManagementScreen({super.key, required this.user});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  static const _orange = Color(0xffFF9E74);
  static const _bg     = Color(0xffFBEEE4);

  final _searchCtrl = TextEditingController();

  List<_LibUser> _users    = [];
  List<_LibUser> _filtered = [];
  bool    _loading = true;
  String? _error;

  static const _rowsPerPage = 15;
  int _page = 0;

  @override
  void initState() { super.initState(); _fetchUsers(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<void> _fetchUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data    = await ApiService.get('/users-management/users');
      final rawList = data is List ? data as List : (data['users'] as List? ?? []);
      final list    = rawList
          .map((e) => _LibUser.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _users   = list.where((u) => u.role == 'reader').toList();
        _loading = false;
        _page    = 0;
      });
      _applyFilter();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _page = 0;
      _filtered = _users.where((u) =>
      q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.libraryCard.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.email.toLowerCase().contains(q),
      ).toList();
    });
  }

  List<_LibUser> get _paged {
    final s = _page * _rowsPerPage;
    final e = (s + _rowsPerPage).clamp(0, _filtered.length);
    return _filtered.sublist(s, e);
  }

  int get _totalPages =>
      (_filtered.length / _rowsPerPage).ceil().clamp(1, 9999);

  // ── Actions ───────────────────────────────────────────────────────────────
  Future<void> _toggleStatus(_LibUser u) async {
    final newStatus = u.status == 'active' ? 'inactive' : 'active';
    final label     = newStatus == 'active' ? 'активировать' : 'заблокировать';
    final confirm   = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Подтвердите действие',
            style: TextStyle(fontFamily: 'Times New Roman')),
        content: Text('$label аккаунт "${u.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Подтвердить',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.put('/users-management/user/${u.id}',
            {'status': newStatus});
        _fetchUsers();
      } catch (e) { _showError(e.toString()); }
    }
  }

  void _openDetail(_LibUser u) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => UserDetailScreen(userData: u.rawData)),
  );

  void _showError(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: Colors.red),
  );

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _bg,
        elevation: 0,
        title: const Text('Управление читателями',
            style: TextStyle(
                fontFamily: 'Times New Roman',
                fontWeight: FontWeight.bold,
                color: _orange,
                fontSize: 22)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh, color: _orange),
              onPressed: _fetchUsers),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 900;
        return Column(children: [
          // ── Search ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText:
                'Поиск по имени, логину, номеру билета, телефону...',
                prefixIcon: const Icon(Icons.search, color: _orange),
                filled: true, fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          // ── Chips ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Row(children: [
              _chip('Читателей: ${_users.length}',    Colors.blueGrey),
              const SizedBox(width: 8),
              _chip('Активных: ${_users.where((u) => u.status == "active").length}',
                  Colors.green),
              const SizedBox(width: 8),
              _chip('Заблок.: ${_users.where((u) => u.status != "active").length}',
                  Colors.red),
            ]),
          ),

          // ── Content ──────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                child: CircularProgressIndicator(color: _orange))
                : _error != null
                ? Center(child: Text(_error!,
                style: const TextStyle(color: Colors.red)))
                : _filtered.isEmpty
                ? const Center(child: Text('Нет данных'))
                : isWeb
                ? _buildWebLayout()
                : _buildMobileLayout(),
          ),
        ]);
      }),
    );
  }

  // ── Web ───────────────────────────────────────────────────────────────────
  Widget _buildWebLayout() => Column(children: [
    Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: _webTable(),
      ),
    ),
    _paginationBar(),
  ]);

  Widget _webTable() {
    const hStyle = TextStyle(
        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13);

    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 1080),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(_orange),
                columnSpacing: 18,
                headingRowHeight: 48,
                dataRowMinHeight: 52,
                dataRowMaxHeight: 64,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text('Пользователь',  style: hStyle)),
                  DataColumn(label: Text('Номер билета',  style: hStyle)),
                  DataColumn(label: Text('Дата рождения', style: hStyle)),
                  DataColumn(label: Text('Дата создания', style: hStyle)),
                  DataColumn(label: Text('Пол',           style: hStyle)),
                  DataColumn(label: Text('Адрес',         style: hStyle)),
                  DataColumn(label: Text('Телефон',       style: hStyle)),
                  DataColumn(label: Text('Статус',        style: hStyle)),
                  DataColumn(label: Text('Действия',      style: hStyle)),
                ],
                rows: _paged.map((u) {
                  final isActive = u.status == 'active';
                  return DataRow(cells: [

                    // Пользователь — аватар + имя
                    DataCell(GestureDetector(
                      onTap: () => _openDetail(u),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _avatarWidget(u, radius: 18),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 160),
                            child: Text(u.fullName,
                                style: const TextStyle(
                                    fontFamily: 'Times New Roman',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                    )),

                    // Номер билета
                    DataCell(Text(u.libraryCard,
                        style: const TextStyle(fontSize: 13))),

                    // Дата рождения
                    DataCell(Text(u.birthDay,
                        style: const TextStyle(fontSize: 12))),

                    // Дата создания
                    DataCell(Text(u.createdAt,
                        style: const TextStyle(fontSize: 12))),

                    // Пол
                    DataCell(Text(u.genderLabel,
                        style: const TextStyle(fontSize: 12))),

                    // Адрес
                    DataCell(ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(u.address,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    )),

                    // Телефон
                    DataCell(Text(u.phone,
                        style: const TextStyle(fontSize: 12))),

                    // Статус
                    DataCell(_statusBadge(u.status)),

                    // Действия
                    DataCell(Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _iconBtn(Icons.info_outline, _orange,
                            'Подробнее', () => _openDetail(u)),
                        _iconBtn(
                          isActive
                              ? Icons.block
                              : Icons.check_circle_outline,
                          isActive ? Colors.red : Colors.green,
                          isActive ? 'Заблокировать' : 'Активировать',
                              () => _toggleStatus(u),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _paginationBar() {
    final start = _page * _rowsPerPage + 1;
    final end   = ((_page + 1) * _rowsPerPage).clamp(0, _filtered.length);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Показано $start–$end из ${_filtered.length}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Row(children: [
            _pgBtn(Icons.first_page, _page == 0,
                    () => setState(() => _page = 0)),
            _pgBtn(Icons.chevron_left, _page == 0,
                    () => setState(() => _page--)),
            ..._pgNumbers(),
            _pgBtn(Icons.chevron_right, _page >= _totalPages - 1,
                    () => setState(() => _page++)),
            _pgBtn(Icons.last_page, _page >= _totalPages - 1,
                    () => setState(() => _page = _totalPages - 1)),
          ]),
        ],
      ),
    );
  }

  Widget _pgBtn(IconData icon, bool disabled, VoidCallback onTap) =>
      IconButton(
        icon: Icon(icon),
        color: disabled ? Colors.grey : _orange,
        onPressed: disabled ? null : onTap,
      );

  List<Widget> _pgNumbers() {
    const maxV  = 5;
    final total = _totalPages;
    final start = (_page - maxV ~/ 2).clamp(0, (total - maxV).clamp(0, total));
    final end   = (start + maxV).clamp(0, total);
    return List.generate(end - start, (i) {
      final p      = start + i;
      final active = p == _page;
      return GestureDetector(
        onTap: () => setState(() => _page = p),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: active ? _orange : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
                color: active ? _orange : Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Text('${p + 1}',
              style: TextStyle(
                fontSize: 13,
                color: active ? Colors.white : Colors.black87,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              )),
        ),
      );
    });
  }

  // ── Mobile ─────────────────────────────────────────────────────────────────
  Widget _buildMobileLayout() => Column(children: [
    Container(
      color: _orange,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: const Row(children: [
        Expanded(flex: 3, child: _H('ФИО')),
        Expanded(flex: 2, child: _H('Билет')),
        Expanded(flex: 2, child: _H('Телефон')),
        SizedBox(width: 36),
      ]),
    ),
    Expanded(
      child: RefreshIndicator(
        onRefresh: _fetchUsers,
        color: _orange,
        child: ListView.builder(
          itemCount: _filtered.length,
          itemBuilder: (_, i) => _mobileRow(_filtered[i]),
        ),
      ),
    ),
  ]);

  Widget _mobileRow(_LibUser u) {
    final isActive = u.status == 'active';
    return GestureDetector(
      onTap: () => _openDetail(u),
      child: Container(
        decoration: BoxDecoration(
            border:
            Border(bottom: BorderSide(color: Colors.grey.shade200))),
        child: Row(children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
              child: Row(children: [
                _avatarWidget(u, radius: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(u.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontFamily: 'Times New Roman', fontSize: 13)),
                ),
              ]),
            ),
          ),
          Expanded(flex: 2,
              child: _cell(u.libraryCard)),
          Expanded(flex: 2,
              child: _cell(u.phone)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
            onSelected: (v) {
              if (v == 'detail') _openDetail(u);
              if (v == 'toggle') _toggleStatus(u);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'detail',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Подробнее'),
                    contentPadding: EdgeInsets.zero,
                  )),
              PopupMenuItem(value: 'toggle',
                  child: ListTile(
                    leading: Icon(
                      isActive ? Icons.block : Icons.check_circle_outline,
                      color: isActive ? Colors.red : Colors.green,
                    ),
                    title: Text(
                      isActive ? 'Заблокировать' : 'Активировать',
                      style: TextStyle(
                          color: isActive ? Colors.red : Colors.green),
                    ),
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          ),
        ]),
      ),
    );
  }

  // ── Shared widgets ──────────────────────────────────────────────────────────
  Widget _avatarWidget(_LibUser u, {required double radius}) {
    final url     = u.avatarUrl;
    final hasAvatar = url.isNotEmpty;
    final fullUrl = url.startsWith('http') ? url : 'http://10.0.2.2:5000$url';
    return CircleAvatar(
      radius: radius,
      backgroundColor: _orange.withOpacity(0.2),
      backgroundImage: hasAvatar ? NetworkImage(fullUrl) : null,
      child: hasAvatar
          ? null
          : Text(
        u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
        style: TextStyle(
            color: _orange,
            fontSize: radius * 0.75,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final active = status == 'active';
    final color  = active ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(active ? 'Активен' : 'Заблокирован',
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _iconBtn(IconData icon, Color color, String tooltip,
      VoidCallback onTap) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      );

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.bold)),
  );

  Widget _cell(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
    child: Text(text,
        style: const TextStyle(fontSize: 12),
        overflow: TextOverflow.ellipsis),
  );
}

class _H extends StatelessWidget {
  final String t;
  const _H(this.t);
  @override
  Widget build(BuildContext context) => Text(t,
      style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12));
}