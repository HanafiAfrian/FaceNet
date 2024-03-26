import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FacePreview extends StatelessWidget {
  const FacePreview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future<String?> getImagePath() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('gambarwajah');
    }

    return FutureBuilder<String?>(
      future: getImagePath(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Widget untuk menampilkan loading saat SharedPreferences sedang diambil
        } else if (snapshot.hasError) {
          return Text(
              'Error: ${snapshot.error}'); // Widget untuk menampilkan pesan error jika terjadi kesalahan saat mengambil SharedPreferences
        } else if (snapshot.hasData && snapshot.data != null) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                File(snapshot.data!),
                fit: BoxFit.cover,
              ),
            ),
          );
        } else {
          return Container(); // Placeholder widget jika imagePath null
        }
      },
    );
  }
}
