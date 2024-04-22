import 'dart:async';
import 'dart:math';
import 'package:face_net_authentication/constants/colors.dart';
import 'package:face_net_authentication/pages/widgets/face_preview.dart';
import 'package:flutter/material.dart';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/pages/widgets/auth_button.dart';
import 'package:face_net_authentication/pages/widgets/camera_detection_preview.dart';
import 'package:face_net_authentication/pages/widgets/camera_header.dart';
import 'package:face_net_authentication/pages/widgets/presensiin_form.dart';
import 'package:face_net_authentication/pages/widgets/single_picture.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'package:face_net_authentication/services/ml_service.dart';
import 'package:face_net_authentication/services/face_detector_service.dart';
import 'package:camera/camera.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import 'widgets/face_preview.dart';

class PresensiIn extends StatefulWidget {
  const PresensiIn({Key? key}) : super(key: key);

  @override
  PresensiInState createState() => PresensiInState();
}

class PresensiInState extends State<PresensiIn> {
  CameraService _cameraService = locator<CameraService>();
  FaceDetectorService _faceDetectorService = locator<FaceDetectorService>();
  MLService _mlService = locator<MLService>();

  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isPictureTaken = false;
  bool _isInitializing = false;
  bool _isTakingPicture = false; // Added
  bool cekwajah = true;
  String? wajah;
  @override
  void initState() {
    super.initState();
    getPref();
    _start();
  }

  getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    wajah = prefs.getString('gambarwajah');
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
    setState(() => _isInitializing = false);
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
    await _faceDetectorService.detectFacesFromImage(image!);
    if (_faceDetectorService.faceDetected) {
      _mlService.setCurrentPrediction(image, _faceDetectorService.faces[0]);
      // Panggil takePictureAutomatically() setiap kali wajah terdeteksi.
      await takePictureAutomatically();
    }
    if (mounted) setState(() {});
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
          .showBottomSheet((context) => presensiInSheet(user: user));
      bottomSheetController.closed.whenComplete(_reload);
    }
  }

  Future<void> takePictureAutomatically() async {
    setState(() => _isTakingPicture = true); // Added
    if (_faceDetectorService.faceDetected) {
      await takePicture();
      User? user = await _mlService.predict();
      // Evaluasi ekspresi dan cetak hasil
      double randomNumber = Random().nextDouble();
      bool result = randomNumber > 0.1;
      print("Nilai Random(): $randomNumber");
      print("Hasil evaluasi Random().nextDouble() > 0.1: $result");
      // Menggunakan hasil evaluasi untuk menentukan tindakan selanjutnya
      if (result) {
        if (user != null) {
          var bottomSheetController = scaffoldKey.currentState!
              .showBottomSheet((context) => presensiInSheet(user: user));
          bottomSheetController.closed.whenComplete(_reload);
        } else {
          _start(); // Mulai kembali deteksi wajah
        }
      } else {
        _start(); // Mulai kembali deteksi wajah
      }
    }
    setState(() => _isTakingPicture = false); // Added
  }

  Widget getBodyWidget() {
    if (_isInitializing) return Center(child: CircularProgressIndicator());
    if (_isPictureTaken && _cameraService.imagePath != null)
      return SinglePicture(imagePath: _cameraService.imagePath!);
    if (wajah != null) {
      setState(() {
        cekwajah = false;
      });
      return FacePreview();
    }

    return CameraDetectionPreview();
  }

  @override
  Widget build(BuildContext context) {
    Widget header = CameraHeader(cekwajah == true ? "Preview Wajah" : "PRESENSI MASUK",
        onBackPressed: _onBackPressed);
    Widget body = getBodyWidget();
    Widget? fab;
    // if (!_isPictureTaken) fab = AuthButton(onTap: onTap);

    return Scaffold(
      key: scaffoldKey,
      body: ModalProgressHUD(
        inAsyncCall: _isTakingPicture, // Added
        progressIndicator: CircularProgressIndicator(
          color: primaryColor,
        ), // Added
        child: Stack(
          children: [body, header],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: fab,
    );
  }

  presensiInSheet({@required User? user}) => user == null
      ? Container(
          width: MediaQuery.of(context).size.width,
          padding: EdgeInsets.all(20),
          child: Text(
            'User Tidak Ditemukan',
            style: TextStyle(fontSize: 20),
          ),
        )
      : PresensiInSheet(user: user);
}
