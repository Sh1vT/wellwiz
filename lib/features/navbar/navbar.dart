// navbar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/features/appointments/doc_view.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/emergency/emergency_service.dart';
import 'package:wellwiz/features/login/login_page.dart';
import 'package:wellwiz/features/profile/profile.dart';
import 'package:wellwiz/features/reminder/reminder_page.dart';
import 'package:wellwiz/features/home/homePage.dart';

class Navbar extends StatelessWidget {
  final String userId;
  final String username;
  final String userimg;

  const Navbar(
      {Key? key,
      required this.userId,
      required this.username,
      required this.userimg})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Colors.grey.shade50,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  child: Image.asset(
                    "assets/images/cropped.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
                Container(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        height: 45,
                        width: 45,
                        child: ClipOval(
                          child: Image.network(userimg),
                        ),
                      ),
                      SizedBox(height: 4),
                      Container(
                          padding: EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            // color: Color.fromARGB(255, 181, 245, 143),
                            border: Border.all(
                              width: 3,
                              color: Color.fromARGB(255, 42, 119, 72),
                            ),
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                                bottomRight: Radius.circular(12)),
                          ),
                          child: Text(
                            username,
                            style: TextStyle(
                                fontFamily: 'Mulish',
                                color: Color.fromARGB(255, 42, 119, 72),
                                fontWeight: FontWeight.w600),
                          )),
                    ],
                  ),
                )
              ],
            ),
            ListTile(
              minTileHeight: 60,
              leading: Icon(
                Icons.cyclone_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
              trailing: Icon(
                Icons.arrow_right_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
              title: Text(
                'Wizard',
                style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Divider(
                height: 0,
              ),
            ),

            ListTile(
              minTileHeight: 60,
              leading: Icon(
                Icons.home,
                color: Colors.green.shade600,
                size: 28,
              ),
              trailing: Icon(
                Icons.arrow_right_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
              title: Text(
                'Home',
                style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return HomePage();
                }));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Divider(
                height: 0,
              ),
            ),
            ListTile(
              minTileHeight: 60,
              leading: Icon(
                Icons.note_alt_outlined,
                color: Colors.green.shade600,
                size: 28,
              ),
              trailing: Icon(
                Icons.arrow_right_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
              title: Text(
                'Profile',
                style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600),
              ),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return ProfilePage();
                }));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Divider(
                height: 0,
              ),
            ),
            ListTile(
              minTileHeight: 70,
              leading: Icon(
                Icons.calendar_month_outlined,
                color: Colors.green.shade600,
                size: 28,
              ),
              trailing: Icon(
                Icons.arrow_right_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
              title: Text(
                'Appointment',
                style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => DocView(userId: userId)),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Divider(
                height: 0,
              ),
            ),
            ListTile(
              minTileHeight: 70,
              leading: Icon(
                Icons.notifications_active_outlined,
                color: Colors.green.shade600,
                size: 28,
              ),
              trailing: Icon(
                Icons.arrow_right_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
              title: Text(
                'Emergency',
                style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return EmergencyScreen();
                }));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Divider(
                height: 0,
              ),
            ),
            ListTile(
              minTileHeight: 60,
              leading: Icon(
                Icons.access_alarm_sharp,
                color: Colors.green.shade600,
                size: 28,
              ),
              trailing: Icon(
                Icons.arrow_right_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
              title: Text(
                'Reminders',
                style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600),
              ),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return ReminderPage(userId: userId);
                }));
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Divider(
                height: 0,
              ),
            ),
            ListTile(
              minTileHeight: 60,
              leading: Icon(
                Icons.power_settings_new_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
              trailing: Icon(
                Icons.arrow_right_rounded,
                color: Colors.green.shade600,
                size: 28,
              ),
              title: Text(
                'Logout',
                style: TextStyle(
                    fontFamily: 'Mulish',
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return LoginScreen();
                }));
              },
            ),
            Spacer(),
            Container(
              height: 100,
              color: Colors.grey.shade50,
              // decoration: BoxDecoration(
              //   gradient: LinearGradient(
              //     colors: [Colors.grey.shade200, Colors.green.shade200],
              //     begin: Alignment.topCenter,
              //     end: Alignment.bottomCenter,
              //   ),
              // ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      width: 64,
                      height: 64,
                      isAntiAlias: true,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Well",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Mulish',
                            fontSize: 40,
                            color: Color.fromRGBO(180, 207, 126, 1)),
                      ),
                      Text(
                        "Wiz",
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Mulish',
                            fontSize: 40,
                            color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
