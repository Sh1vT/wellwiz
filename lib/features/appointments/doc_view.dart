import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:wellwiz/features/appointments/doc_tile.dart';


class DocView extends StatelessWidget{
  const DocView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade400,
        title: const Center(
          child: Text("Welcome user", 
              style: TextStyle(
                fontSize: 18,
                color: Colors.white
            ) 
          )
        )
      ),


      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            height: 70,
            color: Colors.green.shade400,
            child:  Row(
              children: [
                IconButton(onPressed: () {},
                 icon: const Icon(Icons.search)
                 ),
                const Expanded(
                  child: TextField(decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'Search for a doctor',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Colors.black
                      )
                    )
                    ),
                  ),
                ),
              ],
            )
          ),
          Expanded(
            child: ListView.builder(
              itemCount: doctors.length, // List of doctors
              itemBuilder: (context, index) {
                final doctor = doctors[index];
                return DoctorTile(doctor: doctor); // Use the DoctorTile widget
              },
            ),
          ),
        ],
      ),

    );
  }
}


final List<Doctor> doctors = [
  Doctor(name: "Dr. John Doe", specialty: "Cardiologist", degree: "MD", imageUrl: "assets\images\Doctor.png"),
  Doctor(name: "Dr. Jane Smith", specialty: "Dermatologist", degree: "MBBS", imageUrl: "assets\images\Doctor.png"),
  Doctor(name: "Dr. Emily Johnson", specialty: "Pediatrician", degree: "DNB", imageUrl: "assets\images\Doctor.png"),
  Doctor(name: "Dr. Michael Brown", specialty: "Orthopedic", degree: "MCh", imageUrl: "assets\images\Doctor.png"),
  Doctor(name: "Dr. Sarah Wilson", specialty: "General Practitioner", degree: "MBBS", imageUrl: "assets\images\Doctor.png"),
];