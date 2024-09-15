import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'package:wellwiz/features/appointments/doc_view.dart'; // Make sure to import the DocView page

class UserAppointmentsPage extends StatelessWidget {
  final String userId;

  const UserAppointmentsPage({super.key, required this.userId});

  // Function to delete an appointment
  Future<void> _deleteAppointment(String doctorId, String appointmentId) async {
    try {
      await FirebaseFirestore.instance
          .collection('doctor')
          .doc(doctorId)
          .collection('Appointments')
          .doc(appointmentId)
          .delete();
      Fluttertoast.showToast(msg: 'Appointment deleted successfully.');
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error deleting appointment: $e');
    }
  }

  // Function to fetch doctor name using doctorId
  Future<String> _getDoctorName(String doctorId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('doctor')
          .doc(doctorId)
          .get();
      return doc['name'] ?? 'Unknown Doctor';
    } catch (e) {
      return 'Unknown Doctor';
    }
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
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => DocView(userId: userId)),
              );
            }),
        backgroundColor: Colors.green.shade400,
        title: const Text(
          "My Appointments",
          style: TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('Appointments')
            .where('userId', isEqualTo: userId)
            .where('startTime', isGreaterThan: DateTime.now())
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Error loading appointments.'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No future appointments found.'));
          }

          final appointments = snapshot.data!.docs;

          return ListView.builder(
            itemCount: appointments.length,
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              final data = appointment.data() as Map<String, dynamic>;

              // Parse the appointment details
              final startTime = (data['startTime'] as Timestamp).toDate();
              final endTime = (data['endTime'] as Timestamp).toDate();
              final status = data['status'];
              final doctorId = appointment.reference.parent.parent!.id;
              final appointmentId = appointment.id;

              return FutureBuilder<String>(
                future: _getDoctorName(doctorId),
                builder: (context, doctorSnapshot) {
                  if (doctorSnapshot.connectionState == ConnectionState.waiting) {
                    return const ListTile(
                      title: Text('Loading...'),
                    );
                  }

                  if (doctorSnapshot.hasError) {
                    return const ListTile(
                      title: Text('Error loading doctor information'),
                    );
                  }

                  final doctorName = doctorSnapshot.data ?? 'Unknown Doctor';

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                    child: ListTile(
                      title: Text('Appointment on ${DateFormat.yMMMd().add_jm().format(startTime)}'),
                      subtitle: Text('Status: $status\nDoctor: $doctorName'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteAppointment(doctorId, appointmentId);
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
