// import 'package:flutter/material.dart';

// class PatientDetailScreen extends StatelessWidget {
//   final Map patient;

//   const PatientDetailScreen({super.key, required this.patient});

//   @override
//   Widget build(BuildContext context) {
//     final symptoms = (patient["symptoms"] ?? "").toString().split(",");

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         title: const Text("Clinical Report"),
//         backgroundColor: Colors.blue,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// HEADER
//             const Text(
//               "CLINICAL ASSESSMENT",
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
//             ),

//             const SizedBox(height: 6),

//             Text(
//               "PATIENT: ${patient["name"] ?? "-"} (${patient["age"] ?? "-"})",
//               style: const TextStyle(color: Colors.grey),
//             ),

//             const SizedBox(height: 20),

//             /// SYMPTOMS
//             const Text(
//               "SYMPTOMS & PRESENTATION",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),

//             const Divider(),

//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: symptoms.map((s) {
//                 return Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 12,
//                     vertical: 6,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.blue.shade700,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: Text(
//                     s.trim().toUpperCase(),
//                     style: const TextStyle(color: Colors.white),
//                   ),
//                 );
//               }).toList(),
//             ),

//             const SizedBox(height: 15),

//             /// OTHER SYMPTOMS
//             const Text("OTHER SYMPTOMS", style: TextStyle(fontSize: 12)),

//             const SizedBox(height: 5),

//             Container(
//               width: double.infinity,
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Text(
//                 patient["other"] ?? "No additional symptoms",
//                 style: const TextStyle(color: Colors.grey),
//               ),
//             ),

//             const SizedBox(height: 15),

//             /// VITALS
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   vital("BP", patient["bp"]),
//                   vital("TEMP", patient["temp"], highlight: true),
//                   vital("SPO2", patient["spo2"]),
//                   vital("HR", patient["hr"]),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 20),

//             /// DIAGNOSIS
//             const Text(
//               "DIAGNOSIS",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),

//             const Divider(),

//             Text(patient["diagnosis"] ?? "Not available"),

//             const SizedBox(height: 20),

//             /// MEDICINES
//             const Text(
//               "MEDICINES",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),

//             const Divider(),

//             Text(patient["medicines"] ?? "Not available"),

//             const SizedBox(height: 20),

//             /// ADVICE
//             const Text("ADVICE", style: TextStyle(fontWeight: FontWeight.bold)),

//             const Divider(),

//             Text(patient["advice"] ?? "Not available"),

//             const SizedBox(height: 25),

//             /// SYNC STATUS
//             Center(
//               child: Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 6,
//                 ),
//                 decoration: BoxDecoration(
//                   color: patient["synced"] == 1 ? Colors.green : Colors.orange,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Text(
//                   patient["synced"] == 1 ? "SYNCED" : "PENDING SYNC",
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// VITAL UI
//   Widget vital(String label, dynamic value, {bool highlight = false}) {
//     return Column(
//       children: [
//         Text(label, style: const TextStyle(fontSize: 12)),
//         const SizedBox(height: 4),
//         Text(
//           value?.toString() ?? "-",
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             color: highlight ? Colors.red : Colors.black,
//           ),
//         ),
//       ],
//     );
//   }
// } 