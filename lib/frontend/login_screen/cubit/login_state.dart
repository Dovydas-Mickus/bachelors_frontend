part of 'login_cubit.dart';

class LoginState extends Equatable {

  final String email;
  final String password;

  const LoginState({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];

  LoginState copyWith({
    String? email,
    String? password,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
    );
  }
}
