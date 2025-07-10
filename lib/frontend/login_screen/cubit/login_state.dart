part of 'login_cubit.dart';

class LoginState extends Equatable {

  final String email;
  final String password;
  final String errorMessage;

  const LoginState({required this.email, required this.password, required this.errorMessage});

  @override
  List<Object?> get props => [email, password, errorMessage];

  LoginState copyWith({
    String? email,
    String? password,
    String? errorMessage
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
