import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wellwiz/features/bot/bot_screen.dart';
import 'doc_tile.dart'; // Update with the correct path to doc_tile.dart

class DocView extends StatelessWidget {
  final String userId; // Add a field for userId

  const DocView(
      {super.key, required this.userId}); // Pass userId in the constructor

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
          "Our Doctors",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600, fontFamily: 'Mulish'),
        ),
        centerTitle: true,
      ),
      
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('doctor').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(child: Text("Error loading doctors"));
                }

                final List<Doctor> doctors = snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return Doctor.fromFirestore(
                      doc.id, data); // Pass the document ID
                }).toList();

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 tiles per row
                    mainAxisSpacing: 8, // Spacing between rows
                    crossAxisSpacing: 8, // Spacing between columns
                    childAspectRatio:
                        0.75, // Aspect ratio for tiles (width/height)
                  ),
                  padding: const EdgeInsets.all(16),
                  itemCount: doctors.length,
                  itemBuilder: (context, index) {
                    final doctor = doctors[index];
                    return DoctorTile(
                        doctor: doctor, userId: userId); // Pass userId here
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
