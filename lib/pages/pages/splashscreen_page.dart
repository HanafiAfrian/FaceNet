import 'dart:async';

import 'package:face_net_authentication/pages/pages/dinasluar.dart';
import 'package:face_net_authentication/pages/pages/widgets/dashboard_view.dart';
import 'package:face_net_authentication/pages/profile.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../home.dart';
import '../main_screen.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({Key? key}) : super(key: key);

  @override
  _SplashScreenPageState createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  //method yang pertama x dijalankan ketika mengakses suatu halaman dengan widget statefullwidget
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setLoading();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            "assets/images/loginand.png",
            width: 200,
            height: 200,
          ),
          const Padding(
            padding: EdgeInsets.only(top: 20),
            child: Text(
              "Presensian",
              style: TextStyle(
                  fontSize: 35,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontFamily: "batmfo__"),
            ),
          ),
          const SizedBox(
            height: 200,
          ),
          const CircularProgressIndicator(
            color: Colors.green,
          )
        ],
      )),
    );
  }

  setLoading() {
    var duration = const Duration(seconds: 5);
    return Timer(duration, () async {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      bool login = preferences.getBool("login") ?? false;
      String? nip = preferences.getString("nip") ?? "333";
      String? path = preferences.getString("path") ?? "";
      if (login) {
        //untuk perpindahan halaman
        // Navigator.pushReplacement(
        //     context,
        //     MaterialPageRoute(
        //         builder: (context) => Profile(
        //               nip!,
        //               imagePath: path!,
        //             )));

        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => MainScreen(
                      imagePath: path,
                      username: nip,
                    )));
      } else {
        //untuk perpindahan halaman
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => MyHomePage()));
      }
    });
  }
}
