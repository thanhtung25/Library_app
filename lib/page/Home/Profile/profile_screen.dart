import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:library_app/bloc/auth/bloc.dart';
import 'package:library_app/bloc/auth/event.dart';
import 'package:library_app/localization/app_localizations.dart';
import 'package:library_app/localization/locale_controller.dart';
import 'package:library_app/model/user_model.dart';
import '../../../Router/AppRoutes.dart';
import '../../../api_localhost/ApiService.dart';
import '../../../api_localhost/AuthService.dart';
import '../../../bloc/auth/state.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _orange = Color(0xffFF9E74);
  static const Color _bg = Color(0xffF8EDE3);
  static const Color _textDark = Color(0xff3D2314);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _birthCtrl;
  late final TextEditingController _genderCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;

  final Set<String> _editing = {};

  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();


  String? _localAvatarUrl;
  bool _avatarUploading = false;


  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _nameCtrl = TextEditingController(text: u.fullName);
    _birthCtrl = TextEditingController(text: _fmt(u.birth_day));
    _genderCtrl = TextEditingController(text: u.gender);
    _emailCtrl = TextEditingController(text: u.email);
    _phoneCtrl = TextEditingController(text: u.phone);
    _addressCtrl = TextEditingController(text: u.address);
    _localAvatarUrl = u.avatar_url;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _birthCtrl.dispose();
    _genderCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}'
        '.${dt.month.toString().padLeft(2, '0')}'
        '.${dt.year}';
  }

  String? _toApiDate(String value) {
    if (value.trim().isEmpty) return null;

    try {
      final parts = value.split('.');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
      return value;
    } catch (_) {
      return null;
    }
  }

  void _updateProfile() {
    final u = widget.user;

    context.read<AuthBloc>().add(
      UserUpdateSubmittedEvent(
        id_user: u.id_user,
        fullName: _nameCtrl.text.trim(),
        username: u.username,
        password: u.password ?? '',
        role: u.role,
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        gender: _genderCtrl.text.trim(),
        birthDay: _toApiDate(_birthCtrl.text.trim()),
        phone: _phoneCtrl.text.trim(),
        status: u.status,
        createdAt: u.created_at?.toIso8601String(),
        libraryCard: u.library_card ?? '',
        address: _addressCtrl.text.trim(),
        avatarUrl: u.avatar_url,
      ),
    );
  }

  Future<void> _pickBirthDate() async {
    DateTime initialDate = DateTime(2000);

    final current = _birthCtrl.text.trim();
    if (current.isNotEmpty) {
      try {
        final parts = current.split('.');
        if (parts.length == 3) {
          initialDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      } catch (_) {}
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _birthCtrl.text = _fmt(picked);
      });
      _updateProfile();
    }
  }

  String? _normalizeGender(String? value) {
    if (value == null) return null;

    final v = value.trim().toLowerCase();

    if (v.isEmpty) return null;

    if (v == 'male' || v == 'nam' || v == 'мужской' || v == 'm') {
      return 'male';
    }

    if (v == 'female' || v == 'nữ' || v == 'nu' || v == 'женский' || v == 'f') {
      return 'female';
    }

    return null;
  }

  Widget _genderField() {
    final genderValue = _normalizeGender(_genderCtrl.text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('profile.gender'),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.wc_rounded, size: 18, color: _orange),
            const SizedBox(width: 10),
            Expanded(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: genderValue,
                  hint: Text(
                    context.tr('person_info.select_gender'),
                    style: const TextStyle(fontSize: 14, color: _textDark),
                  ),
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'male',
                      child: Text('Male'),
                    ),
                    DropdownMenuItem(
                      value: 'female',
                      child: Text('Female'),
                    ),
                  ],
                  selectedItemBuilder: (context) {
                    return ['male', 'female'].map((gender) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          context.l10n.genderName(gender),
                          style: const TextStyle(fontSize: 14, color: _textDark),
                        ),
                      );
                    }).toList();
                  },
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _genderCtrl.text = value;
                    });
                    _updateProfile();
                  },
                ),
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.brown.withOpacity(0.10),
          thickness: 1,
          height: 18,
        ),
      ],
    );
  }

  Widget _birthField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('profile.birth_date'),
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _pickBirthDate,
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, size: 18, color: _orange),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _birthCtrl.text.isEmpty
                      ? context.tr('common.empty_value')
                      : _birthCtrl.text,
                  style: const TextStyle(fontSize: 14, color: _textDark),
                ),
              ),
              Icon(
                Icons.calendar_month_rounded,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
        Divider(
          color: Colors.brown.withOpacity(0.10),
          thickness: 1,
          height: 18,
        ),
      ],
    );
  }


  Future<void> pickAndUploadAvatar(int id_user) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      context.read<AuthBloc>().add(
        UploadAvatarSubmitted(
          id_user: id_user,
          imageFile: file,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi chọn ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final currentLanguageCode = localeController.locale.languageCode;
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UploadAvatarLoading) {
          setState(() {
            _avatarUploading = true;
          });
        } else if (state is AvatarUploadSuccess) {
          setState(() {
            _avatarUploading = false;
            _localAvatarUrl = state.user.avatar_url;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tải ảnh đại diện thành công')),
          );
        } else if (state is UserUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('profile.update_success'))),
          );
        } else if (state is AuthError) {
          setState(() {
            _avatarUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
  child: Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Выбор языка ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    PopupMenuButton<String>(
                      initialValue: currentLanguageCode,
                      onSelected: (value) {
                        localeController.setLanguageCode(value);
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'ru',
                          child: Text(context.l10n.languageName('ru')),
                        ),
                        PopupMenuItem(
                          value: 'vi',
                          child: Text(context.l10n.languageName('vi')),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.brown.withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.language_rounded,
                              size: 14,
                              color: _orange,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              context.l10n.languageName(currentLanguageCode),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _textDark,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.arrow_drop_down_rounded,
                              size: 18,
                              color: _orange,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Аватар + имя ───────────────────────────
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 22),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: _orange, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: _orange.withOpacity(0.22),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 54,
                              backgroundColor: const Color(0xffFFEDD8),
                              backgroundImage: (_localAvatarUrl != null && _localAvatarUrl!.isNotEmpty)
                                  ? NetworkImage('${ApiService.baseUrl}$_localAvatarUrl')
                                  : null,
                              child: (_localAvatarUrl == null || _localAvatarUrl!.isEmpty)
                                  ? const Icon(
                                Icons.person_rounded,
                                size: 52,
                                color: _orange,
                              )
                                  : null,
                            ),
                          ),
                          if (_avatarUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.25),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(color: Colors.white),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => pickAndUploadAvatar(u.id_user),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: _orange,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        u.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Разделитель ────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: Colors.brown.withOpacity(0.12),
                  thickness: 1,
                ),
              ),
              const SizedBox(height: 10),

              // ── Поля профиля ───────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _field(
                      context.tr('profile.full_name'),
                      Icons.person_outline_rounded,
                      _nameCtrl,
                      'name',
                    ),
                    _birthField(),
                    _genderField(),
                    _field(
                      context.tr('profile.email'),
                      Icons.email_outlined,
                      _emailCtrl,
                      'email',
                    ),
                    _field(
                      context.tr('profile.phone'),
                      Icons.phone_outlined,
                      _phoneCtrl,
                      'phone',
                    ),
                    _field(
                      context.tr('profile.address'),
                      Icons.home_outlined,
                      _addressCtrl,
                      'address',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Выход из аккаунта ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (_) => false,
                  ),
                  icon: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: Text(
                    context.tr('profile.logout'),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: Colors.red.shade400, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
);
  }

  Widget _field(
      String label,
      IconData icon,
      TextEditingController ctrl,
      String key,
      ) {
    final editing = _editing.contains(key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
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
                ctrl.text.isEmpty
                    ? context.tr('common.empty_value')
                    : _displayFieldValue(key, ctrl.text),
                style: const TextStyle(fontSize: 14, color: _textDark),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (editing) {
                  setState(() {
                    _editing.remove(key);
                  });
                  _updateProfile();
                } else {
                  setState(() {
                    _editing.add(key);
                  });
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  editing
                      ? Icons.check_circle_outline_rounded
                      : Icons.edit_outlined,
                  size: 18,
                  color: editing ? Colors.green.shade500 : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
        Divider(
          color: Colors.brown.withOpacity(0.10),
          thickness: 1,
          height: 18,
        ),
      ],
    );
  }
  String _displayFieldValue(String key, String value) {
    if (key == 'gender') {
      return context.l10n.genderName(value);
    }
    return value;
  }
}
