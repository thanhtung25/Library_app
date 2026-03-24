import 'package:flutter/material.dart';
import 'package:library_app/model/user_model.dart';
import '../../../Router/AppRoutes.dart';
import '../../../api_localhost/ApiService.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _orange   = Color(0xffFF9E74);
  static const Color _bg       = Color(0xffF8EDE3);
  static const Color _textDark = Color(0xff3D2314);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _birthCtrl;
  late final TextEditingController _genderCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  final Set<String> _editing = {};
  String _lang = 'Русский';

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl    = TextEditingController(text: u.fullName);
    _birthCtrl   = TextEditingController(text: _fmt(u.birth_day));
    _genderCtrl  = TextEditingController(text: u.gender);
    _emailCtrl   = TextEditingController(text: u.email);
    _phoneCtrl   = TextEditingController(text: u.phone);
    _addressCtrl = TextEditingController(text: u.address);
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _birthCtrl.dispose(); _genderCtrl.dispose();
    _emailCtrl.dispose(); _phoneCtrl.dispose(); _addressCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2,'0')}'
        '.${dt.month.toString().padLeft(2,'0')}'
        '.${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

            // ── Выбор языка ────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                GestureDetector(
                  onTap: () => setState(() =>
                  _lang = _lang == 'Русский' ? 'Tiếng Việt' : 'Русский'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(
                        color: Colors.brown.withOpacity(0.08),
                        blurRadius: 8, offset: const Offset(0, 2),
                      )],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.language_rounded, size: 14, color: _orange),
                      const SizedBox(width: 5),
                      Text(_lang, style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600, color: _textDark)),
                      const SizedBox(width: 3),
                      const Icon(Icons.arrow_drop_down_rounded, size: 18, color: _orange),
                    ]),
                  ),
                ),
              ]),
            ),

            // ── Аватар + имя ───────────────────────────
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 22),
                child: Column(children: [
                  Stack(children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _orange, width: 3),
                        boxShadow: [BoxShadow(
                          color: _orange.withOpacity(0.22),
                          blurRadius: 18, offset: const Offset(0, 6),
                        )],
                      ),
                      child: CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xffFFEDD8),
                        backgroundImage: u.avatar_url.isNotEmpty
                            ? NetworkImage('${ApiService.baseUrl}${u.avatar_url}')
                            : null,
                        child: u.avatar_url.isEmpty
                            ? const Icon(Icons.person_rounded, size: 52, color: _orange)
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 2, right: 2,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: _orange, shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  Text(u.fullName, style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _textDark)),
                  const SizedBox(height: 3),
                  Text('@${u.username}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                ]),
              ),
            ),

            // ── Разделитель ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: Colors.brown.withOpacity(0.12), thickness: 1),
            ),
            const SizedBox(height: 10),

            // ── Поля профиля ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: [
                _field('ФИО',               Icons.person_outline_rounded, _nameCtrl,    'name'),
                _field('Дата рождения',     Icons.cake_outlined,          _birthCtrl,   'birth'),
                _field('Пол',               Icons.wc_rounded,             _genderCtrl,  'gender'),
                _field('Email',             Icons.email_outlined,         _emailCtrl,   'email'),
                _field('Телефон',           Icons.phone_outlined,         _phoneCtrl,   'phone'),
                _field('Адрес проживания',  Icons.home_outlined,          _addressCtrl, 'address'),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Выход из аккаунта ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (_) => false),
                icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                label: const Text('Выйти из аккаунта',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: BorderSide(color: Colors.red.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(
      String label, IconData icon,
      TextEditingController ctrl, String key,
      ) {
    final editing = _editing.contains(key);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(
          fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
      const SizedBox(height: 6),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(icon, size: 18, color: _orange),
        const SizedBox(width: 10),
        Expanded(
          child: editing
              ? TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(fontSize: 14, color: _textDark),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          )
              : Text(
            ctrl.text.isEmpty ? '—' : ctrl.text,
            style: const TextStyle(fontSize: 14, color: _textDark),
          ),
        ),
        // Edit / Confirm button
        GestureDetector(
          onTap: () => setState(() {
            editing ? _editing.remove(key) : _editing.add(key);
          }),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              editing ? Icons.check_circle_outline_rounded : Icons.edit_outlined,
              size: 18,
              color: editing ? Colors.green.shade500 : Colors.grey.shade400,
            ),
          ),
        ),
      ]),
      Divider(color: Colors.brown.withOpacity(0.10), thickness: 1, height: 18),
    ]);
  }
}
