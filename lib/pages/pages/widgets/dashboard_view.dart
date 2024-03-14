import 'dart:convert';

import 'package:face_net_authentication/pages/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:location_permissions/location_permissions.dart';
import 'package:trust_location/trust_location.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../constants/colors.dart';
import '../../../constants/constants.dart';
import '../../../constants/fonts.dart';
import '../../../constants/sizes.dart';
import '../../../utils/alert_utils.dart';

import 'package:http/http.dart' as http;

import '../../presensi-auth.dart';
import '../../presensi-in.dart';
import '../../widgets/app_button.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({this.username, Key? key, this.imagePath})
      : super(key: key);

  final String? username;
  final String? imagePath;
  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
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
          // _isMockLocation = values.isMockLocation ?? false;
          print("mocklocation 1: $_isMockLocation");
        });
        print("mocklocation 2: $_isMockLocation");
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
        getDataFromServer(widget.username!, _latitude, _longitude);
      });
    } on PlatformException catch (e) {
      print('PlatformException: $e');
    } catch (e) {
      print('Error: $e');
    }
  }

  final String historiPresensiURL =
      Constants.BASEURL + Constants.HISTORIABSENSI;

  Future<List<Map<String, dynamic>>> fetchHistoriPresensiByUsername(
      String username) async {
    final Uri url = Uri.parse("${historiPresensiURL}?username=$username");
    final response = await http.get(url);
    print("url : $url");
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

    final Uri url = Uri.parse(Constants.BASEURL +
        Constants.CARIJARAKTERDEKAT +
        "?username=$username&latitude=$_latitude&longitude=$_longitude");

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
    return SingleChildScrollView(
      child: Stack(
        children: [
          Container(
            width: deviceWidth(context),
            height: 205 - statusBarHeight(context),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          Column(
            children: [
              SizedBox(
                height: 32,
              ),
              _HeaderDashboardComponent(),
              SizedBox(
                height: 32,
              ),
              _InformationsComponent(widget.username),
              SizedBox(
                height: 40,
              ),
              _MenuActivityComponent(),
              SizedBox(
                height: 20,
              ),
              _AnnouncementComponent(),
              SizedBox(
                height: 95,
              ),
              _historyAbsensi(),
              Text('Latitude: $_latitude'),
              Text('Longitude: $_longitude'),
              Text('Mock Location: $_isMockLocation'),
              Text(
                'respon jarak area : $serverResponse',
                style: TextStyle(fontSize: 16),
              ),
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
                height: 120,
              )
            ],
          ),
        ],
      ),
    );
  }

  _historyAbsensi() {
    return Column(
      children: [
        Column(
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
            FutureBuilder(
              future: _hasFetchedData
                  ? null
                  : fetchHistoriPresensiByUsername(widget.username ?? "333"),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
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
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(
                            'Tanggal: ${historiPresensi[index]["tanggal"]}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Absen Masuk: ${historiPresensi[index]["absen_masuk"]}'),
                                  Text(
                                      'Jam Masuk: ${historiPresensi[index]["jammasuk"]}'),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
      ],
    );
  }
}

class _HeaderDashboardComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: defaultMargin,
        ),
        Container(
          width: 50,
          height: 50,
          margin: EdgeInsets.only(right: 14),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/logo.png'),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Presensian",
              style: boldWhiteFont.copyWith(fontSize: 22),
            ),
            Text(
              "Modern Presence App",
              style: regularWhiteFont.copyWith(fontSize: 11),
            ),
          ],
        ),
        Spacer(
          flex: 1,
        ),
        Container(
          width: 38,
          height: 38,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              primary: maroonColor,
              elevation: 0,
              onPrimary: Colors.black.withOpacity(0.3),
              visualDensity: VisualDensity.comfortable,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () {
              showAlert(
                context,
                alert: _LogoutAlertComponent(),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/images/ic_logout.png',
                width: 18,
                height: 18,
              ),
            ),
          ),
        ),
        SizedBox(
          width: defaultMargin,
        ),
      ],
    );
  }
}

class _LogoutAlertComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: defaultMargin,
        vertical: 25,
      ),
      content: Container(
        height: 290,
        child: Column(
          children: [
            Container(
              height: 120,
              margin: EdgeInsets.only(bottom: 15),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/logout.png'),
                ),
              ),
            ),
            Text(
              "Logout Dari Akun Ini",
              textAlign: TextAlign.center,
              style: boldBlackFont.copyWith(fontSize: 20),
            ),
            SizedBox(
              height: 6,
            ),
            Text(
              "Akunmu akan bisa dilogin dari\nperangkat mana saja!",
              textAlign: TextAlign.center,
              style: semiGreyFont.copyWith(fontSize: 13),
            ),
            Spacer(
              flex: 1,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 105,
                  height: 40,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Color(0xFFCDCBCB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Batalkan",
                      style: semiWhiteFont.copyWith(fontSize: 14),
                    ),
                  ),
                ),
                Container(
                  width: 105,
                  height: 40,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    onPressed: () async {
                      // await AuthServices.logOut();
                      // Navigator.pushReplacementNamed(
                      //     context, Wrapper.routeName);
                    },
                    child: Text(
                      "Logout",
                      style: semiWhiteFont.copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InformationsComponent extends StatelessWidget {
  String? username;
  _InformationsComponent(username);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi ' + '!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        ),
        Text(
          "Selamat Beraktivitas, ",
          style: semiWhiteFont.copyWith(fontSize: 14),
        ),
        SizedBox(
          height: 12,
        ),
        Container(
            width: defaultWidth(context),
            padding: EdgeInsets.only(
              top: 16,
              bottom: 8,
              left: 25,
              right: 25,
            ),
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFEEEEEE),
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Container()),
      ],
    );
  }
}

class _PresenceInfoComponent extends StatelessWidget {
  final String? iconPath;
  final String? presenceType;
  final int totalPresence;

  _PresenceInfoComponent(
      {this.iconPath, this.presenceType, this.totalPresence = 0});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(iconPath!),
            ),
          ),
        ),
        SizedBox(
          height: 8,
        ),
        Text(
          presenceType!,
          style: regularBlackFont.copyWith(fontSize: 12),
        ),
        SizedBox(
          height: 2,
        ),
        Text(
          totalPresence.toString(),
          style: boldBlackFont.copyWith(fontSize: 18),
        ),
      ],
    );
  }
}

class _MenuActivityComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Menu Aktivitas",
          style: semiBlackFont.copyWith(fontSize: 14),
        ),
        SizedBox(
          height: 16,
        ),
        Wrap(
          spacing: 24,
          runSpacing: 20,
          children: [
            _MenuComponent(
              titleMenu: "Absen Masuk",
              iconPath: 'assets/images/ic_absen_masuk.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => PresensiIn(),
                  ),
                );
              },
            ),
            _MenuComponent(
              titleMenu: "Absen Pulang",
              iconPath: 'assets/images/ic_absen_pulang.png',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext context) => PresensiAuth(),
                  ),
                );
              },
            ),
            _MenuComponent(
              titleMenu: "Riwayat",
              iconPath: 'assets/images/ic_history.png',
              onTap: () {
                Navigator.pushNamed(context, " HistoryScreen.routeName");
              },
            ),
            _MenuComponent(
              titleMenu: "Dinas Luar",
              iconPath: 'assets/images/ic_letter.png',
              onTap: () {
                Navigator.pushNamed(context, "PermitLetterScreen.routeName");
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuComponent extends StatelessWidget {
  final String? titleMenu;
  final String? iconPath;
  final Function()? onTap;

  _MenuComponent({this.titleMenu, this.iconPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Ink(
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.black.withOpacity(0.4),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: deviceWidth(context) / 2 - 1.5 * defaultMargin,
            height: 54,
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  titleMenu!,
                  style: boldWhiteFont.copyWith(fontSize: 13),
                ),
                Image.asset(
                  iconPath!,
                  width: 24,
                  height: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Pemberitahuan",
          style: semiBlackFont.copyWith(fontSize: 14),
        ),
        SizedBox(
          height: 16,
        ),
        Container(
          width: defaultWidth(context),
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFEEEEEE),
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/megaphone.png',
                width: 35,
                height: 35,
              ),
              SizedBox(
                width: 10,
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Perubahan Sistem Absensi",
                    style: semiWhiteFont.copyWith(fontSize: 14),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  Text(
                    "Absensi menggunakan aplikasi Presensian",
                    style: semiBlackFont.copyWith(
                      fontSize: 11.5,
                      color: Color(0xFFEEEEEE),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
