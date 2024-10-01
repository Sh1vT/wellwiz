import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellwiz/features/chatrooms/chatroom_screen.dart';

class ChatRoomSelectionScreen extends StatefulWidget {
  const ChatRoomSelectionScreen({super.key});

  @override
  _ChatRoomSelectionScreenState createState() => _ChatRoomSelectionScreenState();
}

class _ChatRoomSelectionScreenState extends State<ChatRoomSelectionScreen> {
  List<DocumentSnapshot> chatRooms = [];

  @override
  void initState() {
    super.initState();
    fetchChatRooms();
  }

  // Fetch existing chat rooms from Firestore
  void fetchChatRooms() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('chat_rooms').get();
    setState(() {
      chatRooms = snapshot.docs;
    });
  }

  // Create a new chat room
  void createNewChatRoom() async {
    DocumentReference newRoom = await FirebaseFirestore.instance.collection('chat_rooms').add({
      'created_at': FieldValue.serverTimestamp(),
    });
    // Navigate to the new chat room
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ChatRoomScreen(roomId: newRoom.id),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select or Create a Chat Room')),
      body: chatRooms.isEmpty
          ? Center(child: Text('No chat rooms available. Create one!'))
          : ListView.builder(
              itemCount: chatRooms.length,
              itemBuilder: (context, index) {
                var room = chatRooms[index];
                return ListTile(
                  title: Text('Chat Room ${room.id}'),
                  onTap: () {
                    // Navigate to the selected chat room
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => ChatRoomScreen(roomId: room.id),
                    ));
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewChatRoom,
        child: Icon(Icons.add),
        tooltip: 'Create New Chat Room',
      ),
    );
  }
}
