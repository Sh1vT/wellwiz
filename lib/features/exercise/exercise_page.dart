import 'package:flutter/material.dart';
import 'exercise_screen.dart';

class ExerciseListPage extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Breathing Exercises',
          style: TextStyle(color: Colors.white, fontFamily: 'Mulish'),
        ),
        backgroundColor: Colors.green.shade400,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          return ExerciseCard(
            exercise: exercises[index],
            onTap: () {
              _showConfirmationDialog(context, exercises[index]);
            },
          );
        },
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
                  _showErrorDialog(context, 'Exercise steps not found for $exercise.');
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

class ExerciseCard extends StatelessWidget {
  final String exercise;
  final VoidCallback onTap;

  const ExerciseCard({
    Key? key,
    required this.exercise,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color cardColor = Color.fromARGB(255, 106, 172, 67);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: cardColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              exercise,
              style: const TextStyle(
                fontFamily: 'Mulish',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
