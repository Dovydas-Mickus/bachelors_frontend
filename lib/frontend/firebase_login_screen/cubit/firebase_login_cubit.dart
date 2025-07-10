import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/repositories/authentication_repository.dart';

part 'firebase_login_state.dart';

class FirebaseLoginCubit extends Cubit<FirebaseLoginState> {

  final AuthenticationRepository authenticationRepository;

  FirebaseLoginCubit({required this.authenticationRepository}) : super(FirebaseLoginState(email: '', password: '', errorMessage: ''));

  void errorMessageChanged(String errorMessage) {
    emit(state.copyWith(errorMessage: errorMessage));
  }

  void emailChanged(String email) {
    emit(state.copyWith(email: email));
  }

  void passwordChanged(String password) {
    emit(state.copyWith(password: password));
  }

  Future<void> signInWithEmailAndPassword() async {
    try {
      await authenticationRepository.signInWithEmailAndPassword(email: state.email, password: state.password);
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }
}
