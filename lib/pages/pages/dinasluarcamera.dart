import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:face_net_authentication/constants/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../models/user.model.dart';

class DinasLuarCameraPage extends StatefulWidget {
  DinasLuarCameraPage({Key? key, required this.user, this.imagepath})
      : super(key: key);
  final User user;
  String? imagepath;

  @override
  _DinasLuarCameraPageState createState() => _DinasLuarCameraPageState();
}

void main() {
  // Add this line before making the network request
  HttpOverrides.global = MyHttpOverrides();
  // ...
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

class _DinasLuarCameraPageState extends State<DinasLuarCameraPage> {
  File? _pdfFile;
  File? _imageFile;
  String _taskNumber = '';
  String _nip = '';
  String _serverTime = '';

  Future<void> _pickPdf() async {
    final pdfFile = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (pdfFile != null) {
      setState(() {
        _pdfFile = File(pdfFile.files.single.path!);
      });
    }
  }

  Future<void> _takePicture() async {
    final imageFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (imageFile != null) {
      setState(() {
        _imageFile = File(imageFile.path);
      });
    }
  }

  _uploadDocument() async {
    final serverTime = DateTime.now().toString();
    setState(() {
      _serverTime = serverTime;
    });
    if (_pdfFile != null && _imageFile != null) {
      // Simulate backend request to get server time
      // Replace this with your actual backend call to get server time
      // await Future.delayed(Duration(seconds: 2));

      // var url = Uri.parse(Constants.BASEURL + Constants.UPLOADDINAS);
      // var request = http.MultipartRequest('POST', url)
      //   ..fields['no_tugas'] = _taskNumber
      //   ..fields['nip'] = _nip
      //   ..fields['waktu'] = _serverTime
      //   ..files.add(http.MultipartFile(
      //     'pdf_document',
      //     _pdfFile!.readAsBytes().asStream(),
      //     _pdfFile!.lengthSync(),
      //     filename: _pdfFile!.path.split('/').last,
      //   ))
      //   ..files.add(http.MultipartFile(
      //     'image_document',
      //     _imageFile!.readAsBytes().asStream(),
      //     _imageFile!.lengthSync(),
      //     filename: _imageFile!.path.split('/').last,
      //   ));

      // var response = await request.send();
      // if (response.statusCode == 200) {
      //   // File successfully uploaded
      //   print('Document uploaded successfully');
      // } else {
      //   // Error uploading file
      //   print('Failed to upload document');
      // }

      try {
        var url = Uri.parse(Constants.BASEURL + Constants.UPLOADDINAS);
        var request = http.MultipartRequest('POST', url)
          ..fields['no_tugas'] = _taskNumber
          ..fields['nip'] = _nip
          ..fields['waktu'] = _serverTime
          ..files.add(http.MultipartFile(
            'pdf_document',
            _pdfFile!.readAsBytes().asStream(),
            _pdfFile!.lengthSync(),
            filename: _pdfFile!.path.split('/').last,
          ))
          ..files.add(http.MultipartFile(
            'image_document',
            _imageFile!.readAsBytes().asStream(),
            _imageFile!.lengthSync(),
            filename: _imageFile!.path.split('/').last,
          ));
        // Tambahkan data atau file yang ingin diunggah
        // request.files.add(http.MultipartFile.fromBytes('file', await File('path/to/file').readAsBytes(), filename: 'filename.jpg'));

        final response = await request
            .send()
            .timeout(Duration(seconds: 90)); // Atur waktu habis (timeout)

        if (response.statusCode == 200) {
          // Tanggapi respons jika berhasil
          print('Data berhasil diunggah');
          Navigator.pop(context);
        } else {
          // Tanggapi kesalahan jika ada
          print('Gagal mengunggah data. Kode status: ${response.statusCode}');
        }
      } on SocketException catch (e) {
        // Tangani kesalahan koneksi
        print('Terjadi kesalahan koneksi: $e');
      } on TimeoutException catch (e) {
        // Tangani kesalahan waktu habis (timeout)
        print('Waktu habis saat mengirim permintaan: $e');
      } catch (e) {
        // Tangani kesalahan umum
        print('Terjadi kesalahan: $e');
      }
    } else {
      // No PDF file or image selected
      print('Please select PDF and image');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _takePicture();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Upload Document'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickPdf,
              child: Text('Pick PDF'),
            ),
            _pdfFile != null
                ? Text(_pdfFile!.path.split('/').last)
                : SizedBox(height: 20.0),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _takePicture,
              child: Text('Take Picture'),
            ),
            _imageFile != null
                ? Image.file(
                    _imageFile!,
                    height: 200.0,
                    fit: BoxFit.cover,
                  )
                : SizedBox(height: 200.0),
            SizedBox(height: 20.0),
            TextField(
              onChanged: (value) {
                setState(() {
                  _taskNumber = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Task Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.0),
            TextField(
              onChanged: (value) {
                setState(() {
                  _nip = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'NIP',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10.0),
            Text('Server Time: $_serverTime'),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: _uploadDocument,
              child: Text('Upload Document'),
            ),
          ],
        ),
      ),
    );
  }
}
