// ignore_for_file: unused_import

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileService {
  static final ProfileService instance = ProfileService._();
  ProfileService._();

  final ValueNotifier<String?> imagePath = ValueNotifier<String?>(null);
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    imagePath.value = prefs.getString('profile_image_path');
    _loaded = true;
  }

  Future<void> setImageFromPicker(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (picked == null) return;

    // Copy to app directory to keep persistent access
    final bytes = await picked.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(bytes, flush: true);

    imagePath.value = file.path;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path', file.path);
  }
}

