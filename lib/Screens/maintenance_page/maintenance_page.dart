import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';
import 'package:quds_yaghmour/components/button-widget/button-widget.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_screen/login_page.dart';

class MaintenancePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Main_Color,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Image.asset(
                    'assets/images/research-analysis.png',
                    height: 150,
                  ),
                  SizedBox(height: 20),
                  Text(
                    'سوف نعود قريبا',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'يخضع تطبيقنا حاليًا لصيانة مجدولة. شكرا لك على صبرك.',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  ButtonWidget(
                      name: "تسجيل الخروج",
                      height: 40,
                      width: 180,
                      BorderColor: Main_Color,
                      FontSize: 16,
                      OnClickFunction: () async {
                        Navigator.of(context, rootNavigator: true).pop();
                        SharedPreferences sharedPreferences =
                            await SharedPreferences.getInstance();
                        sharedPreferences.clear();
                        sharedPreferences.commit();
                        Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    LoginScreen()),
                            (Route<dynamic> route) => false);
                        Fluttertoast.showToast(msg: "تم تسجيل الخروج بنجاح");
                      },
                      BorderRaduis: 10,
                      ButtonColor: Main_Color,
                      NameColor: Colors.white)
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
