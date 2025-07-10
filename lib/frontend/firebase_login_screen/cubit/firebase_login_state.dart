part of 'firebase_login_cubit.dart';

class FirebaseLoginState extends Equatable {

  final String errorMessage;
  final String email;
  final String password;

  const FirebaseLoginState({required this.errorMessage, required this.email, required this.password});


  @override
  List<Object?> get props => [errorMessage, email, password];

  FirebaseLoginState copyWith({
    String? email,
    String? password,
    String? errorMessage,
  }) {
    return FirebaseLoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

}

