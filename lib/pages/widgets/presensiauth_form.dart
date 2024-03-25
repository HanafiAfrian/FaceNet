import 'package:face_net_authentication/constants/constants.dart';
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
// import 'package:trust_location/trust_location.dart';
import 'package:location_permissions/location_permissions.dart';

import '../main_screen.dart';

class PresensiAuthSheet extends StatefulWidget {
  PresensiAuthSheet({Key? key, required this.user}) : super(key: key);
  final User user;

  @override
  _PresensiAuthSheetState createState() => _PresensiAuthSheetState();
}

class _PresensiAuthSheetState extends State<PresensiAuthSheet> {
  final _passwordController = TextEditingController();
  final _cameraService = locator<CameraService>();
  String _latitude = "Loading...";
  String _longitude = "Loading...";
  bool _isMockLocation = false;
  late GoogleMapController mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    // getLocationPermissionsAndStart();
  }

  Future<void> getLocationPermissionsAndStart() async {
    await requestLocationPermission();
    // TrustLocation.start(5);
    getLocation();
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
    // try {
    //   TrustLocation.onChange.listen((values) {
    //     setState(() {
    //       _latitude = values.latitude?.toString() ?? "N/A";
    //       _longitude = values.longitude?.toString() ?? "N/A";
    //       _isMockLocation = values.isMockLocation ?? false;
    //       _currentLocation = LatLng(
    //         double.tryParse(_latitude) ?? 0.0,
    //         double.tryParse(_longitude) ?? 0.0,
    //       );
    //     });
    //   });
    // } on PlatformException catch (e) {
    //   print('PlatformException: $e');
    // } catch (e) {
    //   print('Error: $e');
    // }
  }

  Future<void> _presensiAuth(BuildContext context, User user) async {
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
    } else if (user.password == _passwordController.text) {
      try {
        final response = await http.post(
          Uri.parse(Constants.BASEURL + Constants.ABSENSIKELUAR),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'nip': user.nip,
            'nama': user.user,
            'jenis_absensi': 'Keluar',
            'latitude': _currentLocation?.latitude.toString() ?? '',
            'longitude': _currentLocation?.longitude.toString() ?? '',
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
                          imagePath: _cameraService.imagePath,
                          username: user.nip,
                        )));
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
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Wrong password!'),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                AppTextField(
                  controller: _passwordController,
                  labelText: "Password",
                  isPassword: true,
                ),
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
                      target: _currentLocation ?? LatLng(0, 0),
                      zoom: 15.0,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                AppButton(
                  text: 'LOGIN',
                  onPressed: () async {
                    await _presensiAuth(context, widget.user);
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
    );
  }
}
