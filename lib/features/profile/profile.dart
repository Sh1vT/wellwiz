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
  Map<String, String> profileMap = {};
  List<List<dynamic>> tableList = [];
  bool emptyNow = false;

  @override
  void initState() {
    super.initState();
    _populateProfile();
  }

  void _populateProfile() async {
    final pref = await SharedPreferences.getInstance();

    String prefval = pref.getString('prof') ?? "";
    if (prefval.isEmpty || prefval == "{}") {
      setState(() {
        emptyNow = true;
      });
    } else {
      setState(() {
        profileMap = Map<String, String>.from(jsonDecode(prefval));
      });
    }

    String? tableJson = pref.getString('table');
    if (tableJson != null && tableJson.isNotEmpty) {
      setState(() {
        tableList = List<List<dynamic>>.from(
            jsonDecode(tableJson).map((item) => List<dynamic>.from(item)));
      });
    }
  }

  void _deleteProfileValue(String key) async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      profileMap.remove(key);
    });
    String updatedProfile = jsonEncode(profileMap);
    pref.setString('prof', updatedProfile);
  }

  void _addProfileValue(String newValue) async {
    final pref = await SharedPreferences.getInstance();
    String currentDateTime =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

    setState(() {
      profileMap[currentDateTime] = newValue;
    });

    String updatedProfile = jsonEncode(profileMap);
    pref.setString('prof', updatedProfile);
  }

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
                  emptyNow = false;
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

  // Method to delete all table data
  void _deleteTableData() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      tableList.clear(); // Clear the tableList in memory
    });
    await pref.remove('table'); // Remove the 'table' key from SharedPreferences
  }

  Widget _buildTable() {
    if (tableList.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'No table data available',
          style: TextStyle(fontSize: 16, fontFamily: 'Mulish'),
        ),
      );
    }

    // Sort the tableList alphabetically by the first column (Fluid)
    tableList.sort((a, b) => a[0].compareTo(b[0]));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Table(
        border: TableBorder.all(color: Colors.green.shade400, width: 1),
        columnWidths: const <int, TableColumnWidth>{
          0: FlexColumnWidth(),
          1: FlexColumnWidth(),
          2: FixedColumnWidth(80),
        },
        children: [
          TableRow(
            decoration: BoxDecoration(
              color: Colors.green.shade100,
            ),
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Chemical',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Value',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Status',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          ...tableList.map((row) {
            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(row[0]), // Fluid
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(row[1]), // Value
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: () {
                    // Status Icon (arrows based on row[2] value)
                    if (row[2] == 1) {
                      return const Icon(Icons.arrow_upward, color: Colors.red);
                    } else if (row[2] == -1) {
                      return const Icon(Icons.arrow_downward, color: Colors.red);
                    } else {
                      return const Icon(Icons.thumb_up_sharp, color: Colors.green);
                    }
                  }(),
                ),
              ],
            );
          }).toList(),
        ],
      ),
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
          },
        ),
        backgroundColor: Colors.green.shade400,
        title: const Text(
          "Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Mulish',
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete, color: Colors.white),
            onPressed: () {
              _deleteTableData(); // Call the delete method when the button is pressed
            },
          ),
        ],
      ),
      body: SingleChildScrollView( // Wrap with SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Text(
                  'Health Metrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    fontFamily: 'Mulish',
                  ),
                ),
              ),
            ),
            _buildTable(), // Display the table of values

            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 16.0, top: 16, right: 16, bottom: 8),
                child: Text(
                  'Traits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                    fontFamily: 'Mulish',
                  ),
                ),
              ),
            ),
            emptyNow
                ? Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    physics: NeverScrollableScrollPhysics(), // Disable internal scroll
                    shrinkWrap: true, // Wrap content to avoid overflow
                    itemCount: profileMap.length,
                    itemBuilder: (context, index) {
                      String key = profileMap.keys.elementAt(index);
                      String value = profileMap[key]!;

                      String datePart = key.split(' ')[0];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Color.fromARGB(255, 42, 119, 72),
                                width: 2),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Created on : $datePart",
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 42, 119, 72),
                                        fontFamily: 'Mulish',
                                        fontSize: 12,
                                      ),
                                    ),
                                    Text(
                                      value,
                                      style: const TextStyle(
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
                                    color: Colors.yellow.shade700),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProfileDialog(context),
        backgroundColor: Colors.green.shade400,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
