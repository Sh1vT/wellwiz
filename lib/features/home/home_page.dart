import 'dart:ffi';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/emotion/emotion_bot_screen.dart';
import 'package:wellwiz/features/navbar/navbar.dart';
import 'package:wellwiz/secrets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";
  String thought = "To be or not to be is the question";
  late final ChatSession _chat;
  static const _apiKey = geminikey;
  late final GenerativeModel _model;
  bool thoughtGenerated = false;

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
  }

  void generateThought() async {
    print("e");
    String prompt =
        "Generate a deep philosophical Shakespearean thought for a mental health application that is purely for demonstration purposes and no commercial use. The thought has to be unique and should be positive. Respond with only the thought without formatting and nothing else. Keep the thought limited to 30 words.";
    var response = await _chat.sendMessage(Content.text(prompt));
    setState(() {
      thought = response.text!;
      thoughtGenerated = true;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getUserInfo();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    generateThought();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          MaterialButton(onPressed: () {}, child: Icon(Icons.sos_rounded))
        ],
        title: Text(
          'Wizard',
          style: TextStyle(
              color: Colors.green.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Mulish'),
        ),
      ),
      drawer: Navbar(
        userId: _auth.currentUser?.uid ?? '',
        username: username,
        userimg: userimg,
      ),
      body: ListView(
        padding: EdgeInsets.zero, // Optional: removes any default padding
        children: <Widget>[
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return BotScreen();
              }));
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Color.fromARGB(255, 106, 172, 67),
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12))),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpeg',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align text to start
                      children: [
                        Text(
                          'Chat with Wizard',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Mulish',
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          height: 2.0,
                          width: 180.0,
                          color: Colors.grey.shade800,
                        ),
                        Text(
                          'Your personal medical assistant',
                          style: TextStyle(
                            fontSize: 14.0,
                            fontFamily: 'Mulish',
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Bottom widget: "How do you feel today?" section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                color: Color.fromARGB(255, 177, 221, 152),
              ),
              child: Column(
                children: [
                  // Heading
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.only(
                        left: 30, right: 30, top: 20, bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'Or tell him how you feel...',
                        textAlign: TextAlign.center, // Center align text
                        style: TextStyle(
                          fontFamily: 'Mulish',
                          fontSize: 16.0,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  // Grid of smaller buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: SizedBox(
                      height: 200,
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics:
                            NeverScrollableScrollPhysics(), // Prevents scrolling inside GridView
                        mainAxisSpacing: 20.0,
                        crossAxisSpacing: 20.0,
                        childAspectRatio: 3,
                        children: <Widget>[
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (conext) {
                                return EmotionBotScreen(emotion: "Happy");
                              }));
                            },
                            child: const Text(
                              'Happy',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {Navigator.push(context,
                                  MaterialPageRoute(builder: (conext) {
                                return EmotionBotScreen(emotion: "Sad");
                              }));},
                            child: const Text(
                              'Sad',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (conext) {
                                return EmotionBotScreen(emotion: "Angry");
                              }));
                            },
                            child: const Text(
                              'Angry',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (conext) {
                                return EmotionBotScreen(emotion: "Anxious");
                              }));
                            },
                            child: const Text(
                              'Anxious',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (conext) {
                                return EmotionBotScreen(emotion: "Frustrated");
                              }));
                            },
                            child: const Text(
                              'Frustrated',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(255, 106, 172, 67),
                            ),
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (conext) {
                                return EmotionBotScreen(emotion: "Stressed");
                              }));
                            },
                            child: const Text(
                              'Stressed',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Mulish',
                                  fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(42),
                      topRight: Radius.circular(42)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9, // 16:9 aspect ratio
                    child: Image.asset(
                      'assets/images/happy1.jpeg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(42),
                      bottomRight: Radius.circular(42),
                    ),
                    color: Colors.grey.shade800,
                  ),
                  padding:
                      EdgeInsets.only(left: 20, right: 20, bottom: 30, top: 20),
                  width: double.infinity,
                  child: Column(
                    children: [
                      Text(
                        thoughtGenerated
                            ? "“ " + thought.replaceAll('\n', '')
                            : "Wizard is thinking...",
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Mulish',
                            fontSize: 16),
                      ),
                      // SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          thoughtGenerated ? "- Wizard   " : "",
                          style: TextStyle(
                              fontFamily: 'Mulish',
                              color: Colors.green.shade300,
                              fontWeight: FontWeight.bold,
                              fontSize: 16),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
