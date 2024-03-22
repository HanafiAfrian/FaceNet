import 'dart:async';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/pages/widgets/auth_button.dart';
import 'package:face_net_authentication/pages/widgets/camera_detection_preview.dart';
import 'package:face_net_authentication/pages/widgets/camera_header.dart';
import 'package:face_net_authentication/pages/widgets/presensidinasluar_form.dart';
import 'package:face_net_authentication/pages/widgets/single_picture.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/services/face_detector_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'pages/dinasluar.dart';

class PresensiDinasluar extends StatefulWidget {
  const PresensiDinasluar({Key? key}) : super(key: key);

  @override
  PresensiDinasluarState createState() => PresensiDinasluarState();
}

class PresensiDinasluarState extends State<PresensiDinasluar> {
  CameraService _cameraService = locator<CameraService>();
  FaceDetectorService _faceDetectorService = locator<FaceDetectorService>();
  MLService _mlService = locator<MLService>();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isPictureTaken = false;
  bool _isInitializing = false;
  bool _isFaceDetectorInitialized = false; // Tambah variabel ini
  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _mlService.dispose();
    _faceDetectorService.dispose();
    super.dispose();
  }

  Future _start() async {
    setState(() => _isInitializing = true);
    await _cameraService.initialize();
    _faceDetectorService.initialize(); // Inisialisasi detektor wajah
    setState(() {
      _isInitializing = false;
      _isFaceDetectorInitialized =
          true; // Atur menjadi true setelah inisialisasi selesai
    });
    _frameFaces();
  }

  _frameFaces() async {
    bool processing = false;
    _cameraService.cameraController!
        .startImageStream((CameraImage image) async {
      if (processing) return; // prevents unnecessary overprocessing.
      processing = true;
      await _predictFacesFromImage(image: image);
      processing = false;
    });
  }

  Future<void> _predictFacesFromImage({@required CameraImage? image}) async {
    assert(image != null, 'Image is null');
    if (_isFaceDetectorInitialized) {
      // Periksa apakah detektor wajah sudah diinisialisasi
      await _faceDetectorService.detectFacesFromImage(image!);
      if (_faceDetectorService.faceDetected) {
        _mlService.setCurrentPrediction(image, _faceDetectorService.faces[0]);
      }
      if (mounted) setState(() {});
    } else {
      // Tambahkan penanganan ketika detektor wajah belum diinisialisasi.
      print('Face detector service is not initialized yet.');
    }
  }

  Future<void> takePicture() async {
    if (_faceDetectorService.faceDetected) {
      await _cameraService.takePicture();
      setState(() => _isPictureTaken = true);
    } else {
      showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(content: Text('No face detected!')));
    }
  }

  _onBackPressed() {
    Navigator.of(context).pop();
  }

  _reload() {
    if (mounted) setState(() => _isPictureTaken = false);
    _start();
  }

  Future<void> onTap() async {
    await takePicture();
    if (_faceDetectorService.faceDetected) {
      User? user = await _mlService.predict();
      var bottomSheetController = scaffoldKey.currentState!
          .showBottomSheet((context) => presensiDinasluarSheet(user: user));
      // print("user" + user!.nip);
      // print(
      //   "camerapath" + _cameraService.imagePath!,
      // );
      bottomSheetController.closed.whenComplete(_reload);
    }
  }

  Widget getBodyWidget() {
    if (_isInitializing) return Center(child: CircularProgressIndicator());
    if (_isPictureTaken)
      return SinglePicture(imagePath: _cameraService.imagePath!);
    return CameraDetectionPreview();
  }

  @override
  Widget build(BuildContext context) {
    Widget header = Flexible(
        child: CameraHeader("DINAS LUAR", onBackPressed: _onBackPressed));
    Widget body = SingleChildScrollView(child: getBodyWidget());
    Widget? fab;
    if (!_isPictureTaken) fab = AuthButton(onTap: onTap);

    return Scaffold(
      key: scaffoldKey,
      body: Stack(
        children: [body, header],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: fab,
    );
  }

  presensiDinasluarSheet({@required User? user}) => user == null
      ? Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(20),
          child: Text(
            'User Tidak Ditemukan',
            style: TextStyle(fontSize: 20),
          ),
        )
      : DinasLuarPage(
          user: user,
          imagepath: _cameraService.imagePath!,
        );
}
