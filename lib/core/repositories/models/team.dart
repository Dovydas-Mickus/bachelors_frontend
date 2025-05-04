import 'package:collection/collection.dart';
import 'package:flutter/material.dart'; // Using material for debugPrint consistency
import 'package:micki_nas/core/repositories/models/user.dart'; // Import User model

class Team {
  final String id; // Changed from _id to id for consistency within Dart model
  final String name;
  final User? lead;         // The lead user object (can be null)
  final List<User> members; // List of non-lead user objects

  Team({
    required this.id,
    required this.name,
    this.lead,
    required this.members,
  });

  // --- Factory Constructor 1: Parses structure with separate 'lead' and 'members' keys ---
  // Expects JSON like: { "_id": "...", "name": "...", "lead": {...}, "members": [...] }
  factory Team.fromJson(Map<String, dynamic> json) {
    // --- LOOK FOR 'id' (no underscore) ---
    final String? teamIdFromJson = json['id'] as String?; // <<< Ensure this looks for 'id'
    final String? teamNameFromJson = json['name'] as String?;
    // --- END CHANGE ---

    final String logId = teamIdFromJson ?? 'UNKNOWN_ID';
    debugPrint("--- [Team.fromJson] Parsing Team: $logId ---");

    // --- Check the variables populated from 'id' and 'name' ---
    if (teamIdFromJson == null || teamNameFromJson == null) {
      debugPrint("   [Team.fromJson] ❌ Missing required fields 'id' or 'name'. JSON: $json");
      throw FormatException("Missing required team fields 'id' or 'name' in JSON: $json");
    }
    // --- END CHECK ---

    User? parsedLead;
    if (json['lead'] != null && json['lead'] is Map<String, dynamic>) {
      try {
        parsedLead = User.fromJson(json['lead'] as Map<String, dynamic>);
      } catch (e, stackTrace) {
        debugPrint("   [Team.fromJson] ❌ ERROR parsing lead user for team $logId. JSON: ${json['lead']} Error: $e\n$stackTrace");
      }
    } else if (json.containsKey('lead')) {
      debugPrint("   [Team.fromJson] Field 'lead' exists but is null or not a map for team $logId.");
    }

    List<User> parsedMembers = [];
    if (json['members'] != null && json['members'] is List) {
      parsedMembers = (json['members'] as List)
          .map((memberJson) {
        if (memberJson is Map<String, dynamic>) {
          try {
            return User.fromJson(memberJson);
          } catch (e, stackTrace) {
            debugPrint("   [Team.fromJson] ❌ ERROR parsing member user for team $logId. JSON: $memberJson Error: $e\n$stackTrace");
            return null;
          }
        } else {
          debugPrint("   [Team.fromJson] ⚠️ WARNING: Unexpected item type in team members list for team $logId: $memberJson");
          return null;
        }
      })
          .whereNotNull()
          .toList();
    } else if (json.containsKey('members')) {
      debugPrint("   [Team.fromJson] Field 'members' exists but is null or not a list for team $logId.");
    }

    debugPrint("--- [Team.fromJson] Finished Parsing Team $logId. Lead: ${parsedLead?.email ?? 'None'}. Members: ${parsedMembers.length} ---");

    return Team(
      // --- Use the variables populated from 'id' and 'name' ---
      id: teamIdFromJson,   // Assign the value from 'id' key in JSON
      name: teamNameFromJson, // Assign the value from 'name' key in JSON
      // --- END CHANGE ---
      lead: parsedLead,
      members: parsedMembers,
    );
  }


  // --- Factory Constructor 2: Parses structure with single 'users' list ---
  // Expects JSON like: { "_id": "...", "name": "...", "users": [ {..., "is_lead": true/false}, ... ] }
  factory Team.fromJsonGetAllTeams(Map<String, dynamic> json) {
    // --- Use '_id' from JSON, assign to 'id' field in Dart ---
    final String? teamIdFromJson = json['_id'] as String?;
    final String? teamNameFromJson = json['name'] as String?;
    final List<dynamic>? usersListJson = json['users'] as List?;
    // --- End Change ---

    final String logId = teamIdFromJson ?? 'UNKNOWN_ID';
    debugPrint("--- [Team.fromJsonGetAllTeams] Parsing Team: $logId ---");

    // --- Check using the variables holding JSON values ---
    if (teamIdFromJson == null || teamNameFromJson == null || usersListJson == null) {
      debugPrint("   [Team.fromJsonGetAllTeams] ❌ Invalid JSON structure for Team $logId: Missing fields '_id', 'name', or 'users' is not a List.");
      throw FormatException("Invalid JSON structure for Team.fromJsonGetAllTeams: $json");
    }
    // --- End Check ---

    User? foundLead;
    List<User> foundMembers = [];

    for (var userJson in usersListJson) {
      if (userJson is Map<String, dynamic>) {
        final userEmailForLog = userJson['email'] ?? 'No Email';
        try {
          // Assume User.fromJson is robust
          final user = User.fromJson(userJson);
          final isLeadValue = userJson['is_lead']; // Key from backend JSON

          if (isLeadValue == true) { // Strict boolean check
            if (foundLead != null) {
              // Log if multiple leads are flagged (potential data issue)
              debugPrint("       ⚠️ WARNING: Multiple leads flagged in 'users' list for team $logId! Using last one found: $userEmailForLog.");
            }
            foundLead = user;
          } else {
            // Add to members list if not the lead
            foundMembers.add(user);
          }

        } catch (e, stackTrace) {
          // Log error if User.fromJson fails for an entry
          debugPrint("     [Team.fromJsonGetAllTeams] ❌ ERROR parsing user '$userEmailForLog' inside User.fromJson for team $logId: $e\n$stackTrace");
        }
      } else {
        debugPrint("     [Team.fromJsonGetAllTeams] ⚠️ WARNING: Non-map item in users list for team $logId: $userJson");
      }
    }

    // Defensive check: Ensure lead isn't accidentally in members list if logic above had issues
    if (foundLead != null) {
      foundMembers.removeWhere((member) => member.id == foundLead!.id);
    }

    debugPrint("--- [Team.fromJsonGetAllTeams] Finished Parsing Team $logId. Lead: ${foundLead?.email ?? 'None'}. Final Member Count: ${foundMembers.length} ---");

    return Team(
      // --- Use the variables holding extracted JSON values ---
      id: teamIdFromJson,   // Assign the value from _id
      name: teamNameFromJson, // Assign the value from name
      // --- End Change ---
      lead: foundLead,
      members: foundMembers,
    );
  } // --- End of factory Team.fromJsonGetAllTeams ---


  /// Converts a Team instance to a JSON map (primarily for debugging or sending data back).
  /// Note: Uses 'id', not '_id'. Adjust if sending back to CouchDB directly.
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Use the Dart field name 'id'
      'name': name,
      'lead': lead?.toJson(), // Assumes User has toJson()
      'members': members.map((user) => user.toJson()).toList(), // Assumes User has toJson()
    };
  }


  // Optional: toString for easy debugging
  @override
  String toString() {
    return 'Team(id: $id, name: $name, lead: ${lead?.email ?? 'None'}, members: ${members.length})';
  }

  // Optional: Equality operators using collection package for list comparison
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is Team &&
        other.id == id &&
        other.name == name &&
        other.lead == lead && // Uses User's ==
        listEquals(other.members, members); // Deep equality check for list
  }

  @override
  int get hashCode {
    final listHash = const DeepCollectionEquality().hash;
    return id.hashCode ^
    name.hashCode ^
    lead.hashCode ^ // Uses User's hashCode
    listHash(members); // Deep hash for list
  }
} // --- End of class Team ---