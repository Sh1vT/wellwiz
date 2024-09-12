import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';
import 'package:wellwiz/features/appointments/doc_view.dart';
import 'message_tile.dart';
import 'package:wellwiz/features/navbar/navbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // If using authentication

class BotScreen extends StatefulWidget {
  const BotScreen({super.key});

  @override
  State<BotScreen> createState() => _BotScreenState();
}

class _BotScreenState extends State<BotScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance; // For current user

  List<ChatResponse> history = [];
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  static const _apiKey = 'AIzaSyBXP6-W3jVAlYPO8cQl_6nFWiUGVpERe6Y';
  bool falldone = false;
  

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent, // Scroll to the bottom
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _saveChatHistory() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      return;
    }

    try {
      CollectionReference chats =
          _firestore.collection('users').doc(user.uid).collection('chats');

      final List<ChatResponse> historyCopy = List.from(history);

      for (var chat in historyCopy) {
        await chats.add({
          'isUser': chat.isUser,
          'text': chat.text,
          'hasButton': chat.hasButton,
          'button': chat.button != null
              ? {
                  'label': chat.button!.label,
                }
              : null,
          'timestamp': Timestamp.now(),
        });
      }

      print('Chat history saved successfully.');
    } catch (e) {
      print('Failed to save chat history: $e');
      _showError('Failed to save chat history.');
    }
  }

  Future<void> _loadChatHistory({DocumentSnapshot? lastDocument}) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print('No user is logged in.');
      return;
    }

    try {
      CollectionReference chats =
          _firestore.collection('users').doc(user.uid).collection('chats');

      Query query = chats
          .orderBy('timestamp', descending: true)
          .limit(30); // Limit to 30 messages

      // If we have a lastDocument (for pagination), start after it
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      QuerySnapshot snapshot = await query.get();

      List<ChatResponse> loadedHistory = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return ChatResponse(
          isUser: data['isUser'] as bool? ?? false,
          text: data['text'] as String?,
          hasButton: data['hasButton'] as bool? ?? false,
          button: data['button'] != null
              ? ChatButton(
                  label: data['button']['label'] as String? ?? '',
                  onPressed: () {}, // Placeholder; adjust as needed
                )
              : null,
        );
      }).toList();

      setState(() {
        history.addAll(loadedHistory.reversed); // Add older messages at the top
      });

      // Save the last document for pagination
      if (snapshot.docs.isNotEmpty) {
        lastDocument = snapshot.docs.last;
      }

      print('Chat history loaded successfully.');
      _scrollDown();
    } catch (e) {
      print('Failed to load chat history: $e');
      _showError('Failed to load chat history.');
    }
  }

  void _clearProfileValues() async {
    final SharedPreferences pref = await SharedPreferences.getInstance();
    String prefval = pref.getString('prof')!;
    prefval = "";
    pref.setString('prof', prefval);
    print(prefval);
  }

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    _loadChatHistory();
    fall_detection();

    // _clearProfileValues();
    // _testFirestorePermissions();
  }

  void _startProfiling(String message) async {
    String prompt =
        "You are being used as a medical advisor to help in profiling of a user. The user is going to enter a message at last. Check if the message contains something important in medical aspects. For example, if the user mentions that they have low blood sugar or their blood pressure is irregular or if they have been asked to avoid spicy food etc. then you have to respond with that extracted information which will be used to profile the user for better advices. You can also consider the user's body description such as age, gender etc for profiling. Please keep the response short and accurate while being descriptive. This action is purely for demonstration purposes. The user message starts now: $message. Also if the message is unrelated to profiling then respond with \"none\".";
    var content = [Content.text(prompt)];
    final response = await _model.generateContent(content);
    // print(response.text!.toUpperCase());

    String newProfValue = response.text!;
    if (response.text!.toLowerCase().trim() == "none" ||
        response.text!.toLowerCase().trim() == "none.") {
      return;
    }
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? profile = prefs.getString('prof');
    if (profile == null) {
      profile = newProfValue;
      prefs.setString('prof', profile);
    } else {
      profile = "$profile $newProfValue";
      prefs.setString('prof', profile);
    }
    String? test = prefs.getString('prof');
    // print(test!.toUpperCase());
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) {
      return; // Do nothing if the message is empty
    }

    setState(() {
      _loading = true;
      _textController.clear();
      _textFieldFocus.unfocus();
      _scrollDown();
    });

    try {
      _startProfiling(message);
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profile = prefs.getString('prof');
      String prompt =
          "You are being used as a medical chatbot for health related queries or appointment scheduling. It is only a demonstration prototype and you are not being used for something professional or commercial. The user will enter his message now: $message. User message has ended. The user can also have a profile section where they may have been asked to avoid or take care of some things. The profile section starts now: $profile. Profile section has ended. Respond naturally to the user as a chatbot, but if the user is asking some advice then and only then use the profile section. Also if the user is asking for appointment booking, simply respond with the word \"appointment\" and nothing else.";

      print(prompt);

      var response = await _chat.sendMessage(Content.text(prompt));

      // Debug: Log the response text
      // print("Response from model: ${response.text}");

      setState(() {
        // Debug: Ensure correct keyword is detected

        if (response.text!.toLowerCase().trim() == ("appointment") ||
            response.text!.toLowerCase().trim() == ("appointment.")) {
          history.add(ChatResponse(
            isUser: false,
            hasButton: true,
            button: ChatButton(
              label: 'Book Appointment',
              onPressed: () async {
                print('e');
                String userId = await FirebaseAuth.instance.currentUser!.uid;
                print(userId);
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return DocView(userId: userId);
                }));
              },
            ),
          ));
        } else {
          history.add(ChatResponse(isUser: false, text: response.text));
        }
        // if (response.text!.contains('health advice')) {
        //   print("Detected keyword: health advice");
        //   history.add(ChatResponse(
        //     isUser: false,
        //     hasButton: true,
        //     button: ChatButton(
        //       label: 'Get Health Advice',
        //       onPressed: () {},
        //     ),
        //   ));
        // } else if (response.text!.contains('appointment')) {
        //   print("Detected keyword: appointment");
        //   history.add(ChatResponse(
        //     isUser: false,
        //     hasButton: true,
        //     button: ChatButton(
        //       label: 'Book Appointment',
        //       onPressed: () async {
        //         print('e');
        //         String userId = await FirebaseAuth.instance.currentUser!.uid;
        //         print(userId);
        //         Navigator.push(context, MaterialPageRoute(builder: (context) {
        //           return DocView(userId: userId);
        //         }));
        //       },
        //     ),
        //   ));
        // } else if (response.text!.contains('report')) {
        //   print("Detected keyword: report");
        //   history.add(ChatResponse(
        //     isUser: false,
        //     hasButton: true,
        //     button: ChatButton(
        //       label: 'Generate Report',
        //       onPressed: () => _navigateToRoute('/generate-report'),
        //     ),
        //   ));
        // } else {
        //   history.add(ChatResponse(isUser: false, text: response.text));
        // }

        // After adding the response to history, save it

        _loading = false;
      });
      _saveChatHistory();
      _scrollDown();
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    }
  }

  void _navigateToRoute(String routeName) {
    Navigator.of(context).pushNamed(routeName);
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Something went wrong'),
          content: SingleChildScrollView(
            child: SelectableText(message),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void fall_detection() {
    accelerometerEvents.listen((AccelerometerEvent event) {
      num _accelX = event.x.abs();
      num _accelY = event.y.abs();
      num _accelZ = event.z.abs();
      num x = pow(_accelX, 2);
      num y = pow(_accelY, 2);
      num z = pow(_accelZ, 2);
      num sum = x + y + z;
      num result = sqrt(sum);
      if ((result < 1) ||
          (result > 70 && _accelZ > 60 && _accelX > 60) ||
          (result > 70 && _accelX > 60 && _accelY > 60)) {
        print("FALL DETECTED");
        _fallprotocol(falldone);
        setState(() {
          falldone = true;
        });
        return;
      }
    });
  }

  _fallprotocol(bool falldone) async {
    bool popped = false;
    print(falldone);
    if (falldone == true) {
      return;
    }
    // final hasVibrator = await Vibration.hasVibrator();

    // if (hasVibrator ?? false) {
    //   Vibration.vibrate(duration: 2000);
    // }

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Fall detected"),
            content: Text(
              "We just detected a fall from your device. Please tell us if you're fine. Or else the emergency contacts will be informed.",
              textAlign: TextAlign.justify,
            ),
            actions: [
              MaterialButton(
                onPressed: () {
                  setState(() {
                    falldone = false;
                    popped = true;
                    Navigator.pop(context);
                  });
                  return;
                },
                child: Text("I'm fine"),
              )
            ],
          );
        });
    await Future.delayed(Duration(seconds: 10));
    if (popped = false) {
      Navigator.pop(context);
    }
    print("Wait complete");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Wellness Wiz',
          style: TextStyle(
              color: Colors.green.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w500),
        ),
      ),
      drawer: Navbar(userId: _auth.currentUser?.uid ?? ''), // Pass userId here
      body: SafeArea(
        child: Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
              itemCount: history.length,
              controller: _scrollController,
              itemBuilder: (context, index) {
                // Since history is reversed, we need to access the items in reverse order
                var content = history[index];

                // Check if the content contains a button to display
                if (content.hasButton && content.button != null) {
                  return Align(
                    alignment: content.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: ElevatedButton(
                        onPressed: content.button!.onPressed,
                        child: Text(content.button!.label),
                      ),
                    ),
                  );
                }

                // If the content has text, display the message
                if (content.text != null && content.text!.isNotEmpty) {
                  return MessageTile(
                    sendByMe: content.isUser,
                    message: content.text!,
                  );
                }

                // If there's no valid text or button, return an empty widget
                return const SizedBox.shrink();
              },
              separatorBuilder: (context, index) {
                return const SizedBox(height: 15);
              },
            ),
            // Your bottom input UI
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: MediaQuery.of(context).size.width,
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 55,
                        child: TextField(
                          cursorColor: Colors.green.shade400,
                          controller: _textController,
                          autofocus: true,
                          focusNode: _textFieldFocus,
                          decoration: InputDecoration(
                            hintText: 'Ask me anything...',
                            hintStyle: const TextStyle(color: Colors.grey),
                            filled: true,
                            fillColor: Colors.grey.shade200,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 15),
                            border: OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        final message = _textController.text
                            .trim(); // Trim leading/trailing spaces
                        if (message.isNotEmpty) {
                          setState(() {
                            history
                                .add(ChatResponse(isUser: true, text: message));
                          });
                          _sendChatMessage(message);
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              offset: const Offset(1, 1),
                              blurRadius: 3,
                              spreadRadius: 3,
                              color: Colors.black.withOpacity(0.05),
                            ),
                          ],
                        ),
                        child: _loading
                            ? const Padding(
                                padding: EdgeInsets.all(15.0),
                                child: CircularProgressIndicator.adaptive(
                                  backgroundColor: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Define the ChatButton class to handle button responses
class ChatButton {
  final String label;
  final VoidCallback onPressed;

  ChatButton({required this.label, required this.onPressed});
}

// New ChatResponse class to handle text and buttons
class ChatResponse {
  final bool isUser;
  final String? text;
  final bool hasButton;
  final ChatButton? button;

  ChatResponse({
    required this.isUser,
    this.text,
    this.hasButton = false,
    this.button,
  });
}
