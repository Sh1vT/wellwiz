import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wellwiz/features/appointments/doc_view.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/chatrooms/chatroom_selection_screen.dart';
import 'package:wellwiz/features/emergency/emergency_service.dart';
import 'package:wellwiz/features/home/home_page.dart';
import 'package:wellwiz/features/login/login_page.dart';
import 'package:wellwiz/features/profile/profile.dart';
import 'package:wellwiz/features/reminder/reminder_page.dart';
import 'package:wellwiz/features/exercise/exercise_page.dart';

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
                            border: Border.all(
                              width: 3,
                              color: Color.fromARGB(255, 42, 119, 72),
                            ),
                            borderRadius: BorderRadius.circular(12),
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
            _buildListTile(
              context: context,
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => HomePage(),
                ));
              },
            ),
            _buildListTile(
              context: context,
              icon: Icons.note_alt_outlined,
              label: 'Profile',
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => ProfilePage(),
                ));
              },
            ),
            _buildListTile(
              context: context,
              icon: Icons.chat_outlined,
              label: 'Chatroom',
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => ChatRoomSelectionScreen(),
                ));
              },
            ),
            _buildListTile(
              context: context,
              icon: Icons.calendar_month_outlined,
              label: 'Appointment',
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => DocView(userId: userId),
                ));
              },
            ),
            _buildListTile(
              context: context,
              icon: Icons.notifications_active_outlined,
              label: 'Emergency',
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => EmergencyScreen(),
                ));
              },
            ),
            _buildListTile(
              context: context,
              icon: Icons.run_circle_outlined,
              label: 'Exercise',
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => ExerciseListPage(),
                ));
              },
            ),
            _buildListTile(
              context: context,
              icon: Icons.access_alarm_sharp,
              label: 'Reminders',
              onTap: () {
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => ReminderPage(userId: userId),
                ));
              },
            ),
            _buildListTile(
              context: context,
              icon: Icons.power_settings_new_rounded,
              label: 'Logout',
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushReplacement(MaterialPageRoute(
                  builder: (context) => LoginScreen(),
                ));
              },
            ),
            Spacer(),
            _buildFooterLogo(),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Function onTap,
  }) {
    return Column(
      children: [
        ListTile(
          minTileHeight: 60,
          leading: Icon(icon, color: Colors.green.shade600, size: 28),
          trailing: Icon(Icons.arrow_right_rounded,
              color: Colors.green.shade600, size: 28),
          title: Text(
            label,
            style: TextStyle(
                fontFamily: 'Mulish',
                fontWeight: FontWeight.bold,
                color: Colors.green.shade600),
          ),
          onTap: () => onTap(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Divider(height: 0),
        ),
      ],
    );
  }

  Widget _buildFooterLogo() {
    return Container(
      height: 100,
      color: Colors.grey.shade50,
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
          const SizedBox(width: 12),
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
    );
  }
}
