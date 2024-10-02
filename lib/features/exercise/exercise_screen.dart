import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ExerciseScreen extends StatefulWidget {
  final String exercise;

  ExerciseScreen({required this.exercise});

  @override
  _ExerciseScreenState createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  late Timer _timer;
  int _totalDuration = 0;
  int _elapsedTime = 0;
  int _instructionElapsedTime = 0; // New variable for instruction timing
  int _currentPhaseIndex = 0;
  String _currentInstruction = 'Get ready...';

  @override
  void initState() {
    super.initState();
    // Get total duration and ensure it's at least 60 seconds
    _totalDuration = getTotalDurationForExercise(widget.exercise) ?? 120;
    if (_totalDuration < 120) {
      _totalDuration = 120; // Ensure minimum duration is 60 seconds
    }
    startTimer();
  }

  int? getTotalDurationForExercise(String exercise) {
    return exerciseSteps[exercise]?.fold<int>(0, (total, step) => total + (step['duration'] as int));
  }

  void startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_elapsedTime < _totalDuration) {
          _elapsedTime++;
          _instructionElapsedTime++; // Increment instruction elapsed time independently
          updateCurrentInstruction();
        } else {
          // Show dialog when exercise is completed
          _showCompletionDialog();
          // Cancel the timer
          _timer.cancel();
        }
      });
    });
  }

  void updateCurrentInstruction() {
    if (exerciseSteps[widget.exercise] != null) {
      int totalSteps = exerciseSteps[widget.exercise]!.length;
      int timePassed = 0;

      // Update current instruction based on instruction elapsed time
      for (int i = 0; i < totalSteps; i++) {
        int stepDuration = exerciseSteps[widget.exercise]![i]['duration'] as int;
        if (_instructionElapsedTime >= timePassed && _instructionElapsedTime < timePassed + stepDuration) {
          _currentInstruction = exerciseSteps[widget.exercise]![i]['instruction'];
          _currentPhaseIndex = i;
          break;
        }
        timePassed += stepDuration;

        // Cycle back to the beginning if we reach the end
        if (i == totalSteps - 1 && _instructionElapsedTime >= timePassed) {
          _instructionElapsedTime -= totalSteps * stepDuration; // Reset instruction elapsed time for cycling
          _currentPhaseIndex = 0; // Reset current phase index
        }
      }
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Exercise Completed!'),
          content: Text('Great job! You have completed the exercise.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exercise),
        backgroundColor: Colors.green.shade400, // Match the style
      ),
      body: Container(
        width: screenWidth,
        height: screenHeight,
        color: Colors.white, // Background color for the page
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Instruction container
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _currentInstruction,
                style: TextStyle(fontSize: 24, color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 10),
            // Circular background for the animation
            Container(
              width: screenWidth * 0.6,
              height: screenWidth * 0.6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100, // Darker green for circular background
              ),
              child: Center(
                child: ClipOval(
                  child: Lottie.asset('assets/animations/breathing.json'),
                ),
              ),
            ),
            SizedBox(height: 20),
            // Timer container
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.green.shade400,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Time remaining: ${_totalDuration - _elapsedTime} seconds',
                style: TextStyle(fontSize: 20, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final Map<String, List<Map<String, dynamic>>> exerciseSteps = {
  'Deep Breathing': [
    {'instruction': 'Inhale deeply', 'duration': 8},
    {'instruction': 'Hold your breath', 'duration': 8},
    {'instruction': 'Exhale slowly', 'duration': 8},
  ],
  'Box Breathing': [
    {'instruction': 'Inhale for 6 seconds', 'duration': 6},
    {'instruction': 'Hold for 6 seconds', 'duration': 6},
    {'instruction': 'Exhale for 6 seconds', 'duration': 6},
    {'instruction': 'Hold for 6 seconds', 'duration': 6},
  ],
  '4-7-8 Breathing': [
    {'instruction': 'Inhale for 4 seconds', 'duration': 4},
    {'instruction': 'Hold for 7 seconds', 'duration': 7},
    {'instruction': 'Exhale for 8 seconds', 'duration': 8},
  ],
  'Alternate Nostril Breathing': [
    {'instruction': 'Close right nostril and inhale through left nostril', 'duration': 6},
    {'instruction': 'Hold breath, close both nostrils', 'duration': 6},
    {'instruction': 'Open right nostril and exhale', 'duration': 6},
    {'instruction': 'Repeat on the other side', 'duration': 6},
  ],
  // New exercises
  'Happy Breathing': [
    {'instruction': 'Inhale slowly while smiling', 'duration': 6},
    {'instruction': 'Hold the breath, focus on happy thoughts', 'duration': 8},
    {'instruction': 'Exhale while imagining joy spreading', 'duration': 6},
  ],
  'Calm Down Breathing': [
    {'instruction': 'Inhale slowly and deeply through the nose', 'duration': 5},
    {'instruction': 'Hold your breath', 'duration': 6},
    {'instruction': 'Exhale calmly through the mouth', 'duration': 7},
  ],
  'Stress Relief Breathing': [
    {'instruction': 'Inhale deeply, hold for a moment', 'duration': 6},
    {'instruction': 'Exhale slowly, releasing tension', 'duration': 6},
    {'instruction': 'Focus on releasing stress with each breath', 'duration': 6},
  ],
  'Relaxed Mind Breathing': [
    {'instruction': 'Inhale deeply through your nose', 'duration': 6},
    {'instruction': 'Hold and relax your mind', 'duration': 8},
    {'instruction': 'Exhale completely', 'duration': 8},
  ],
};
