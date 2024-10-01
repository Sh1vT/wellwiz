import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:wellwiz/features/appointments/doc_view.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/bot/message_tile.dart';
import 'package:wellwiz/features/navbar/navbar.dart';
import 'package:wellwiz/secrets.dart';

class EmotionBotScreen extends StatefulWidget {
  final String emotion;
  EmotionBotScreen({super.key, required this.emotion});

  @override
  State<EmotionBotScreen> createState() => _EmotionBotScreenState();
}

class _EmotionBotScreenState extends State<EmotionBotScreen> {
  bool recommendedMhp = false;
  String currentEmotion = "";
  List<ChatResponse> history = [];
  late final GenerativeModel _model;
  late final ChatSession _chat;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFieldFocus = FocusNode();
  bool _loading = false;
  static const _apiKey = geminikey;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  late DateTime _startTime;
  late SharedPreferences _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String mentalissues = "";

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
            )
          ],
        );
      },
    );
  }

  void _suggestmhp(String message) async {
    print(recommendedMhp);
    if (recommendedMhp == true) {
      return;
    }
    String analysisPrompt =
        """You are being used as a mental health chatbot for demonstration purposes and not commercially or professionally.
    The user has entered this message : $message. You have to summarise the message and link up the current and existing analysis.
    The current analysis is $mentalissues. The current session belongs to this emotion so the user was initially feeling this :$currentEmotion.
    Now generate a short summary so that the current analysis can be replaced with a better analysis including the current message.
    """;

    var analysisResponse =
        await _chat.sendMessage(Content.text(analysisPrompt));
    setState(() {
      mentalissues = analysisResponse.text!;
    });

    // print(mentalissues);
    QuerySnapshot querySnapshot = await _firestore.collection('mhp').get();
    List<Map<String, dynamic>> map = await querySnapshot.docs.map((doc) {
      return {
        'name': doc['name'],
        'profession': doc['profession'],
      };
    }).toList();

    String prompt =
        """You are being used as a mental health chatbot for demonstration purposes and not commercially or professionally. 
    You have to detect the user's messages and analyse how the user is currently feeling so that you can recommend an appropriate doctor.
    The user is currently feeling $currentEmotion, so take that into consideration too.
    We have a map of doctors with their name and profession that starts now : $map.
    The messages of the user so far have been these: $mentalissues. 
    If you cant suggest a doctor yet, simply respond with a plain text of "none" and nothing else.
    But Once you think a doctor matches to the user's current mental condition, respond a message that is formatted like this:
    Tell user that you cant replace an actual mental health professional. Tell them you've looked into the messages so far and it seems user has [issue]. 
    Then suggest them a [doctor] who specializes in [specialization]... Retur the doctor name and their specialization in bolded letters""";

    var response = await _chat.sendMessage(Content.text(prompt));
    // print(response.text!);

    if (response.text!.trim().toLowerCase() == "none." ||
        response.text!.trim().toLowerCase() == "none") {
      return;
    } else {
      setState(() {
        history.add(ChatResponse(isUser: false, text: response.text!));
        recommendedMhp = true;
      });
      _scrollDown();

      print("added");
    }
  }

  Future<void> _sendChatMessage(String message) async {
    if (message.trim().isEmpty) {
      return; // Do nothing if the message is empty
    }

    setState(() {
      _loading = true;
      _textController.clear();
      _textFieldFocus.unfocus();
    });

    _scrollDown(); // Ensure scroll to the bottom after user message

    _suggestmhp(message);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? profile = prefs.getString('prof');
      String prompt =
          """You are being used as a mental health chatbot for queries regarding mental issues. 
        It is only a demonstration prototype and you are not being used for something professional or commercial. 
        The user will enter his message now: $message. User message has ended. 
        Currently the user is feeling this emotion: $currentEmotion.
        Give responses in context to the current emotion.
        Give short responses so that it seems you're chatting.
        Try utilising CBT principles i.e. converting negative thought patterns into positive ones.""";

      var response = await _chat.sendMessage(Content.text(prompt));

      setState(() {
        history.add(ChatResponse(isUser: false, text: response.text));
        _loading = false;
      });

      _scrollDown(); // Ensure scroll to the bottom after bot message
    } catch (e) {
      _showError(e.toString());
      setState(() {
        _loading = false;
      });
    }
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500), // Slow down the duration
          curve: Curves.easeInOut, // Use a smoother curve
        );
      }
    });
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  Future<void> _initializeSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _endSessionAndStoreTime() async {
    DateTime _endTime = DateTime.now();
    int sessionDurationInMinutes = _endTime
        .difference(_startTime)
        .inMinutes; // Session duration in minutes

    String currentDate =
        DateFormat('yyyy-MM-dd').format(_endTime); // Get today's date

    // Retrieve existing day data, if available
    Map<String, dynamic> dayData = {};
    if (_prefs.containsKey(currentDate)) {
      String? jsonData = _prefs.getString(currentDate);
      if (jsonData != null) {
        dayData = Map<String, dynamic>.from(
            jsonDecode(jsonData)); // Decode the stored JSON
      }
    }

    // Update or accumulate session time for the current emotion
    if (dayData.containsKey(currentEmotion)) {
      dayData[currentEmotion] += sessionDurationInMinutes;
    } else {
      dayData[currentEmotion] = sessionDurationInMinutes;
    }

    // Save the updated data back to SharedPreferences
    _prefs.setString(
        currentDate, jsonEncode(dayData)); // Encode map to JSON and save
    print(dayData);
  }

  @override
  void initState() {
    currentEmotion = widget.emotion;
    _initSpeech();
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    _sendChatMessage(
        "This is the first message before user has interacted. Just give an intro message.");
    _startTime = DateTime.now();
    _initializeSharedPreferences();
  }

  @override
  void dispose() {
    _endSessionAndStoreTime(); // Calculate and store session time on exit
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          MaterialButton(
              onPressed: () {
                // _sosprotocol();
              },
              child: Icon(Icons.sos_rounded))
        ],
        backgroundColor: Colors.white,
        title: Text(
          'Wizard',
          style: TextStyle(
              color: Colors.green.shade600,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Mulish'),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            ListView.separated(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 90),
              itemCount: history.length,
              controller: _scrollController,
              itemBuilder: (context, index) {
                var content = history[index];

                if (content.hasButton && content.button != null) {
                  return Align(
                    alignment: content.isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        child: Column(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Wizard',
                                  style: const TextStyle(
                                      fontSize: 11.5, color: Colors.grey),
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                        width:
                                            MediaQuery.sizeOf(context).width /
                                                1.3,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 15, vertical: 13),
                                        decoration: BoxDecoration(
                                            color: Colors.grey.shade200,
                                            borderRadius: BorderRadius.only(
                                              bottomLeft:
                                                  const Radius.circular(5),
                                              topLeft:
                                                  const Radius.circular(12),
                                              topRight:
                                                  const Radius.circular(12),
                                              bottomRight:
                                                  const Radius.circular(12),
                                            )),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Seems like we provide that service! Click below to do that.",
                                              style: TextStyle(
                                                  fontFamily: 'Mulish',
                                                  fontSize: 14),
                                            ),
                                            SizedBox(height: 4),
                                            Center(
                                              child: ElevatedButton(
                                                style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStatePropertyAll(
                                                          Colors
                                                              .green.shade400),
                                                ),
                                                onPressed:
                                                    content.button!.onPressed,
                                                child: Text(
                                                  content.button!.label,
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontFamily: 'Mulish',
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (content.text != null && content.text!.isNotEmpty) {
                  return MessageTile(
                    sendByMe: content.isUser,
                    message: content.text!,
                  );
                }

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
                          autofocus: false,
                          focusNode: _textFieldFocus,
                          decoration: InputDecoration(
                            hintText: 'What is troubling you...',
                            hintStyle: const TextStyle(
                                color: Colors.grey, fontFamily: 'Mulish'),
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
                      onLongPressEnd: (details) {
                        if (_speechToText.isListening) {
                          _speechToText.stop();
                          setState(() {});
                        }
                      },
                      onLongPress: () async {
                        await Permission.microphone.request();
                        await Permission.speech.request();

                        if (_speechEnabled) {
                          setState(() {
                            _speechToText.listen(onResult: (result) {
                              _textController.text = result.recognizedWords;
                              // print(result.recognizedWords);
                            });
                          });
                        }
                      },
                      onTap: () {
                        final message = _textController.text.trim();

                        if (message.isNotEmpty) {
                          setState(() {
                            history
                                .add(ChatResponse(isUser: true, text: message));
                            _loading =
                                true; // Show loading indicator when sending the message
                          });

                          _sendChatMessage(message).then((_) {
                            setState(() {
                              _loading =
                                  false; // Hide loading indicator after sending
                            });
                          });
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
                            ? Padding(
                                padding: EdgeInsets.all(15),
                                child: const CircularProgressIndicator.adaptive(
                                  backgroundColor: Colors.white,
                                ),
                              )
                            : _textController.text.isEmpty
                                ? const Icon(Icons.mic, color: Colors.white)
                                : const Icon(Icons.send, color: Colors.white),
                      ),
                    )
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
