import 'package:bloc/bloc.dart';
import 'package:library_app/api_localhost/AuthService.dart';
import 'event.dart';
import 'state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<UserUpdateSubmittedEvent>(_onUpdateSubmitted);
    on<UploadAvatarSubmitted>(_onUploadAvatarSubmitted);
  }
  Future<void> _onLoginSubmitted(
      LoginSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    final username = event.username.trim();
    final password = event.password.trim();
    if (username.isEmpty || password.isEmpty) {
      emit(AuthError('auth.error.login_empty'));
      return;
    }
    emit(AuthLoading());
    try {
      final response = await authService.login(username, password);

      if (response.user == null) {
        emit(AuthError('auth.error.invalid_credentials'));
        return;
      }

      emit(AuthSuccess(response.user!));
    } catch (e) {
      emit(AuthError('auth.error.invalid_credentials'));
    }
  }

  Future<void> _onRegisterSubmitted(
      RegisterSubmitted event,
      Emitter<AuthState> emit,
      )async {
    final username = event.username.trim();
    final password = event.password.trim();
    final email = event.email?.trim();
    final phone = event.phone.trim();
    final role = event.role.trim();
    final full_name = event.fullName.trim();
    final address = event.address.trim();
    final gender = event.gender.trim();
    final birthDay = event.birthDay?.trim();
    final status = event.status.trim();
    final createdAt = event.createdAt?.trim();
    final libraryCard = event.libraryCard.trim();
    final avatarUrl = event.avatarUrl.trim();

    if (full_name.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        role.isEmpty ||
        gender.isEmpty ||
        phone.isEmpty ||
        status.isEmpty ||
        libraryCard.isEmpty ||
        address.isEmpty) {
      emit(AuthError('auth.error.register_required'));
      return;
    }
    emit(AuthLoading());


    try {

      final user = await authService.register(
        fullName: event.fullName,
        username: event.username,
        password: event.password,
        role: event.role,
        email: event.email,
        gender: event.gender,
        birthDay: event.birthDay,
        phone: event.phone,
        status: event.status,
        createdAt: event.createdAt,
        libraryCard: event.libraryCard,
        address: event.address,
        avatarUrl: event.avatarUrl,
      );

      emit(AuthSuccess(user));

    } catch (e) {

      emit(AuthError(_mapRegisterError(e)));

    }
  }

  String _mapRegisterError(Object e) {

    final msg = e.toString().toLowerCase();

    if (msg.contains("username already exists")) {
      return 'auth.error.username_exists';
    }

    if (msg.contains("already exists")) {
      return 'auth.error.username_exists';
    }

    if (msg.contains("unique") || msg.contains("constraint")) {
      return 'auth.error.username_exists';
    }

    if (msg.contains("email")) {
      return 'auth.error.email_exists';
    }

    return 'auth.error.register_failed';
  }


  Future<void> _onUpdateSubmitted(
      UserUpdateSubmittedEvent event,
      Emitter<AuthState> emit,
      ) async {
    final id_user = event.id_user;
    final username = event.username.trim();
    final password = event.password.trim();
    final email = event.email?.trim();
    final phone = event.phone.trim();
    final role = event.role.trim();
    final fullName = event.fullName.trim();
    final address = event.address.trim();
    final gender = event.gender.trim();
    final birthDay = event.birthDay?.trim();
    final status = event.status.trim();
    final createdAt = event.createdAt?.trim();
    final libraryCard = event.libraryCard.trim();
    final avatarUrl = event.avatarUrl.trim();

    if (fullName.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        role.isEmpty ||
        gender.isEmpty ||
        phone.isEmpty ||
        status.isEmpty ||
        libraryCard.isEmpty ||
        address.isEmpty) {
      emit(AuthError('auth.error.register_required'));
      return;
    }

    emit(AuthLoading());

    try {
      final user = await authService.updateUserbyId(
        id_user: id_user,
        fullName: fullName,
        username: username,
        password: password,
        role: role,
        email: email,
        gender: gender,
        birthDay: birthDay,
        phone: phone,
        status: status,
        createdAt: createdAt,
        libraryCard: libraryCard,
        address: address,
        avatarUrl: avatarUrl,
      );

      emit(UserUpdateSuccess(user));
    } catch (e) {
      emit(AuthError(_mapUpdateError(e)));
    }
  }

  String _mapUpdateError(Object e) {
    final msg = e.toString().toLowerCase();

    if (msg.contains("username already exists")) {
      return 'auth.error.username_exists';
    }

    if (msg.contains("already exists")) {
      return 'auth.error.username_exists';
    }

    if (msg.contains("unique") || msg.contains("constraint")) {
      return 'auth.error.username_exists';
    }

    if (msg.contains("email")) {
      return 'auth.error.email_exists';
    }

    return 'auth.error.update_failed';
  }

  Future<void> _onUploadAvatarSubmitted(
      UploadAvatarSubmitted event,
      Emitter<AuthState> emit,
      ) async {
    emit(UploadAvatarLoading());

    try {
      final user = await authService.uploadAvatar(
        idUser: event.id_user,
        imageFile: event.imageFile,
      );

      emit(AvatarUploadSuccess(user));
    } catch (e) {
      emit(AuthError('Upload avatar failed: $e'));
    }
  }
}
