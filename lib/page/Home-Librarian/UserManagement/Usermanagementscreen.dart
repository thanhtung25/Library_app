import 'package:flutter/material.dart';
import 'package:library_app/api_localhost/ApiService.dart';
import 'package:library_app/model/user_model.dart';
import 'package:library_app/page/Home-Librarian/UserManagement/user_detail_screen.dart';

// ─── Simple display model ──────────────────────────────────────────────────────
class _LibUser {
  final int    id;
  final String fullName;
  final String username;
  final String role;
  final String status;
  final String phone;
  final String libraryCard;
  final String email;
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
    rawData:     j,
  );
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
  bool   _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.get('/users-management/users');
      final rawList = data is List ? data as List : (data['users'] as List? ?? []);
      final list = rawList
          .map((e) => _LibUser.fromJson(e as Map<String, dynamic>))
          .toList();
      setState(() {
        _users = list.where((u) => u.role == 'reader').toList();
        _loading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _users.where((u) =>
      q.isEmpty ||
          u.fullName.toLowerCase().contains(q) ||
          u.username.toLowerCase().contains(q) ||
          u.libraryCard.toLowerCase().contains(q) ||
          u.phone.contains(q),
      ).toList();
    });
  }

  // ── Toggle status active/inactive ─────────────────────────────────────────
  Future<void> _toggleStatus(_LibUser u) async {
    final newStatus = u.status == 'active' ? 'inactive' : 'active';
    final label     = newStatus == 'active' ? 'kích hoạt' : 'vô hiệu hoá';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận $label',
            style: const TextStyle(fontFamily: 'Times New Roman')),
        content: Text('$label tài khoản "${u.fullName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _orange),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Xác nhận',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ApiService.put('/users-management/user/${u.id}',
            {'status': newStatus});
        _fetchUsers();
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  // ── View user detail dialog ───────────────────────────────────────────────
  void _showDetail(_LibUser u) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _orange.withOpacity(0.2),
                  child: Text(
                    u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(color: _orange, fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.fullName,
                        style: const TextStyle(
                            fontFamily: 'Times New Roman',
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('@${u.username}',
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            _detailRow(Icons.badge,        'Thẻ thư viện', u.libraryCard),
            _detailRow(Icons.phone,        'Điện thoại',   u.phone),
            _detailRow(Icons.email,        'Email',        u.email),
            _detailRow(Icons.manage_accounts, 'Vai trò',  u.role),
            _detailRow(Icons.circle,       'Trạng thái',  u.status),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Icon(icon, size: 18, color: _orange),
        const SizedBox(width: 10),
        Text('$label: ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Expanded(
          child: Text(value,
              style: const TextStyle(fontFamily: 'Times New Roman',
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Quản lý Người dùng',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
            color: _orange,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _orange),
            onPressed: _fetchUsers,
          ),
        ],
      ),

      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => _applyFilter(),
              decoration: InputDecoration(
                hintText: 'Tìm tên, tài khoản, số thẻ, SĐT...',
                prefixIcon: const Icon(Icons.search, color: _orange),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Summary chips
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 8),
            child: Row(
              children: [
                _chip('Độc giả: ${_users.length}', Colors.blueGrey),
                const SizedBox(width: 8),
                _chip('Hoạt động: ${_users.where((u) => u.status == "active").length}',
                    Colors.green),
                const SizedBox(width: 8),
                _chip('Khoá: ${_users.where((u) => u.status != "active").length}',
                    Colors.red),
              ],
            ),
          ),

          // Table header
          _tableHeader(),

          // User rows
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _orange))
                : _error != null
                ? Center(child: Text(_error!,
                style: const TextStyle(color: Colors.red)))
                : _filtered.isEmpty
                ? const Center(child: Text('Không tìm thấy người dùng'))
                : RefreshIndicator(
              onRefresh: _fetchUsers,
              color: _orange,
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) => _userRow(_filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label,
        style: TextStyle(color: color, fontSize: 12,
            fontWeight: FontWeight.bold)),
  );

  Widget _tableHeader() => Container(
    color: _orange,
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
    child: const Row(
      children: [
        Expanded(flex: 3, child: _H('Họ tên')),
        Expanded(flex: 2, child: _H('Thẻ TV')),
        Expanded(flex: 2, child: _H('SĐT')),
        SizedBox(width: 36),
      ],
    ),
  );

  Widget _userRow(_LibUser u) {
    final isActive = u.status == 'active';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserDetailScreen(userData: u.rawData),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          children: [
            // Avatar + name
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: _orange.withOpacity(0.2),
                      child: Text(
                        u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
                        style: const TextStyle(color: _orange, fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(u.fullName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'Times New Roman', fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(flex: 2, child: _cell(u.libraryCard)),
            Expanded(flex: 2, child: _cell(u.phone)),

            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 18, color: Colors.grey),
              onSelected: (v) {
                if (v == 'detail') Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserDetailScreen(userData: u.rawData),
                  ),
                );
                if (v == 'toggle') _toggleStatus(u);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'detail',
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Xem chi tiết'),
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: ListTile(
                    leading: Icon(
                      isActive ? Icons.block : Icons.check_circle_outline,
                      color: isActive ? Colors.red : Colors.green,
                    ),
                    title: Text(
                      isActive ? 'Vô hiệu hoá' : 'Kích hoạt',
                      style: TextStyle(
                          color: isActive ? Colors.red : Colors.green),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(String text) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
    child: Text(text, style: const TextStyle(fontSize: 12)),
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