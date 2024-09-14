// navbar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/features/appointments/doc_view.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/emergency/emergency_service.dart';
import 'package:wellwiz/features/login/login_page.dart';
import 'package:wellwiz/features/profile/profile.dart';

class Navbar extends StatelessWidget {
  final String userId;
  final String username;

  const Navbar({Key? key, required this.userId, required this.username})
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
                      Icon(
                        Icons.person_outline_rounded,
                        size: 45,
                        color: Color.fromARGB(255, 42, 119, 72),
                        weight: 1,
                      ),
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
                    fontWeight: FontWeight.bold, color: Colors.green.shade600),
              ),
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) {
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
                    fontWeight: FontWeight.bold, color: Colors.green.shade600),
              ),
              onTap: () {
                Navigator.of(context).pushReplacement(
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
                    fontWeight: FontWeight.bold, color: Colors.green.shade600),
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
                    fontWeight: FontWeight.bold, color: Colors.green.shade600),
              ),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).push(MaterialPageRoute(builder: (context) {
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
                  const Text(
                    'WellWiz',
                    style: TextStyle(
                        // fontFamily: 'Calibri',
                        color: Color.fromRGBO(161, 188, 117, 1),
                        fontSize: 32,
                        fontWeight: FontWeight.w700),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
