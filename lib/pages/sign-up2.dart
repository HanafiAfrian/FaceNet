import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/widgets/FacePainter.dart';
import 'package:face_net_authentication/pages/widgets/auth-action-button.dart';
import 'package:face_net_authentication/pages/widgets/auth-action-button2.dart';
import 'package:face_net_authentication/pages/widgets/camera_header.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/services/face_detector_service.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toast/toast.dart';

import '../constants/constants.dart';

class SignUp2 extends StatefulWidget {
  String? nip, username, password, role;
  SignUp2({Key? key, this.nip, this.username, this.password, this.role})
      : super(key: key);

  @override
  SignUp2State createState() => SignUp2State();
}

class SignUp2State extends State<SignUp2> {
  String? imagePath;
  Face? faceDetected;
  Size? imageSize;

  bool _detectingFaces = false;
  bool pictureTaken = false;

  bool _initializing = false;

  bool _saving = false;
  bool _bottomSheetVisible = false;

  // service injection
  FaceDetectorService _faceDetectorService = locator<FaceDetectorService>();
  CameraService _cameraService = locator<CameraService>();
  MLService _mlService = locator<MLService>();
  FaceDetectorService _mlKitService = locator<FaceDetectorService>();
  bool _imageStreamInitialized = false;
  @override
  void initState() {
    super.initState();
    // _initializeServices();
    _start();
  }

  _initializeServices() async {
    await _cameraService.initialize();
    await _mlService.initialize();
    _mlKitService.initialize();
  }

  // @override
  // void dispose() {
  //   _cameraService.dispose();
  //   _mlService.dispose();
  //   _faceDetectorService.dispose();
  //   _cameraService.cameraController!.dispose();

  //   super.dispose();
  // }

  _start() async {
    setState(() => _initializing = true);
    await _cameraService.initialize();
    await _mlService.initialize();
    _mlKitService.initialize();
    setState(() => _initializing = false);

    _frameFaces();
  }

  Future<bool> onShot() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    if (faceDetected == null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('No face detected!'),
          );
        },
      );
      return false;
    } else {
      _saving = true;
      await Future.delayed(Duration(milliseconds: 500));

      // Ambil gambar dari kamera
      XFile? file = await _cameraService.takePicture();
      imagePath = file?.path;

      preferences.setString("gambarwajah", imagePath!);
      // Kirim gambar ke server
      bool uploadSuccess = await uploadImageToServer(imagePath!);

      if (uploadSuccess) {
        setState(() {
          _bottomSheetVisible = true;
          pictureTaken = true;
        });
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text('Failed to upload image to server.'),
            );
          },
        );
      }

      return uploadSuccess;
    }
  }

  Future<bool> uploadImageToServer(String imagePath) async {
    try {
      var uri = Uri.parse(Constants.BASEURL + Constants.REGISTER);
      var request = http.MultipartRequest('POST', uri);

      // Menambahkan file gambar ke permintaan multipart
      request.files
          .add(await http.MultipartFile.fromPath('user_image', imagePath));

      // Kirim permintaan
      var response = await request.send();

      // Periksa respons dari server
      if (response.statusCode == 200) {
        // print('Image uploaded successfully');
        // Toast.show("Selamat,anda berhasil Sign Up",
        //     duration: Toast.lengthShort, gravity: Toast.bottom);
        return true;
      } else {
        print('Failed to upload image. Status code: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error uploading image: $e');
      return false;
    }
  }

  _frameFaces() {
    imageSize = _cameraService.getImageSize();

    _cameraService.cameraController?.startImageStream((image) async {
      if (_cameraService.cameraController != null) {
        if (_detectingFaces) return;

        _detectingFaces = true;

        try {
          await _faceDetectorService.detectFacesFromImage(image);

          if (_faceDetectorService.faces.isNotEmpty) {
            setState(() {
              faceDetected = _faceDetectorService.faces[0];
            });
            if (_saving) {
              _mlService.setCurrentPrediction(image, faceDetected);
              setState(() {
                _saving = false;
              });
            }
          } else {
            print('face is null');
            setState(() {
              faceDetected = null;
            });
          }

          _detectingFaces = false;
        } catch (e) {
          print('Error _faceDetectorService face => $e');
          _detectingFaces = false;
        }
      }
    });
  }

  _onBackPressed() {
    Navigator.of(context).pop();
  }

  _reload() {
    setState(() {
      _bottomSheetVisible = false;
      pictureTaken = false;
    });
    this._start();
  }

  @override
  Widget build(BuildContext context) {
    final double mirror = math.pi;
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    late Widget body;
    if (_initializing) {
      body = Center(
        child: CircularProgressIndicator(),
      );
    } else if (!_initializing && pictureTaken && imagePath != null) {
      body = Container(
        width: width,
        height: height,
        child: Transform(
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.cover,
            child: Image.file(File(imagePath!)),
          ),
          transform: Matrix4.rotationY(mirror),
        ),
      );
    } else if (!_initializing && !pictureTaken) {
      body = Transform.scale(
        scale: 1.0,
        child: AspectRatio(
          aspectRatio: MediaQuery.of(context).size.aspectRatio,
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Container(
                width: width,
                height:
                    width * _cameraService.cameraController!.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    CameraPreview(_cameraService.cameraController!),
                    CustomPaint(
                      painter: FacePainter(
                          face: faceDetected, imageSize: imageSize!),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Default value if none of the conditions are met
      body = Container();
    }

    return Scaffold(
        body: Stack(
          children: [
            body,
            CameraHeader(
              "SIGN UP 2",
              onBackPressed: _onBackPressed,
            )
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: !_bottomSheetVisible
            ? AuthActionButton2(
                nip: widget.nip,
                username: widget.username,
                password: widget.password,
                role: widget.role,
                context: context,
                onPressed: onShot,
                isLogin: false,
                isAbsenmasuk: false,
                isAbsendinasluar: false,
                isAbsenkeluar: false,
                reload: _reload,
              )
            : Container());
  }
}
