part of 'user_cubit.dart';

class UserState extends Equatable {
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool isLoading; // Added to show progress *during* profile load
  final bool isLoaded;  // Indicates if data has been successfully loaded at least once
  final String? errorMessage; // Optional: For displaying errors

  const UserState({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    required this.isLoading, // Require in constructor
    required this.isLoaded,
    this.errorMessage,
  });

  // copyWith method
  UserState copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? role,
    bool? isLoading,
    bool? isLoaded,
    String? errorMessage,
    bool clearError = false, // Helper to clear error message easily
  }) {
    return UserState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      role: role ?? this.role,
      isLoading: isLoading ?? this.isLoading,
      isLoaded: isLoaded ?? this.isLoaded,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    firstName,
    lastName,
    email,
    role,
    isLoading,
    isLoaded,
    errorMessage,
  ];
}

