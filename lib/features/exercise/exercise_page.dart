import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellwiz/features/navbar/navbar.dart';
import 'exercise_screen.dart';

class ExerciseListPage extends StatefulWidget {
  @override
  State<ExerciseListPage> createState() => _ExerciseListPageState();
}

class _ExerciseListPageState extends State<ExerciseListPage> {
  final List<String> exercises = [
    'Deep Breathing',
    'Box Breathing',
    '4-7-8 Breathing',
    'Alternate Nostril Breathing',
    'Happy Breathing',
    'Calm Down Breathing',
    'Stress Relief Breathing',
    'Relaxed Mind Breathing',
  ];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String username = "";
  String userimg = "";

  @override
  void initState() {
    super.initState();
    _getUserInfo();
  }

  void _getUserInfo() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    setState(() {
      username = pref.getString('username')!;
      userimg = pref.getString('userimg')!;
    });
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
        // Wrap the entire body in a SingleChildScrollView
        child: Column(
          children: [
            // Horizontal Scrollable Header
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Peace",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      fontSize: 40,
                      color: Color.fromRGBO(106, 172, 67, 1),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Zone",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Mulish',
                      fontSize: 40,
                      color: const Color.fromRGBO(97, 97, 97, 1),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            // Use a ListView inside a ConstrainedBox to limit its height
            ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: 300, // Set a minimum height for the list
              ),
              child: ListView.builder(
                physics:
                    NeverScrollableScrollPhysics(), // Disable scrolling for the ListView
                shrinkWrap: true, // Shrink the ListView to fit its contents
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  return ExerciseCard(
                    index: index,
                    exercise: exercises[index],
                    onTap: () {
                      _showConfirmationDialog(context, exercises[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(BuildContext context, String exercise) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start Exercise'),
          content: Text('Do you want to start $exercise?'),
          actions: <Widget>[
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                // Check if exercise exists in exerciseSteps before navigating
                if (exerciseSteps.containsKey(exercise)) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseScreen(exercise: exercise),
                    ),
                  );
                } else {
                  _showErrorDialog(
                      context, 'Exercise steps not found for $exercise.');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

final List<IconData> breathingIcons = [
  Icons.air, // Air icon
  Icons.fitness_center, // Fitness center icon
  Icons.spa, // Spa icon
  Icons.favorite, // Favorite icon
  Icons.accessibility, // Accessibility icon
  Icons.cloud, // Cloud icon
];

class ExerciseCard extends StatelessWidget {
  final String exercise; // The exercise name
  final VoidCallback onTap;
  final int index; // Add an index parameter

  const ExerciseCard({
    Key? key,
    required this.exercise,
    required this.onTap,
    required this.index, // Required index parameter
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Select the icon based on the index and cycle through the list
    IconData leadingIcon = breathingIcons[index % breathingIcons.length];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade300, // Changed to gray background
          borderRadius: BorderRadius.circular(12),
        ),
        padding:
            const EdgeInsets.all(8), // Padding consistent with appointment card
        child: ListTile(
          onTap: onTap,
          trailing: Icon(
            Icons.arrow_right_rounded, // Forward arrow icon
            color: Color.fromRGBO(106, 172, 67, 1),
            size: 30, // Color to match the theme
          ),
          leading: Icon(
            leadingIcon, // Use the selected icon
            size: 30,
            color: Color.fromRGBO(106, 172, 67, 1), // Match leading icon color
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exercise,
                style: const TextStyle(
                  fontFamily: 'Mulish',
                  fontSize: 16, // Use consistent font size
                  fontWeight: FontWeight.w600,
                  color: Colors.black, // Adjusted text color
                ),
              ),
              // Additional details can be added here if needed
            ],
          ),
        ),
      ),
    );
  }
}
