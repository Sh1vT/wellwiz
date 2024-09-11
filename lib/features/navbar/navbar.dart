// navbar.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/features/appointments/doc_view.dart'; // Adjust the import based on your project structure

class Navbar extends StatelessWidget {
  final String userId;

  const Navbar({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text('Navigation Menu', style: TextStyle(fontSize: 24)),
          ),
          ListTile(
            title: const Text('Appointment'),
            onTap: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => DocView(userId: userId)),
              );
            },
          ),
          // Add more ListTiles for other pages
          ListTile(
            title: const Text('Logout'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushReplacementNamed('/login'); // Adjust route as needed
            },
          ),
        ],
      ),
    );
  }
}
