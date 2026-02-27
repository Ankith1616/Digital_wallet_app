import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload profile image and return the download URL
  Future<String?> uploadProfileImage(
    String uid, {
    File? file,
    Uint8List? bytes,
  }) async {
    try {
      final ref = _storage.ref().child('users').child(uid).child('profile.jpg');

      if (kIsWeb && bytes != null) {
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else if (file != null) {
        await ref.putFile(file);
      } else {
        return null;
      }

      return await ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }
}

