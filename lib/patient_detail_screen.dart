import 'package:flutter/material.dart';

class PatientDetailScreen extends StatelessWidget {
  final Map patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Patient Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info("Name", patient["name"]),
                info("Age", patient["age"].toString()),
                info("Gender", patient["gender"]),
                info("Address", patient["address"]),
                info("Medicine", patient["medicine"]),
                info("Symptoms", patient["symptoms"]),
                info("Medical Camp", patient["camp"]),
                info("Visit Date", patient["visit_date"]),
                info(
                  "Sync Status",
                  patient["synced"] == 1 ? "Synced" : "Pending",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget info(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            "$title: ",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
