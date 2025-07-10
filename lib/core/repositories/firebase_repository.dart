
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseRepository {
  final CollectionReference profiles = FirebaseFirestore.instance.collection('profiles');
  final FirebaseStorage storage = FirebaseStorage.instance; // ✅ Add this line
  // CREATE
  Future<void> createProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      await FirebaseFirestore.instance.collection('profiles').doc(userId).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to create profile: $e');
    }
  }



  // READ
  Future<DocumentSnapshot> getProfile(String userId) async {
    try {
      return await profiles.doc(userId).get();
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  Future<DocumentSnapshot> fetchRandomWord() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('words')
        .get();

    if (snapshot.docs.isEmpty) throw Exception('No documents found');

    final randomIndex = Random().nextInt(snapshot.docs.length);
    return snapshot.docs[randomIndex];
  }

  // UPDATE
  Future<void> updateProfile(String userId, Map<String, dynamic> updatedData) async {
    try {
      await profiles.doc(userId).update(updatedData);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // DELETE
  Future<void> deleteProfile(String userId) async {
    try {
      await profiles.doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}
