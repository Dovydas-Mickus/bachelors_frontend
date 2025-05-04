// lib/core/repositories/models/user.dart

import 'package:flutter/foundation.dart';

class User {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String role;
  final bool? isLead; // Nullable: only present when coming from a team endpoint

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.role,
    this.isLead,
  });

  /// Creates a User instance from a JSON map.
  factory User.fromJson(Map<String, dynamic> json) {
    debugPrint("➤ [User.fromJson] Parsing user: ${json['email'] ?? 'No Email'}");

    if (json['id'] == null ||
        json['first_name'] == null ||
        json['last_name'] == null ||
        json['email'] == null ||
        json['role'] == null) {
      debugPrint("  ✖️ [User.fromJson] Missing fields in JSON: $json");
      throw FormatException("Missing required user fields in JSON: $json");
    }

    try {
      final user = User(
        id: json['id'] as String,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        isLead: json['is_lead'] as bool?,
      );
      debugPrint("  ✔️ [User.fromJson] Parsed successfully: ${user.email}");
      return user;
    } catch (e) {
      debugPrint("  ✖️ [User.fromJson] Error parsing User JSON: $json\n       $e");
      rethrow;
    }
  }

  /// Converts a User instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'role': role,
      if (isLead != null) 'is_lead': isLead,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, firstName: $firstName, lastName: $lastName, email: $email, role: $role, isLead: $isLead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.role == role &&
        other.isLead == isLead;
  }

  @override
  int get hashCode => Object.hash(
    id,
    firstName,
    lastName,
    email,
    role,
    isLead,
  );
}

/// Display helpers for User
extension UserDisplay on User {
  /// “JD” from “John Doe”, or first letter of email if no name parts
  String get initials {
    final fn = firstName.trim();
    final ln = lastName.trim();
    if (fn.isNotEmpty && ln.isNotEmpty) {
      return '${fn[0]}${ln[0]}'.toUpperCase();
    }
    return email.isNotEmpty ? email[0].toUpperCase() : '';
  }

  /// “John Doe” or fallback to email
  String get displayName {
    final parts = <String>[];
    if (firstName.trim().isNotEmpty) parts.add(firstName.trim());
    if (lastName.trim().isNotEmpty) parts.add(lastName.trim());
    return parts.isNotEmpty ? parts.join(' ') : email;
  }
}
