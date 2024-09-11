import 'package:flutter/material.dart';
import 'booking.dart';

class Doctor {
  final String id; // Add doctor ID field
  final String name;
  final String speciality;
  final String degree;
  final String imageUrl;

  Doctor({
    required this.id, // Include ID in constructor
    required this.name,
    required this.speciality,
    required this.degree,
    required this.imageUrl,
  });

  factory Doctor.fromFirestore(String id, Map<String, dynamic> data) {
    return Doctor(
      id: id, // Set ID from Firestore document
      name: data['name'],
      speciality: data['speciality'],
      degree: data['degree'],
      imageUrl: data['imageUrl'],
    );
  }
}

class DoctorTile extends StatelessWidget {
  final Doctor doctor;
  final String userId; // Add userId parameter

  const DoctorTile({super.key, required this.doctor, required this.userId}); // Accept userId in the constructor

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
              const SizedBox(height: 10),
              Text("Speciality: ${doctor.speciality}"),
              Text("Degree: ${doctor.degree}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                // Call the booking method when 'Book Appointment' is clicked
                final appointmentService = AppointmentService();
                Navigator.of(context).pop(); // Close the dialog first
                await appointmentService.selectAndBookAppointment(context, doctor.id, userId); // Pass doctor.id instead of name
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
      onTap: () => _showDoctorDetails(context),
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
                doctor.speciality,
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
