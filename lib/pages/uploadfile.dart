import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class UploadFile extends StatefulWidget {
  final String nip;

  UploadFile(this.nip);

  @override
  _UploadFileState createState() => _UploadFileState();
}

class _UploadFileState extends State<UploadFile> {
  final _fileController = TextEditingController();
  final _nomorSuratController = TextEditingController();
  File? _selectedFile;

  Future<void> _uploadFile(BuildContext context) async {
    try {
      if (_selectedFile == null) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text('Please select a file.'),
            );
          },
        );
        return;
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.18.12/presensi/upload_file.php'),
      );

      request.fields['nip'] = widget.nip;
      request.fields['nomor_surat'] = _nomorSuratController.text;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _selectedFile!.path,
        ),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        // File berhasil diunggah
        // Tambahkan logika atau tindakan yang diperlukan setelah pengunggahan file
        print('File uploaded successfully');
      } else {
        // Gagal mengunggah file
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                  'Failed to upload file. Status Code: ${response.statusCode}'),
            );
          },
        );
      }
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Error: $error'),
          );
        },
      );
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = File(result.files.first.path!);
          _fileController.text = _selectedFile!.path;
        });
      }
    } catch (error) {
      print('Error picking file: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload File'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('NIP: ${widget.nip}'),
            SizedBox(height: 20),
            TextField(
              controller: _nomorSuratController,
              decoration: InputDecoration(
                labelText: 'Nomor Surat Tugas',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _pickFile(),
              child: Text('Select File from Gallery'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _fileController,
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Selected File',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _uploadFile(context);
              },
              child: Text('Upload File'),
            ),
          ],
        ),
      ),
    );
  }
}
