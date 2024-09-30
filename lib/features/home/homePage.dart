import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back
          },
        ),
        backgroundColor: Colors.green.shade400,
        title: const Text(
          'Home',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // New Container with motivational thought and image on the right
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10.0), // Margin to prevent stretching
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
                border: Border.all(color: Colors.green, width: 2), // Green border
              ),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  // Text (Motivational thought)
                  const Expanded(
                    child: Text(
                      'Believe in yourself, every step forward counts.',
                      style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  // Rounded image using ClipOval, aligned to the right
                  ClipOval(
                    child: Image.asset(
                      'assets/images/wizard.png',
                      height: 80,
                      width: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Space between containers
            // First Container with wizard image and text
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                margin: const EdgeInsets.symmetric(horizontal: 24.0), // Margin to prevent stretching
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[200],
                  border: Border.all(color: Colors.green, width: 2), // Green border
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    // Rounded image using ClipOval
                    ClipOval(
                      child: Image.asset(
                        'assets/images/wizard.png',
                        height: 80,
                        width: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    // Text
                    const Expanded(
                      child: Text(
                        'Click to talk to wizard',
                        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20), // Space between containers
            // Second Container with buttons grid
            Container(
              padding: const EdgeInsets.all(16.0),
              margin: const EdgeInsets.symmetric(horizontal: 24.0), // Margin to prevent stretching
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[200],
                border: Border.all(color: Colors.green, width: 2), // Green border
              ),
              child: Column(
                children: <Widget>[
                  // Heading
                  const Text(
                    'How do you feel today?',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16.0),
                  // Grid of smaller buttons
                  GridView.count(
                    crossAxisCount: 2, // 2 buttons per row
                    shrinkWrap: true,
                    mainAxisSpacing: 10.0,
                    crossAxisSpacing: 10.0,
                    childAspectRatio: 3, // Adjust the button aspect ratio to make them smaller
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Happy'),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Sad'),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Angry'),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Anxious'),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Frustrated'),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        child: const Text('Stressed'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
