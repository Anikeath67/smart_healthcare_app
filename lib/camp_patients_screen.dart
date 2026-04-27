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
  // doctor id getting from here

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

  // add or edit paitent from here

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
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold)),
                    const Chip(
                      label: Text("Auto Sync"),
                      backgroundColor: Color.fromARGB(255, 113, 144, 153),
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

                      // syncing with backend done here

                      await SyncService.syncAll();
                      if (!mounted) return;
                      Navigator.pop(context);
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 132, 158, 175),
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

  // paitent data entery ui

  Widget cardSection(
      {required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 238, 236, 236),
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

  Widget styledField(TextEditingController c, String hint,
      {bool isNumber = false}) {
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

  //    ui main body

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.camp["name"]),
        backgroundColor:  const Color.fromARGB(255, 143, 159, 172),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 143, 159, 172),
        onPressed: () => addOrEditPatient(),
        child: const Icon(Icons.add),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 51, 159, 236), 
              Color.fromARGB(255, 134, 175, 221), 
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder(
          future: getPatients(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final patients = snapshot.data as List<Map<String, dynamic>>;

            if (patients.isEmpty) {
              return const Center(child: Text("No patients added"));
            }

            return Column(
              children: [
                // 🔍 SEARCH BAR (UI only)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search patient...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                // 📋 LIST
                Expanded(
                  child: ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, i) {
                      final p = patients[i];

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(14),

                            // 👤 NAME
                            title: Text(
                              p["name"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),

                            // 📊 AGE
                            subtitle: Text(
                              "Age: ${p["age"]}",
                              style: const TextStyle(
                                color: Color(0xFF757575),
                              ),
                            ),

                            // 🔄 SYNC STATUS (UPGRADED)
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: p["synced"] == 1
                                    ? Colors.green.withOpacity(0.15)
                                    : Colors.orange.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    p["synced"] == 1
                                        ? Icons.cloud_done
                                        : Icons.cloud_upload,
                                    size: 18,
                                    color: p["synced"] == 1
                                        ? Colors.green
                                        : Colors.orange,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    p["synced"] == 1 ? "Synced" : "Pending",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: p["synced"] == 1
                                          ? Colors.green
                                          : Colors.orange,
                                    ),
                                  )
                                ],
                              ),
                            ),

                            onTap: () => addOrEditPatient(patient: p),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
