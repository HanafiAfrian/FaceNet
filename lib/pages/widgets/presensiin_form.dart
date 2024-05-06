import 'package:face_net_authentication/pages/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/pages/profile.dart';
import 'package:face_net_authentication/pages/widgets/app_button.dart';
import 'package:face_net_authentication/pages/widgets/app_text_field.dart';
import 'package:face_net_authentication/services/camera.service.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:trust_location/trust_location.dart';
import 'package:location_permissions/location_permissions.dart';

import 'package:geolocator/geolocator.dart' as geoloc;
import '../../constants/constants.dart';

class PresensiInSheet extends StatefulWidget {
  PresensiInSheet({Key? key, required this.user}) : super(key: key);
  final User user;

  @override
  _PresensiInSheetState createState() => _PresensiInSheetState();
}

class _PresensiInSheetState extends State<PresensiInSheet> {
  final _cameraService = locator<CameraService>();
  String? _latitude;
  String? _longitude;
  bool _isMockLocation = false;
  late GoogleMapController mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _getLocation();
    getLocationPermissionsAndStart();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled;
    geoloc.LocationPermission permission;

    // Memeriksa apakah layanan lokasi diaktifkan
    serviceEnabled = await geoloc.Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showLocationServiceAlertDialog();
      return;
    }

    // Memeriksa izin lokasi
    permission = await geoloc.Geolocator.checkPermission();
    if (permission == geoloc.LocationPermission.deniedForever) {
      // Izin ditolak secara permanen, arahkan pengguna ke pengaturan
      _showPermissionDeniedDialog();
      return;
    }

    if (permission == geoloc.LocationPermission.denied) {
      // Izin tidak diberikan, minta izin
      permission = await geoloc.Geolocator.requestPermission();
      if (permission != geoloc.LocationPermission.whileInUse &&
          permission != geoloc.LocationPermission.always) {
        // Izin tidak diberikan oleh pengguna, keluar dari fungsi
        return;
      }
    }

    // Izin diberikan, dapatkan lokasi terbaru
    try {
      geoloc.Position position = await geoloc.Geolocator.getCurrentPosition(
          desiredAccuracy: geoloc.LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude.toString();
        _longitude = position.longitude.toString();
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Izin Lokasi Ditolak'),
          content: Text(
              'Izin lokasi telah ditolak secara permanen. Buka pengaturan aplikasi untuk mengaktifkannya.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showLocationServiceAlertDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Layanan Lokasi Tidak Aktif'),
          content: Text(
              'Layanan lokasi tidak diaktifkan pada perangkat Anda. Silakan aktifkan layanan lokasi.'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> getLocationPermissionsAndStart() async {
    await requestLocationPermission();
    TrustLocation.start(5);
    // getLocation();
  }

  Future<void> requestLocationPermission() async {
    PermissionStatus permission =
        await LocationPermissions().requestPermissions();
    print('Permissions: $permission');

    if (permission != PermissionStatus.granted) {
      showPermissionDeniedDialog();
    }
  }

  void showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Permission Required'),
          content: Text('Location permission is required for this app.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> getLocation() async {
    try {
      TrustLocation.onChange.listen((values) {
        setState(() {
          _isMockLocation = values.isMockLocation ?? false;
          _currentLocation = LatLng(
            double.parse(_latitude!),
            double.parse(_longitude!),
          );
        });
      });
    } on PlatformException catch (e) {
      print('PlatformException: $e');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _presensiIn(BuildContext context, User user) async {
    if (_isMockLocation) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Alamat Palsu'),
            content: Text('Maaf, alamat Anda terdeteksi sebagai lokasi palsu.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
    try {
      final response = await http.post(
        Uri.parse(Constants.BASEURL + Constants.ABSENSIMASUK),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'nip': user.nip,
          'nama': user.user,
          'jenis_absensi': 'Masuk',
          'latitude': _latitude.toString() ?? '',
          'longitude': _longitude.toString() ?? '',
        },
      );

      if (response.statusCode == 200) {
        final trimmedResponse = response.body.trim().toLowerCase();
        if (trimmedResponse == 'false') {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: Text('Anda berada di luar area presensi.'),
              );
            },
          );
        } else if (trimmedResponse == 'true') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (BuildContext context) => MainScreen(
                username: user.nip,
                imagePath: _cameraService.imagePath!,
              ),
            ),
          );
        } else {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: Text('Invalid server response.'),
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text('Failed to connect to the server.'),
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

  @override
  Widget build(BuildContext context) {
    return _latitude != null && _longitude != null
        ? Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Text(
                    'Selamat Datang, ' + widget.user.nip + '.',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Container(
                  child: Column(
                    children: [
                      SizedBox(height: 10),
                      Divider(),
                      SizedBox(height: 10),
                      Text('lokasi palsu $_isMockLocation'),
                      SizedBox(height: 10),
                      Text('Latitude: $_latitude, Longitude: $_longitude'),
                      SizedBox(height: 10),
                      Container(
                        height: 200,
                        child: GoogleMap(
                          onMapCreated: (GoogleMapController controller) {
                            mapController = controller;
                          },
                          initialCameraPosition: CameraPosition(
                            target: _currentLocation ??
                                LatLng(
                                    double.parse(_latitude ??
                                        "${_currentLocation?.latitude}"),
                                    double.parse(_longitude ??
                                        "${_currentLocation?.longitude}")),
                            zoom: 15.0,
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      AppButton(
                        text: 'LOGIN',
                        onPressed: () async {
                          await _presensiIn(context, widget.user);
                        },
                        icon: Icon(
                          Icons.login,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : Center(
            child: SingleChildScrollView(),
          );
  }
}
