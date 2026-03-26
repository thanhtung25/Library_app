import 'package:bloc/bloc.dart';
import 'package:library_app/api_localhost/AuthService.dart';
import 'event.dart';
import 'state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(AuthInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
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
}
