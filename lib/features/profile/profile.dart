import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // To use JSON encoding/decoding
import 'package:intl/intl.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'package:wellwiz/features/navbar/navbar.dart';
import 'package:wellwiz/secrets.dart'; // To format dates and times

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, String> profileMap = {};
  List<List<dynamic>> tableList = [];
  List<List<dynamic>> prescriptionsList = [];
  bool emptyNow = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";
  late File _image;
  late final GenerativeModel _model;
  static const _apiKey = geminikey;
  late final ChatSession _chat;
  bool imageInitialized = false;

  final safetysettings = [
    SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
  ];

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
  }

  @override
  void initState() {
    super.initState();
    _populateProfile();
    _getUserInfo();
    _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        safetySettings: safetysettings);
    _chat = _model.startChat();
  }

  Future<void> getImageCamera(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Select Image Source",
            style: TextStyle(fontFamily: 'Mulish'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: Colors.green.shade600,
                ),
                title: const Text(
                  "Camera",
                  style: TextStyle(fontFamily: 'Mulish'),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await Permission.camera.request();
                  var image = await ImagePicker().pickImage(
                    source: ImageSource.camera,
                  );

                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                      imageInitialized = true;
                    });
                    print("sending");
                    _sendImageMessage();
                  } else {
                    Fluttertoast.showToast(msg: "No image selected");
                    debugPrint('No image selected.');
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo,
                  color: Colors.green.shade600,
                ),
                title: const Text(
                  "Gallery",
                  style: TextStyle(fontFamily: 'Mulish'),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  var image = await ImagePicker()
                      .pickImage(source: ImageSource.gallery);

                  if (image != null) {
                    setState(() {
                      _image = File(image.path);
                      imageInitialized = true;
                    });
                    print("sending");
                    _sendImageMessage();
                  } else {
                    Fluttertoast.showToast(msg: "No image selected");
                    debugPrint('No image selected.');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendImageMessage() async {
    final imgBytes = await _image.readAsBytes();
    final SharedPreferences pref = await SharedPreferences.getInstance();

    // Fetch the existing table list from SharedPreferences
    String? tableJson = pref.getString("table");
    List<List<dynamic>> tableList = [];

    if (tableJson != null && tableJson.isNotEmpty) {
      try {
        tableList = List<List<dynamic>>.from(
            jsonDecode(tableJson).map((item) => List<dynamic>.from(item)));
      } catch (e) {
        print("Error decoding JSON: $e");
      }
    }

    Fluttertoast.showToast(msg: "Extracting information...");

    // Constructing the modified prompt
    String prompt = """
  You are being used as a medical chatbot for demonstration purposes. 
  The user has submitted a medical report in image form, and you need to extract body chemical levels. 
  Here is the current table of body chemical levels stored as a JSON list: $tableList.

  Instructions:
  1. Extract the body chemical levels from the medical report and format them as "Title : Value : Integer" where:
    - "Title" is the name of the chemical or component. If it is written in short then write the full form or the more well-known version of that title.
    - "Value" is the numerical level.
    - "Integer" is 0, -1, or 1 depending on the following:
      - 0: Level is within the normal range
      - -1: Level is below the normal range
      - 1: Level is above the normal range

  2. Compare the extracted chemical levels against the provided table list. 
    - If a chemical level is missing from the table, or if its value has changed, return it in the response.
    - Only return those entries that either aren't found in the `tableList` or have updated values.

  Return the list of updated or new chemical levels in the format "Title : Value : Integer".
  If nothing is found, return "none".
  """;

    final content = [
      Content.multi([
        TextPart(prompt),
        DataPart('image/jpeg', imgBytes),
      ])
    ];

    final response = await _model.generateContent(content);
    final responseText = response.text!.toLowerCase().trim();

    // Debugging output
    print("Response: $responseText");

    if (responseText == "none") {
      Fluttertoast.showToast(msg: "No new or updated levels found.");
      return;
    }

    // Handle the response as plain text
    try {
      List<String> entries =
          responseText.split('\n').map((e) => e.trim()).toList();

      for (var entry in entries) {
        // Example entry: "Title : Value : Integer"
        List<String> parts = entry.split(':').map((e) => e.trim()).toList();

        if (parts.length == 3) {
          String title = parts[0];
          String value = parts[1];
          int flag = int.tryParse(parts[2]) ?? 0;

          // Check if the title already exists in the list, update if necessary
          bool found = false;
          for (var existingEntry in tableList) {
            if (existingEntry[0] == title) {
              if (existingEntry[1] != value || existingEntry[2] != flag) {
                // Update the existing entry if the value or flag has changed
                existingEntry[1] = value;
                existingEntry[2] = flag;
                print("Updated entry: $existingEntry"); // Debugging output
              }
              found = true;
              break;
            }
          }

          // If the title is not found, add a new entry
          if (!found) {
            tableList.add([title, value, flag]);
            print(
                "Added new entry: [${title}, ${value}, ${flag}]"); // Debugging output
          }
        } else {
          print("Unexpected entry format: $entry");
        }
      }

      // Save the updated list back to SharedPreferences
      tableJson = jsonEncode(tableList);
      await pref.setString('table', tableJson);
      print("Updated tableList: $tableList"); // Debugging output
      Fluttertoast.showToast(msg: "Updated levels added to table.");

      // Call setState to refresh the UI
      setState(() {});
    } catch (e) {
      Fluttertoast.showToast(msg: "An unknown error occurred!");
      print("Error parsing response: $e");
    }
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

    String? prescriptionsJson = pref.getString('prescriptions');
    if (prescriptionsJson != null && prescriptionsJson.isNotEmpty) {
      setState(() {
        prescriptionsList = List<List<dynamic>>.from(
            jsonDecode(prescriptionsJson)
                .map((item) => List<dynamic>.from(item)));
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

  void _deletePrescriptionData() async {
    final pref = await SharedPreferences.getInstance();
    setState(() {
      prescriptionsList.clear();
    });
    await pref.remove('prescriptions');
  }

  Widget _buildPrescriptionsTable() {
    if (prescriptionsList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.green.shade100,
        ),
        child: const Center(
          child: Text(
            textAlign: TextAlign.justify,
            'Tell WellWiz about your medicines!',
            style: TextStyle(fontFamily: 'Mulish'),
          ),
        ),
      );
    }

    // Sort the prescriptionsList alphabetically by the first column (Medication)
    prescriptionsList.sort((a, b) => a[0].compareTo(b[0]));

    return Table(
      border: TableBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Color.fromRGBO(106, 172, 67, 1),
            // Curved top border
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Medication',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Dosage',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
        ...prescriptionsList.map((row) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(row[0]), // Medication
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(row[1]), // Dosage
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTable() {
    if (tableList.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.green.shade100,
        ),
        child: const Center(
          child: Text(
            'Try scanning some reports!',
            style: TextStyle(fontFamily: 'Mulish'),
          ),
        ),
      );
    }

    tableList.sort((a, b) => a[0].compareTo(b[0]));

    return Table(
      border: TableBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      columnWidths: const <int, TableColumnWidth>{
        0: FlexColumnWidth(),
        1: FlexColumnWidth(),
        2: FixedColumnWidth(80),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Color.fromRGBO(106, 172, 67, 1),
            // Curved top border
          ),
          children: const [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Chemical',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Value',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Status',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
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
                    return const Icon(Icons.thumb_up_sharp,
                        color: Colors.green);
                  }
                }(),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: Navbar(
        userId: _auth.currentUser?.uid ?? '',
        username: username,
        userimg: userimg,
      ),
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Your",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      fontSize: 40,
                      color: Color.fromRGBO(106, 172, 67, 1)),
                ),
                Text(
                  " Profile",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      fontSize: 40,
                      color: const Color.fromRGBO(97, 97, 97, 1)),
                ),
              ],
            ),
            SizedBox(
              height: 12,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header Container
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              8), // Match with the main container
                          topRight: Radius.circular(
                              8), // Match with the main container
                        ),
                        color: Colors.grey.shade600,
                      ),
                      padding:
                          const EdgeInsets.all(8.0), // Padding for header text
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Space between text and icons
                        children: [
                          Expanded(
                            // Allow the text to occupy available space
                            child: Text(
                              'Health Metrics',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                          // Icons on the right
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.camera_alt,
                                    color: Colors.white), // Camera icon
                                onPressed: () {
                                  // Handle camera icon press
                                  getImageCamera(context);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.white), // Trash bin icon
                                onPressed: () {
                                  // Handle trash bin icon press
                                  _deleteTableData();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Table below the header
                    _buildTable(),
                  ],
                ),
              ),
            ),

            // Display the table of values

            SizedBox(
              height: 20,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header Container
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                              8), // Match with the main container
                          topRight: Radius.circular(
                              8), // Match with the main container
                        ),
                        color: Colors.grey.shade600,
                      ),
                      padding:
                          const EdgeInsets.all(8.0), // Padding for header text
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Space between text and icons
                        children: [
                          Expanded(
                            // Allow the text to occupy available space
                            child: Text(
                              'Prescriptions',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                          // Icons on the right
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.chat_outlined,
                                    color: Colors.white), // Camera icon
                                onPressed: () {
                                  // Handle camera icon press
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return BotScreen();
                                  }));
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: Colors.white), // Trash bin icon
                                onPressed: () {
                                  // Handle trash bin icon press
                                  _deletePrescriptionData();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Table below the header
                    _buildPrescriptionsTable(),
                  ],
                ),
              ),
            ), // Display the prescriptions table
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10), // Add horizontal padding to match styling
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade600, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Header for the list section
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                        color: Colors.grey.shade600,
                      ),
                      padding:
                          const EdgeInsets.all(8.0), // Padding for header text
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Space between text and icons
                        children: [
                          Expanded(
                            child: Text(
                              'Your Traits',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.add_box_outlined,
                                    color: Colors.white), // Camera icon
                                onPressed: () {
                                  // Handle camera icon press
                                  _showAddProfileDialog(context);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    // ListView for traits
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
                            physics:
                                NeverScrollableScrollPhysics(), // Disable internal scroll
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
                                    color: Color.fromARGB(255, 96, 168, 82),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Created on : $datePart",
                                              style: TextStyle(
                                                color: Colors.grey.shade100,
                                                fontFamily: 'Mulish',
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              value,
                                              style: const TextStyle(
                                                color: Colors.white,
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
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                    SizedBox(
                      height: 15,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }
}
