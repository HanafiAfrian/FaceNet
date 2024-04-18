import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

import '../../../constants/colors.dart';
import '../../../constants/fonts.dart';
import '../../../constants/sizes.dart';

class PresenceView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Stack(
        children: [
          Container(
            width: deviceWidth(context),
            height: 140 - statusBarHeight(context),
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
              _HeaderPresenceComponent(),
              SizedBox(
                height: 32,
              ),
              _ClockPresenceComponent(),
              SizedBox(
                height: 24,
              ),
              _PresenceActivityComponent(),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderPresenceComponent extends StatelessWidget {
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
              image: AssetImage('assets/images/secondary_logo.png'),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Aktivitas Kehadiran",
              style: boldWhiteFont.copyWith(fontSize: 22),
            ),
            Text(
              "Realtime Presence App",
              style: regularWhiteFont.copyWith(fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _ClockPresenceComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: 40,
      ),
      padding: EdgeInsets.symmetric(
        vertical: 10,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/clock.png',
            width: 31,
            height: 31,
          ),
          SizedBox(
            width: 16,
          ),
          // TimerBuilder.periodic(
          //   Duration(seconds: 1),
          //   builder: (context) {
          //     return Text(
          //       getSystemTime(),
          //       style: boldBlackFont.copyWith(
          //         color: primaryColor,
          //         fontSize: 24,
          //       ),
          //     );
          //   },
          // ),
          SizedBox(
            width: 16,
          ),
          Text(
            "WIB",
            style: boldBlackFont.copyWith(
              color: primaryColor,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _PresenceActivityComponent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int startTimeToday =
        DateTime.now().subtract(Duration(hours: 12)).millisecondsSinceEpoch;
    int endTimeToday =
        DateTime.now().add(Duration(hours: 12)).millisecondsSinceEpoch;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: defaultMargin),
          child: Text(
            "Kehadiran Hari Ini",
            textAlign: TextAlign.left,
            style: semiBlackFont.copyWith(fontSize: 14),
          ),
        ),
        SizedBox(
          height: 16,
        ),
      ],
    );
  }
}

class UserPresenceComponent extends StatelessWidget {
  final String? hari;
  final String? absentTimeMasuk, absentTimePulang;
  final String? photoURL, tanggal;
  String? timemasuk, timepulang;
  UserPresenceComponent(
      {this.hari,
      this.tanggal,
      this.absentTimeMasuk,
      this.absentTimePulang,
      this.photoURL});

  @override
  Widget build(BuildContext context) {
    if (absentTimeMasuk != null && absentTimeMasuk != "") {
      DateTime parsedTime = DateFormat('HH:mm:ss').parse(absentTimeMasuk!);
// Formatting objek DateTime ke format yang diinginkan dengan AM/PM
      timemasuk = DateFormat('hh : mm : ss a').format(parsedTime);
    } else {
      print("Waktu absen masuk tidak tersedia.");
    }
    if (absentTimePulang != null &&
        absentTimePulang != "" &&
        absentTimePulang != "0") {
      DateTime parsedTimePulang =
          DateFormat('HH:mm:ss').parse(absentTimePulang!);
// Formatting objek DateTime ke format yang diinginkan dengan AM/PM
      timepulang = DateFormat('hh : mm : ss a').format(parsedTimePulang);
    } else {
      print("Waktu absen pulang tidak tersedia.");
    }
    DateTime parsedDate = DateTime.parse(tanggal!);

    // Formatting objek DateTime ke format yang diinginkan
    String newTanggal = DateFormat('dd-MMMM-yyyy').format(parsedDate);
    return Container(
      width: deviceWidth(context),
      height: 104,
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: whiteColor,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFEBEBEF),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (photoURL == null)
            ClipOval(
              child: Image.asset(
                'assets/images/avatar.png',
                width: 46,
                height: 46,
                fit: BoxFit.cover,
              ),
            )
          else
            ClipOval(
              child: Image.network(
                photoURL!,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget? child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child!;
                  return SpinKitFadingCircle(
                    color: primaryColor,
                  );
                },
              ),
            ),
          SizedBox(
            width: 16,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                hari! + " / $newTanggal",
                style: semiBlackFont.copyWith(fontSize: 13),
              ),
              SizedBox(
                height: 6,
              ),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 14,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: timemasuk != null ? primaryColor : red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          "Masuk",
                          style: boldWhiteFont.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      timemasuk ?? "-",
                      style: semiBlackFont.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 14,
                      margin: EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: timepulang != null ? primaryColor : red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Center(
                        child: Text(
                          "Pulang",
                          style: boldWhiteFont.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      timepulang ?? "-",
                      style: semiBlackFont.copyWith(
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacer(
            flex: 1,
          ),
          Image.asset(
            'assets/images/entry.png',
            width: 24,
            height: 24,
          ),
        ],
      ),
    );
  }
}
