import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
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

  @override
  void initState() {
    super.initState();
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
    _chat = _model.startChat();
    _loadChatHistory();
    // _testFirestorePermissions();
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
      var response = await _chat.sendMessage(Content.text(message));

      // Debug: Log the response text
      print("Response from model: ${response.text}");

      setState(() {
        // Debug: Ensure correct keyword is detected
        if (response.text!.contains('health advice')) {
          print("Detected keyword: health advice");
          history.add(ChatResponse(
            isUser: false,
            hasButton: true,
            button: ChatButton(
              label: 'Get Health Advice',
              onPressed: () => _navigateToRoute('/health-advice'),
            ),
          ));
        } else if (response.text!.contains('appointment')) {
          print("Detected keyword: appointment");
          history.add(ChatResponse(
            isUser: false,
            hasButton: true,
            button: ChatButton(
              label: 'Book Appointment',
              onPressed: () => _navigateToRoute('/booking'),
            ),
          ));
        } else if (response.text!.contains('report')) {
          print("Detected keyword: report");
          history.add(ChatResponse(
            isUser: false,
            hasButton: true,
            button: ChatButton(
              label: 'Generate Report',
              onPressed: () => _navigateToRoute('/generate-report'),
            ),
          ));
        } else {
          history.add(ChatResponse(isUser: false, text: response.text));
        }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Bot'),
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
