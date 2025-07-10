part of 'admin_cubit.dart';

class AdminState extends Equatable {
  final List<Team> teams;
  final List<User> users;
  final bool isLoading;

  const AdminState({
    required this.teams,
    required this.users,
    this.isLoading = false,
  });

  AdminState copyWith({
    List<Team>? teams,
    bool? isLoading,
    List<User>? users,
  }) {
    return AdminState(
      teams: teams ?? this.teams,
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
    );
  }

  @override
  List<Object?> get props => [teams, isLoading, users];
}


