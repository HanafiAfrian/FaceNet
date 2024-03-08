import 'dart:convert';
import 'dart:io';
import 'dart:convert';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:face_net_authentication/pages/home.dart';
import 'package:face_net_authentication/pages/presensi-auth.dart';
import 'package:face_net_authentication/pages/presensi-dinasluar.dart';
import 'package:face_net_authentication/pages/presensi-in.dart';
import 'package:face_net_authentication/pages/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:trust_location/trust_location.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:url_launcher/url_launcher.dart';

class Profile extends StatefulWidget {
  const Profile(this.username, {Key? key, required this.imagePath})
      : super(key: key);

  final String username;
  final String imagePath;

  @override
  _ProfileState createState() => _ProfileState();
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

class _ProfileState extends State<Profile> {
  String _latitude = "Loading...";
  String _longitude = "Loading...";
  bool _isMockLocation = false;
  String serverResponse = "Loading...";

  bool _hasFetchedData = false;

  final String githubURL =
      "https://github.com/MCarlomagno/FaceRecognitionAuth/tree/master";

  @override
  void initState() {
    super.initState();
    getLocationPermissionsAndStart();
  }

  void _launchURL() async {
    await canLaunch(githubURL)
        ? await launch(githubURL)
        : throw 'Could not launch $githubURL';
  }

  Future<void> getLocationPermissionsAndStart() async {
    await requestLocationPermission();
    await TrustLocation.start(5);
    await Future.delayed(
        Duration(seconds: 5)); // Tunggu beberapa detik untuk mendapatkan lokasi
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
    try {
      TrustLocation.onChange.listen((values) {
        setState(() {
          _latitude = values.latitude?.toString() ?? "N/A";
          _longitude = values.longitude?.toString() ?? "N/A";
          _isMockLocation = values.isMockLocation ?? false;
        });
        if (_isMockLocation) {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text('Peringatan'),
                content:
                    Text('Maaf, alamat Anda terdeteksi sebagai lokasi palsu.'),
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
        // Setelah mendapatkan lokasi, panggil getDataFromServer
        getDataFromServer(widget.username, _latitude, _longitude);
      });
    } on PlatformException catch (e) {
      print('PlatformException: $e');
    } catch (e) {
      print('Error: $e');
    }
  }

  final String historiPresensiURL =
      "https://sisensio.unand.ac.id/presensi/historiabsensi.php";

  Future<List<Map<String, dynamic>>> fetchHistoriPresensiByUsername(
      String username) async {
    final Uri url = Uri.parse("$historiPresensiURL?username=$username");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Failed to load histori presensi');
    }
  }

  Future<void> getDataFromServer(
      String username, String latitude, String longitude) async {
    if (latitude.isEmpty || longitude.isEmpty) {
      // Penanganan ketika latitude atau longitude kosong
      setState(() {
        serverResponse = "Error: Latitude or longitude is empty";
      });
      return;
    }

    final Uri url = Uri.parse(
        "https://sisensio.unand.ac.id/presensi/mencarijarakterdekat.php?username=$username&latitude=$_latitude&longitude=$_longitude");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        print("Data from server: $responseData");
        // Tampilkan respons di dalam teks
        setState(() {
          serverResponse = "$responseData";
        });
      } else {
        print(
            "Failed to fetch data from server. Status code: ${response.statusCode}");
        // Tampilkan pesan kesalahan di dalam teks
        setState(() {
          serverResponse =
              "Failed to fetch data from server. Status code: ${response.statusCode}";
        });
      }
    } catch (error) {
      print("Error: $error");
      // Tampilkan pesan kesalahan di dalam teks
      setState(() {
        serverResponse = "Error: $error";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var launchURL = _launchURL;
    return Scaffold(
      body: SafeArea(
        child: Container(
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black,
                      image: DecorationImage(
                        fit: BoxFit.cover,
                        image: FileImage(File(widget.imagePath)),
                      ),
                    ),
                    margin: EdgeInsets.all(20),
                    width: 50,
                    height: 50,
                  ),
                  Text(
                    'Hi ' + widget.username + '!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (serverResponse == 'false')
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xFFFEFFC1),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: InkWell(
                                onTap: () {
                                  // Tampilkan pop-up di luar jangkauan di sini
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Peringatan'),
                                        content: Text(
                                            'Anda Berada DI Luar Kawasan Area Universitas Andalas'),
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
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_outlined,
                                      size: 30,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Absen Masuk',
                                      style: TextStyle(fontSize: 16),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (serverResponse == 'true')
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xFFFEFFC1),
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          PresensiIn(),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_outlined,
                                      size: 30,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Absen Masuk',
                                      style: TextStyle(fontSize: 16),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (serverResponse == 'false')
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: InkWell(
                                onTap: () {
                                  // Tampilkan pop-up di luar jangkauan di sini
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Peringatan'),
                                        content: Text(
                                            'Anda Berada DI Luar Kawasan Area Universitas Andalas'),
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
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_outlined,
                                      size: 30,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Absen Pulang',
                                      style: TextStyle(fontSize: 16),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (serverResponse == 'true')
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.blue,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          PresensiAuth(),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_outlined,
                                      size: 30,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Absen Pulang',
                                      style: TextStyle(fontSize: 16),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: launchURL,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.yellow,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (BuildContext context) =>
                                          PresensiDinasluar(),
                                    ),
                                  );
                                },
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_outlined,
                                      size: 30,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Dinas Luar',
                                      style: TextStyle(fontSize: 16),
                                      textAlign: TextAlign.left,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: _launchURL,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.red,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.1),
                                    blurRadius: 1,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              padding: EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.warning_amber_outlined,
                                    size: 30,
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    'Bantuan',
                                    style: TextStyle(fontSize: 16),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histori Presensi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _hasFetchedData
                          ? null
                          : fetchHistoriPresensiByUsername(widget.username),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        } else {
                          List<Map<String, dynamic>> historiPresensi =
                              snapshot.data ?? [];
                          _hasFetchedData = true;
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: historiPresensi.length,
                            itemBuilder: (context, index) {
                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 16),
                                child: ListTile(
                                  title: Text(
                                    'Tanggal: ${historiPresensi[index]["tanggal"]}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Absen Masuk: ${historiPresensi[index]["absen_masuk"]}'),
                                          Text(
                                              'Jam Masuk: ${historiPresensi[index]["jammasuk"]}'),
                                        ],
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              'Absen Keluar: ${historiPresensi[index]["absen_keluar"]}'),
                                          Text(
                                              'Jam Keluar: ${historiPresensi[index]["jamkeluar"]}'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  contentPadding: EdgeInsets.all(16),
                                  tileColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              Text('Latitude: $_latitude'),
              Text('Longitude: $_longitude'),
              Text('Mock Location: $_isMockLocation'),
              Text(
                'respon jarak area : $serverResponse',
                style: TextStyle(fontSize: 16),
              ),
              Spacer(),
              AppButton(
                text: "LOG OUT",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyHomePage()),
                  );
                },
                icon: Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
                color: Color(0xFFFF6161),
              ),
              SizedBox(
                height: 20,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _launchURL {}

List<Map<String, String>> historiList = [
  {'title': 'Masuk', 'subTitle': 'Rabu, 28 February 2024.', 'waktu': '08:00'},
  {'title': 'Pulang', 'subTitle': 'Rabu, 28 February 2024.', 'waktu': '16:30'},
  {'title': 'Masuk', 'subTitle': 'Kamis, 29 February 2024.', 'waktu': '08:45'},
];
