import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Sample list of profile values, replace with actual values from SharedPreferences later
  List<String> profileValues = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _populateProfile();
  }

  void _populateProfile() async {
    final pref = await SharedPreferences.getInstance();
    String prefval = pref.getString('prof') ?? "";
    if (prefval == "") {
      return;
    }

    setState(() {
      profileValues = prefval.split(RegExp(r'[.\n]'));
      profileValues = profileValues
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    });
    print(profileValues);
  }

  // Method to delete an entry
  void _deleteProfileValue(int index) async {
    final pref = await SharedPreferences.getInstance();
    String prefval = pref.getString('prof')!;
    profileValues.removeAt(index);
    prefval=profileValues.join('.\n');
    pref.setString('prof',prefval);
    
    setState(() {
      // profileValues.removeAt(index);

      // Implement logic to update SharedPreferences here
    });
  }

  // Method to add a new profile value
  void _addProfileValue(String newValue) async {
    profileValues.add(newValue);
    final pref = await SharedPreferences.getInstance();
    String prefval = pref.getString('prof')!;
    String updatedval=prefval+".\n$newValue.\n";
    pref.setString('prof', updatedval);
    print(updatedval);
    setState(() {
      // Implement logic to update SharedPreferences here
    });
  }

  // Show a dialog to enter a new profile value
  void _showAddProfileDialog(BuildContext context) {
    TextEditingController _controller = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Profile Entry'),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: 'Enter profile detail'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addProfileValue(_controller.text);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
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
        leading: CupertinoButton(
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return const BotScreen();
              }));
            }),
        backgroundColor: Colors.green.shade400,
        title: const Text(
          "Profile",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: profileValues.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(profileValues[index]),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
                  _deleteProfileValue(index);
                },
              ),
            ),
          );
        },
      ),
      // Floating Action Button to add new profile values
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProfileDialog(context),
        backgroundColor: Colors.green.shade400,
        child: const Icon(Icons.add),
      ),
    );
  }
}
