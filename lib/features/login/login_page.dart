import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/home/home_page.dart';
import 'package:wellwiz/features/login/sign_in_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    await GoogleSignIn().signOut();
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print("Google Sign-In canceled.");
        return;
      }

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        print("Error: idToken is null");
        return;
      }

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      print("User signed in successfully: ${userCredential.user?.displayName}");

      SharedPreferences pref = await SharedPreferences.getInstance();
      pref.setString('username', googleUser.displayName!);
      pref.setString('userimg', googleUser.photoUrl!);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      print("Exception: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            border: Border.all(
              color: Color.fromRGBO(161, 188, 117, 1),
              width: 10.0,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Spacer(),
                Container(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.jpeg',
                      height: 100,
                      width: 100,
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
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
                const SizedBox(height: 10),
                SignInButton(
                  buttontext: ("Sign In"),
                  iconImage: const AssetImage('assets/images/googlelogo.png'),
                  onPressed: () {
                    // TODO: Implement Google Sign-In and remove Navigator.push in favor of StreamBuilder in SplashScreen
                    _signInWithGoogle(context);
                    // Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => const GlobalScaffold()));
                  },
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Made with ",
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        color: Color.fromRGBO(64, 52, 52, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(Icons.favorite, color: Colors.green.shade600,),
                    Text(
                      " by Can-do Crew",
                      style: TextStyle(
                        fontFamily: 'Mulish',
                        color: Color.fromRGBO(64, 52, 52, 1),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4,)
              ],
            ),
          ),
        ),
      ),
    );
  }
}
