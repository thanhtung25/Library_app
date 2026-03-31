import 'package:flutter/material.dart';
import 'user_loan_history_screen.dart';
import 'user_fines_screen.dart';

class UserDetailScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const UserDetailScreen({super.key, required this.userData});

  static const _orange = Color(0xffFF9E74);
  static const _bg = Color(0xffFBEEE4);

  @override
  Widget build(BuildContext context) {
    final id          = userData['id_user']?.toString() ?? '';
    final fullName    = userData['full_name']    ?? '';
    final libraryCard = userData['library_card'] ?? '';
    final birthDay    = userData['birth_day']    ?? '';
    final rawGender   = userData['gender']       ?? '';
    final gender      = rawGender == 'male'
        ? 'Мужской'
        : rawGender == 'female' ? 'Женский' : rawGender;
    final email   = userData['email']   ?? '';
    final phone   = userData['phone']   ?? '';
    final address = userData['address'] ?? '';
    final avatarUrl = userData['avatar_url'];

    String _fullAvatarUrl(String path) {
      if (path.isEmpty) return '';
      if (path.startsWith('http')) return path;
      return 'http://10.0.2.2:5000$path';
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Профиль читателя',
          style: TextStyle(
            fontFamily: 'Times New Roman',
            fontWeight: FontWeight.bold,
            color: _orange,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Avatar ──────────────────────────────────────────────────────
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundColor: _orange.withOpacity(0.2),
                backgroundImage: (avatarUrl != null && avatarUrl.toString().isNotEmpty)
                    ? NetworkImage(_fullAvatarUrl(avatarUrl.toString()))
                    : null,
                child: (avatarUrl == null || avatarUrl.toString().isEmpty)
                    ? Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: _orange, fontSize: 36, fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fullName,
              style: const TextStyle(
                fontFamily: 'Times New Roman',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // ── Fields ──────────────────────────────────────────────────────
            _buildField('ID читателя', id),
            _buildField('Билет библиотеки', libraryCard),
            _buildField('ФИО', fullName),
            _buildField('Дата рождения', birthDay),
            _buildField('Пол', gender),
            _buildField('Эл. почта', email),
            _buildField('Телефон', phone),
            _buildField('Адрес', address),

            const SizedBox(height: 32),

            // ── Navigation buttons ──────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.history, color: Colors.white),
                    label: const Text(
                      'История выдач',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserLoanHistoryScreen(
                          userId: userData['id_user'] ?? 0,
                          userName: fullName,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.monetization_on, color: Colors.white),
                    label: const Text(
                      'Штрафы и долги',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserFinesScreen(
                          userId: userData['id_user'] ?? 0,
                          userName: fullName,
                        ),
                      ),
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

  Widget _buildField(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: TextEditingController(text: value),
      enabled: false,
      style: const TextStyle(
        fontFamily: 'Times New Roman',
        fontSize: 14,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _orange, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    ),
  );
}
