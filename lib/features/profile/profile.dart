import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // To use JSON encoding/decoding
import 'package:intl/intl.dart'; // To format dates and times

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Map to store profile values along with their date and time
  Map<String, String> profileMap = {};
  bool emptyNow = false;

  @override
  void initState() {
    super.initState();
    _populateProfile();
  }

  // Fetch profile from SharedPreferences
  void _populateProfile() async {
    final pref = await SharedPreferences.getInstance();
    String prefval = pref.getString('prof') ?? "";
    print("prefval $prefval");
    if (prefval.isEmpty || prefval=="{}") {
      setState(() {
        emptyNow = true;
      });
      return;
    }
    print(prefval);

    // Decode the JSON string into a map
    setState(() {
      profileMap = Map<String, String>.from(jsonDecode(prefval));
    });
    print(profileMap);
  }

  // Method to delete an entry
  void _deleteProfileValue(String key) async {
    final pref = await SharedPreferences.getInstance();

    // Remove the entry from the map
    setState(() {
      profileMap.remove(key);
    });

    // Encode the updated map and save it back to SharedPreferences
    String updatedProfile = jsonEncode(profileMap);
    pref.setString('prof', updatedProfile);
  }

  // Method to add a new profile value
  void _addProfileValue(String newValue) async {
    final pref = await SharedPreferences.getInstance();

    // Get the current date and time for uniqueness
    String currentDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    // Add the new profile value with the current date and time as the key
    setState(() {
      profileMap[currentDateTime] = newValue;
    });

    // Encode the map to JSON and save it
    String updatedProfile = jsonEncode(profileMap);
    pref.setString('prof', updatedProfile);
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
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  _addProfileValue(_controller.text);
                }
                setState(() {
                  emptyNow=false;
                });
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
              Navigator.pop(context);
            }),
        backgroundColor: Colors.green.shade400,
        title: const Text(
          "Profile",
          style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Mulish'),
        ),
        centerTitle: true,
      ),
      body: emptyNow
          ? Container(
              margin: const EdgeInsets.all(16),
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.shade100,
              ),
              child: const Center(
                child: Text(
                  'Add something about yourself!',
                  style: TextStyle(fontFamily: 'Mulish'),
                ),
              ),
            )
          : ListView.builder(
              itemCount: profileMap.length,
              itemBuilder: (context, index) {
                String key = profileMap.keys.elementAt(index);
                String value = profileMap[key]!;

                // Extract the date part from the key
                String datePart = key.split(' ')[0];

                return Padding(
                  padding: EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Color.fromARGB(255, 42, 119, 72), width: 2),
                    ),
                    padding: EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Created on : $datePart", // Display only the date
                                style: TextStyle(
                                  color: Color.fromARGB(255, 42, 119, 72),
                                  fontFamily: 'Mulish',
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                value, // Display the profile value
                                style: TextStyle(
                                  fontFamily: 'Mulish',
                                  fontSize: 16,
                                ),
                                maxLines: null,
                                overflow: TextOverflow.visible,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              _deleteProfileValue(key);
                              setState(() {
                                _populateProfile();
                              });
                            },
                            icon: Icon(Icons.delete,
                                color: Colors.yellow.shade700)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProfileDialog(context),
        backgroundColor: Colors.green.shade400,
        child: const Icon(Icons.add, color: Colors.white,),
      ),
    );
  }
}
