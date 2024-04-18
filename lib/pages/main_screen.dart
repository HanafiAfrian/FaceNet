import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/colors.dart';
import '../constants/fonts.dart';
import 'pages/widgets/dashboard_view.dart';
import 'pages/widgets/presence_view.dart';

class MainScreen extends StatefulWidget {
  final String? username;
  final String? imagePath;
  const MainScreen({Key? key, this.username, this.imagePath}) : super(key: key);
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? bottomNavBarIndex;
  PageController? pageController;

  String? nip;

  String? path;

  @override
  void initState() {
    super.initState();
   
    bottomNavBarIndex = 0;
    pageController = PageController(initialPage: bottomNavBarIndex!);
  }

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: primaryColor,
          ),
          SafeArea(
            child: Stack(
              children: [
                Container(
                  color: screenColor,
                ),
                PageView(
                  controller: pageController,
                  onPageChanged: (index) {
                    setState(() {
                      bottomNavBarIndex = index;
                    });
                  },
                  children: [
                    DashboardView(
                      username: nip,
                      imagePath: path,
                      context: context,
                    ),
                    PresenceView(),
                  ],
                ),
                bottomNavBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomNavBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          unselectedItemColor: Color(0xFFE5E5E5),
          currentIndex: bottomNavBarIndex!,
          onTap: (index) {
            setState(() {
              bottomNavBarIndex = index;
              pageController?.jumpToPage(index);
            });
          },
          selectedLabelStyle: (bottomNavBarIndex == 0)
              ? boldBlackFont.copyWith(
                  color: primaryColor,
                  fontSize: 12,
                )
              : semiBlackFont.copyWith(
                  color: Color(0xFFCDCBCB),
                  fontSize: 12,
                ),
          items: [
            BottomNavigationBarItem(
              label: "dashboard",
              icon: Container(
                margin: EdgeInsets.only(bottom: 4),
                height: 24,
                child: Image.asset(
                  (bottomNavBarIndex == 0)
                      ? "assets/images/dashboard_active.png"
                      : "assets/images/dashboard_inactive.png",
                  color: (bottomNavBarIndex == 0) ? primaryColor : greyColor,
                ),
              ),
            ),
            BottomNavigationBarItem(
              label: "Kehadiran",
              icon: Container(
                margin: EdgeInsets.only(bottom: 4),
                height: 24,
                child: Image.asset(
                  (bottomNavBarIndex == 1)
                      ? "assets/images/list_active.png"
                      : "assets/images/list_inactive.png",
                  color: (bottomNavBarIndex == 1) ? primaryColor : greyColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

 
}
