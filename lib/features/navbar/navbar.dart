// navbar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/features/appointments/doc_view.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/login/login_page.dart';
import 'package:wellwiz/features/profile/profile.dart';

class Navbar extends StatelessWidget {
  final String userId;

  const Navbar({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            child: Image.asset(
              "assets/images/navimg.jpg",
              fit: BoxFit.cover,
            ),
          ),
          ListTile(
            minTileHeight: 60,
            leading: Icon(
              Icons.person_pin_circle_outlined,
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
              //ENTER PROFILING LINK HERE
              ///
              ///
              ///
              ///
              ///
              ///
              Navigator.of(context).push(MaterialPageRoute(builder: (context)
              {
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
              Icons.hail_rounded,
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
        ],
      ),
    );
  }
}
