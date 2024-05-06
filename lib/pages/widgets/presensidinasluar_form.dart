import 'package:face_net_authentication/pages/uploadfile.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:face_net_authentication/locator.dart';
import 'package:face_net_authentication/pages/models/user.model.dart';
import 'package:face_net_authentication/pages/profile.dart';
import 'package:face_net_authentication/pages/widgets/app_button.dart';
import 'package:face_net_authentication/pages/widgets/app_text_field.dart';
import 'package:face_net_authentication/services/camera.service.dart';

import '../../constants/constants.dart';

class PresensiDinasluarSheet extends StatefulWidget {
  PresensiDinasluarSheet({Key? key, required this.user}) : super(key: key);
  final User user;

  @override
  _PresensiDinasluarSheetState createState() => _PresensiDinasluarSheetState();
}

class _PresensiDinasluarSheetState extends State<PresensiDinasluarSheet> {
  final _cameraService = locator<CameraService>();
  Location _locationController = Location();
  GoogleMapController? _mapController;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    getLocation();
  }

  Future<void> _presensiDinasluar(BuildContext context, User user) async {
    try {
      final response = await http.post(
        Uri.parse(Constants.BASEURL + Constants.ABSENSIMASUK),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'nip': user.nip,
          'nama': user.user,
          'jenis_absensi': 'Dinas Luar',
          'latitude': _currentLocation?.latitude.toString() ?? '',
          'longitude': _currentLocation?.longitude.toString() ?? '',
        },
      );

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (BuildContext context) => UploadFile(
              user.nip,
            ),
          ),
        );
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

  Future<void> getLocation() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged
        .listen((LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentLocation =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
        });

        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
                LatLng(currentLocation.latitude!, currentLocation.longitude!)),
          );
        }
      }
    });
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
                Divider(),
                SizedBox(height: 10),
                Text(
                  'Latitude: ${_currentLocation?.latitude ?? 'N/A'}',
                  style: TextStyle(fontSize: 16),
                ),
                Text(
                  'Longitude: ${_currentLocation?.longitude ?? 'N/A'}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 10),
                Container(
                  height: 200,
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    initialCameraPosition: CameraPosition(
                      target: _currentLocation ?? LatLng(0, 0),
                      zoom: 15.0,
                    ),
                    markers: {
                      Marker(
                        markerId: MarkerId('currentLocation'),
                        position: _currentLocation ?? LatLng(0, 0),
                        infoWindow: InfoWindow(title: 'Lokasi Saat Ini'),
                      ),
                    },
                  ),
                ),
                AppButton(
                  text: 'LOGIN',
                  onPressed: () async {
                    await _presensiDinasluar(context, widget.user);
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
