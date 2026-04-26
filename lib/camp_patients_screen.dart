import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db_helper.dart';
import 'sync_service.dart';

class CampPatientsScreen extends StatefulWidget {
  final Map camp;

  const CampPatientsScreen({super.key, required this.camp});

  @override
  State<CampPatientsScreen> createState() => _CampPatientsScreenState();
}

class _CampPatientsScreenState extends State<CampPatientsScreen> {

  // ================= GET DOCTOR ID =================
  // Future<int> getDoctorId() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   return prefs.getInt("doctor_id") ?? 0;
  // }
  Future<int> getDoctorId() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getInt("doctor_id");

  if (id == null || id == 0) {
    throw Exception("Doctor ID not found. User not logged in.");
  }

  return id;
}
  Future<List<Map<String, dynamic>>> getPatients() async {
    return DBHelper.getPatients(widget.camp["id"]);
  }

  // ================= ADD / EDIT =================

  Future<void> addOrEditPatient({Map? patient}) async {
    final name = TextEditingController(text: patient?["name"]);
    final age = TextEditingController(text: patient?["age"]?.toString());

    final gender = TextEditingController(text: patient?["gender"]);
    final location = TextEditingController(text: patient?["location"]);

    final symptoms = TextEditingController(text: patient?["symptoms"]);
    final diagnosis = TextEditingController(text: patient?["diagnosis"]);
    final medicines = TextEditingController(text: patient?["medicines"]);
    final advice = TextEditingController(text: patient?["advice"]);

    final temp = TextEditingController(text: patient?["temp"]);
    final bp = TextEditingController(text: patient?["bp"]);
    final pulse = TextEditingController(text: patient?["hr"]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF738CBD),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Clinical Entry",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const Chip(
                      label: Text("Auto Sync"),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    )
                  ],
                ),

                const SizedBox(height: 20),

                cardSection(
                  title: "Patient Info",
                  icon: Icons.person,
                  child: Column(
                    children: [
                      styledField(name, "Patient Name"),
                      const SizedBox(height: 10),
                      styledField(age, "Age", isNumber: true),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(child: styledField(gender, "Gender")),
                          const SizedBox(width: 10),
                          Expanded(child: styledField(location, "Location")),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                cardSection(
                  title: "Symptoms",
                  icon: Icons.sick,
                  child: styledMultiField(symptoms, "Enter symptoms"),
                ),

                const SizedBox(height: 15),

                cardSection(
                  title: "Vitals",
                  icon: Icons.monitor_heart,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      vitalField("Temp", temp),
                      vitalField("BP", bp),
                      vitalField("Pulse", pulse),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                cardSection(
                  title: "Diagnosis",
                  icon: Icons.medical_services,
                  child: styledMultiField(diagnosis, "Clinical diagnosis"),
                ),

                const SizedBox(height: 15),

                cardSection(
                  title: "Medicines",
                  icon: Icons.medication,
                  child: styledMultiField(medicines, "Prescribed medicines"),
                ),

                const SizedBox(height: 15),

                cardSection(
                  title: "Advice",
                  icon: Icons.notes,
                  child: styledMultiField(advice, "Doctor advice"),
                ),

                const SizedBox(height: 25),

                // SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (name.text.isEmpty) return;

                      int doctorId = await getDoctorId();

                      if (patient == null) {
                        await DBHelper.insertPatient({
                          "doctor_id": doctorId,
                          "camp_id": widget.camp["id"],
                          "name": name.text,
                          "age": int.tryParse(age.text) ?? 0,
                          "gender": gender.text,
                          "location": location.text,
                          "symptoms": symptoms.text,
                          "temp": temp.text,
                          "bp": bp.text,
                          "hr": pulse.text,
                          "diagnosis": diagnosis.text,
                          "medicines": medicines.text,
                          "advice": advice.text,
                          "visit_date": DateTime.now().toString(),
                          "synced": 0,
                        });
                      } else {
                        await DBHelper.updatePatient(patient["id"], {
                          "doctor_id": doctorId,
                          "name": name.text,
                          "age": int.tryParse(age.text) ?? 0,
                          "gender": gender.text,
                          "location": location.text,
                          "symptoms": symptoms.text,
                          "temp": temp.text,
                          "bp": bp.text,
                          "hr": pulse.text,
                          "diagnosis": diagnosis.text,
                          "medicines": medicines.text,
                          "advice": advice.text,
                          "synced": 0,
                        });
                      }

                      // 🔥 SYNC HERE
                      // await SyncService.syncPatients();
                      await SyncService.syncAll();
                      if (!mounted) return;
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text("SAVE RECORD"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= UI HELPERS =================

  Widget cardSection({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 18, color: Colors.teal),
            const SizedBox(width: 6),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget styledField(TextEditingController c, String hint, {bool isNumber = false}) {
    return TextField(
      controller: c,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget styledMultiField(TextEditingController c, String hint) {
    return TextField(
      controller: c,
      maxLines: 3,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget vitalField(String label, TextEditingController c) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          Text(label),
          TextField(controller: c, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ================= MAIN UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.camp["name"])),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addOrEditPatient(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder(
        future: getPatients(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final patients = snapshot.data as List<Map<String, dynamic>>;

          if (patients.isEmpty) {
            return const Center(child: Text("No patients added"));
          }

          return ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, i) {
              final p = patients[i];

              return ListTile(
                title: Text(p["name"]),
                subtitle: Text("Age: ${p["age"]}"),
                trailing: Icon(
                  p["synced"] == 1 ? Icons.cloud_done : Icons.cloud_off,
                  color: p["synced"] == 1 ? Colors.green : Colors.orange,
                ),
                onTap: () => addOrEditPatient(patient: p),
              );
            },
          );
        },
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'db_helper.dart';
// import 'package:fl_chart/fl_chart.dart';

// class CampPatientsScreen extends StatefulWidget {
//   final Map camp;
//   const CampPatientsScreen({super.key, required this.camp});

//   @override
//   State<CampPatientsScreen> createState() => _CampPatientsScreenState();
// }

// class _CampPatientsScreenState extends State<CampPatientsScreen> {
//   Future<List<Map<String, dynamic>>> getPatients() async {
//     return DBHelper.getPatients(widget.camp["id"]);
//   }

//   // ================= ADD / EDIT PATIENT =================
//   Future<void> addOrEditPatient({Map? patient}) async {
//     final name = TextEditingController(text: patient?["name"]);
//     final age = TextEditingController(text: patient?["age"]?.toString());
//     final gender = TextEditingController(text: patient?["gender"]);
//     final location = TextEditingController(text: patient?["location"]);
//     final symptoms = TextEditingController(text: patient?["symptoms"]);
//     final diagnosis = TextEditingController(text: patient?["diagnosis"]);
//     final medicines = TextEditingController(text: patient?["medicines"]);
//     final advice = TextEditingController(text: patient?["advice"]);
//     final temp = TextEditingController(text: patient?["temp"]);
//     final bp = TextEditingController(text: patient?["bp"]);
//     final pulse = TextEditingController(text: patient?["hr"]);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//         return Container(
//           padding: EdgeInsets.only(
//             left: 16,
//             right: 16,
//             top: 16,
//             bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//           ),
//           decoration: const BoxDecoration(
//             color: Color.fromARGB(255, 115, 140, 189),
//             borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 /// HEADER
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "Clinical Entry",
//                       style: TextStyle(
//                           fontSize: 22, fontWeight: FontWeight.bold),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 10, vertical: 6),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(20),
//                         color: Colors.green.shade100,
//                       ),
//                       child: const Text(
//                         "Auto Sync",
//                         style: TextStyle(color: Colors.green),
//                       ),
//                     )
//                   ],
//                 ),
//                 const SizedBox(height: 20),

//                 /// PATIENT INFO
//                 cardSection(
//                   title: "Patient Info",
//                   icon: Icons.person,
//                   child: Column(
//                     children: [
//                       styledField(name, "Patient Name"),
//                       const SizedBox(height: 10),
//                       styledField(age, "Age", isNumber: true),
//                       const SizedBox(height: 10),
//                       Row(
//                         children: [
//                           Expanded(child: styledField(gender, "Gender")),
//                           const SizedBox(width: 10),
//                           Expanded(child: styledField(location, "Location")),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 15),

//                 /// SYMPTOMS
//                 cardSection(
//                   title: "Symptoms",
//                   icon: Icons.sick,
//                   child: styledMultiField(symptoms, "Enter symptoms"),
//                 ),

//                 const SizedBox(height: 15),

//                 /// VITALS
//                 cardSection(
//                   title: "Vitals",
//                   icon: Icons.monitor_heart,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       vitalField("Temp", temp),
//                       vitalField("BP", bp),
//                       vitalField("Pulse", pulse),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 15),

//                 /// DIAGNOSIS
//                 cardSection(
//                   title: "Diagnosis",
//                   icon: Icons.medical_services,
//                   child: styledMultiField(
//                       diagnosis, "Clinical diagnosis"),
//                 ),

//                 const SizedBox(height: 15),

//                 /// MEDICINES
//                 cardSection(
//                   title: "Medicines",
//                   icon: Icons.medication,
//                   child: styledMultiField(
//                       medicines, "Prescribed medicines"),
//                 ),

//                 const SizedBox(height: 15),

//                 /// ADVICE
//                 cardSection(
//                   title: "Advice",
//                   icon: Icons.notes,
//                   child: styledMultiField(advice, "Doctor advice"),
//                 ),

//                 const SizedBox(height: 25),

//                 /// SAVE BUTTON
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       if (name.text.isEmpty) return;

//                       if (patient == null) {
//                         await DBHelper.insertPatient({
//                           "camp_id": widget.camp["id"],
//                           "name": name.text,
//                           "age": int.tryParse(age.text) ?? 0,
//                           "gender": gender.text,
//                           "location": location.text,
//                           "symptoms": symptoms.text,
//                           "temp": temp.text,
//                           "bp": bp.text,
//                           "hr": pulse.text,
//                           "diagnosis": diagnosis.text,
//                           "medicines": medicines.text,
//                           "advice": advice.text,
//                           "visit_date": DateTime.now().toString(),
//                           "synced": 0,
//                         });
//                       } else {
//                         await DBHelper.updatePatient(patient["id"], {
//                           "name": name.text,
//                           "age": int.tryParse(age.text) ?? 0,
//                           "gender": gender.text,
//                           "location": location.text,
//                           "symptoms": symptoms.text,
//                           "temp": temp.text,
//                           "bp": bp.text,
//                           "hr": pulse.text,
//                           "diagnosis": diagnosis.text,
//                           "medicines": medicines.text,
//                           "advice": advice.text,
//                           "synced": 0,
//                         });
//                       }

//                       Navigator.pop(context);
//                       setState(() {});
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.teal,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12)),
//                     ),
//                     child: const Text("SAVE RECORD"),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ================= HELPERS =================

//   Widget cardSection({
//     required String title,
//     required IconData icon,
//     required Widget child,
//   }) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//           )
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, size: 18, color: Colors.teal),
//               const SizedBox(width: 6),
//               Text(
//                 title,
//                 style: const TextStyle(fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget styledField(TextEditingController c, String hint,
//       {bool isNumber = false}) {
//     return TextField(
//       controller: c,
//       keyboardType:
//           isNumber ? TextInputType.number : TextInputType.text,
//       decoration: InputDecoration(
//         hintText: hint,
//         filled: true,
//         fillColor: Colors.grey.shade100,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }

//   Widget styledMultiField(TextEditingController c, String hint) {
//     return TextField(
//       controller: c,
//       maxLines: 3,
//       decoration: InputDecoration(
//         hintText: hint,
//         filled: true,
//         fillColor: Colors.grey.shade100,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(10),
//           borderSide: BorderSide.none,
//         ),
//       ),
//     );
//   }

//   Widget vitalField(String label, TextEditingController c) {
//     return SizedBox(
//       width: 90,
//       child: Column(
//         children: [
//           Text(label, style: const TextStyle(fontSize: 12)),
//           const SizedBox(height: 5),
//           TextField(
//             controller: c,
//             textAlign: TextAlign.center,
//             decoration: InputDecoration(
//               filled: true,
//               fillColor: Colors.grey.shade100,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(8),
//                 borderSide: BorderSide.none,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= MAIN UI =================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(widget.camp["name"]),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => addOrEditPatient(),
//         child: const Icon(Icons.add),
//       ),
//       body: FutureBuilder(
//         future: getPatients(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final patients =
//               snapshot.data as List<Map<String, dynamic>>;

//           if (patients.isEmpty) {
//             return const Center(child: Text("No patients added"));
//           }

//           return ListView.builder(
//             itemCount: patients.length,
//             itemBuilder: (context, i) {
//               final p = patients[i];
//               return ListTile(
//                 title: Text(p["name"]),
//                 subtitle: Text(
//                     "Age: ${p["age"]} | ${p["gender"] ?? ""}"),
//                 trailing: Icon(
//                   p["synced"] == 1
//                       ? Icons.cloud_done
//                       : Icons.cloud_off,
//                   color: p["synced"] == 1
//                       ? Colors.green
//                       : Colors.orange,
//                 ),
//                 onTap: () => addOrEditPatient(patient: p),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'db_helper.dart';
// import 'sync_service.dart';

// class CampPatientsScreen extends StatefulWidget {
//   final Map camp;

//   const CampPatientsScreen({super.key, required this.camp});

//   @override
//   State<CampPatientsScreen> createState() => _CampPatientsScreenState();
// }

// class _CampPatientsScreenState extends State<CampPatientsScreen> {

//   // ================= GET DOCTOR ID =================
//   Future<int> getDoctorId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt("doctor_id") ?? 0;
//   }

//   Future<List<Map<String, dynamic>>> getPatients() async {
//     return DBHelper.getPatients(widget.camp["id"]);
//   }

//   // ================= ADD / EDIT =================

//   Future<void> addOrEditPatient({Map? patient}) async {
//     final name = TextEditingController(text: patient?["name"]);
//     final age = TextEditingController(text: patient?["age"]?.toString());

//     final gender = TextEditingController(text: patient?["gender"]);
//     final location = TextEditingController(text: patient?["location"]);

//     final symptoms = TextEditingController(text: patient?["symptoms"]);
//     final diagnosis = TextEditingController(text: patient?["diagnosis"]);
//     final medicines = TextEditingController(text: patient?["medicines"]);
//     final advice = TextEditingController(text: patient?["advice"]);

//     final temp = TextEditingController(text: patient?["temp"]);
//     final bp = TextEditingController(text: patient?["bp"]);
//     final pulse = TextEditingController(text: patient?["hr"]);

//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) {
//         return Container(
//           padding: EdgeInsets.only(
//             left: 16,
//             right: 16,
//             top: 16,
//             bottom: MediaQuery.of(context).viewInsets.bottom + 20,
//           ),
//           decoration: const BoxDecoration(
//             color: Color(0xFF738CBD),
//             borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
//           ),
//           child: SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [

//                 // HEADER
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text("Clinical Entry",
//                         style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
//                     const Chip(
//                       label: Text("Auto Sync"),
//                       backgroundColor: Colors.green,
//                       labelStyle: TextStyle(color: Colors.white),
//                     )
//                   ],
//                 ),

//                 const SizedBox(height: 20),

//                 cardSection(
//                   title: "Patient Info",
//                   icon: Icons.person,
//                   child: Column(
//                     children: [
//                       styledField(name, "Patient Name"),
//                       const SizedBox(height: 10),
//                       styledField(age, "Age", isNumber: true),
//                       const SizedBox(height: 10),
//                       Row(
//                         children: [
//                           Expanded(child: styledField(gender, "Gender")),
//                           const SizedBox(width: 10),
//                           Expanded(child: styledField(location, "Location")),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 15),

//                 cardSection(
//                   title: "Symptoms",
//                   icon: Icons.sick,
//                   child: styledMultiField(symptoms, "Enter symptoms"),
//                 ),

//                 const SizedBox(height: 15),

//                 cardSection(
//                   title: "Vitals",
//                   icon: Icons.monitor_heart,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       vitalField("Temp", temp),
//                       vitalField("BP", bp),
//                       vitalField("Pulse", pulse),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 15),

//                 cardSection(
//                   title: "Diagnosis",
//                   icon: Icons.medical_services,
//                   child: styledMultiField(diagnosis, "Clinical diagnosis"),
//                 ),

//                 const SizedBox(height: 15),

//                 cardSection(
//                   title: "Medicines",
//                   icon: Icons.medication,
//                   child: styledMultiField(medicines, "Prescribed medicines"),
//                 ),

//                 const SizedBox(height: 15),

//                 cardSection(
//                   title: "Advice",
//                   icon: Icons.notes,
//                   child: styledMultiField(advice, "Doctor advice"),
//                 ),

//                 const SizedBox(height: 25),

//                 // SAVE BUTTON
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () async {
//                       if (name.text.isEmpty) return;

//                       int doctorId = await getDoctorId();

//                       if (patient == null) {
//                         await DBHelper.insertPatient({
//                           "doctor_id": doctorId,
//                           "camp_id": widget.camp["id"],
//                           "name": name.text,
//                           "age": int.tryParse(age.text) ?? 0,
//                           "gender": gender.text,
//                           "location": location.text,
//                           "symptoms": symptoms.text,
//                           "temp": temp.text,
//                           "bp": bp.text,
//                           "hr": pulse.text,
//                           "diagnosis": diagnosis.text,
//                           "medicines": medicines.text,
//                           "advice": advice.text,
//                           "visit_date": DateTime.now().toString(),
//                           "synced": 0,
//                         });
//                       } else {
//                         await DBHelper.updatePatient(patient["id"], {
//                           "doctor_id": doctorId,
//                           "name": name.text,
//                           "age": int.tryParse(age.text) ?? 0,
//                           "gender": gender.text,
//                           "location": location.text,
//                           "symptoms": symptoms.text,
//                           "temp": temp.text,
//                           "bp": bp.text,
//                           "hr": pulse.text,
//                           "diagnosis": diagnosis.text,
//                           "medicines": medicines.text,
//                           "advice": advice.text,
//                           "synced": 0,
//                         });
//                       }

//                       // 🔥 SYNC HERE
//                       await SyncService.syncPatients();

//                       Navigator.pop(context);
//                       setState(() {});
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.teal,
//                       padding: const EdgeInsets.symmetric(vertical: 16),
//                     ),
//                     child: const Text("SAVE RECORD"),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   // ================= UI HELPERS =================

//   Widget cardSection({required String title, required IconData icon, required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(14),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(children: [
//             Icon(icon, size: 18, color: Colors.teal),
//             const SizedBox(width: 6),
//             Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           ]),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget styledField(TextEditingController c, String hint, {bool isNumber = false}) {
//     return TextField(
//       controller: c,
//       keyboardType: isNumber ? TextInputType.number : TextInputType.text,
//       decoration: InputDecoration(
//         hintText: hint,
//         filled: true,
//         fillColor: Colors.grey.shade100,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   Widget styledMultiField(TextEditingController c, String hint) {
//     return TextField(
//       controller: c,
//       maxLines: 3,
//       decoration: InputDecoration(
//         hintText: hint,
//         filled: true,
//         fillColor: Colors.grey.shade100,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
//       ),
//     );
//   }

//   Widget vitalField(String label, TextEditingController c) {
//     return SizedBox(
//       width: 90,
//       child: Column(
//         children: [
//           Text(label),
//           TextField(controller: c, textAlign: TextAlign.center),
//         ],
//       ),
//     );
//   }

//   // ================= MAIN UI =================

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.camp["name"])),
//       floatingActionButton: FloatingActionButton(
//         onPressed: () => addOrEditPatient(),
//         child: const Icon(Icons.add),
//       ),
//       body: FutureBuilder(
//         future: getPatients(),
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return const Center(child: CircularProgressIndicator());
//           }

//           final patients = snapshot.data as List<Map<String, dynamic>>;

//           if (patients.isEmpty) {
//             return const Center(child: Text("No patients added"));
//           }

//           return ListView.builder(
//             itemCount: patients.length,
//             itemBuilder: (context, i) {
//               final p = patients[i];

//               return ListTile(
//                 title: Text(p["name"]),
//                 subtitle: Text("Age: ${p["age"]}"),
//                 trailing: Icon(
//                   p["synced"] == 1 ? Icons.cloud_done : Icons.cloud_off,
//                   color: p["synced"] == 1 ? Colors.green : Colors.orange,
//                 ),
//                 onTap: () => addOrEditPatient(patient: p),
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }