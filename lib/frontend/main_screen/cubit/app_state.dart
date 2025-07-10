part of 'app_cubit.dart';

enum AppStatus {
  loading,
  loggedIn,
  loggedOut,
}

class AppState extends Equatable {

  final AppStatus appStatus;

  const AppState({required this.appStatus});

  @override
  List<Object?> get props => [appStatus];

  AppState copyWith({
    AppStatus? appStatus,
  }) {
    return AppState(
      appStatus: appStatus ?? this.appStatus,
    );
  }
}
