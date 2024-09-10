import 'package:flutter/material.dart';

class Doctor {
  final String name;
  final String specialty;
  final String degree; // Add degree field
  final String imageUrl;

  Doctor({
    required this.name,
    required this.specialty,
    required this.degree,
    required this.imageUrl,
  });
}


class DoctorTile extends StatelessWidget {
  final Doctor doctor;

  const DoctorTile({Key? key, required this.doctor}) : super(key: key);

  void _showDoctorDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(doctor.name),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 100, // Adjust size as needed
                width: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(doctor.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text("Specialty: ${doctor.specialty}"),
              Text("Degree: ${doctor.degree}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Handle booking appointment logic here
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Book Appointment"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDoctorDetails(context), // Show dialog on tap
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Column(
          children: [
            // Display the doctor's image
            Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: NetworkImage(doctor.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Doctor's name
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                doctor.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            // Doctor's specialty
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                doctor.specialty,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
