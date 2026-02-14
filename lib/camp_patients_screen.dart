import 'package:flutter/material.dart';
import 'db_helper.dart';

class CampPatientsScreen extends StatefulWidget {
  final Map camp;

  const CampPatientsScreen({super.key, required this.camp});

  @override
  State<CampPatientsScreen> createState() => _CampPatientsScreenState();
}

class _CampPatientsScreenState extends State<CampPatientsScreen> {
  final searchController = TextEditingController();

  // ================= LOAD PATIENTS =================

  Future<List<Map<String, dynamic>>> getPatients() async {
    return DBHelper.getPatients(widget.camp["id"]);
  }

  // ================= ADD / EDIT PATIENT =================

  Future<void> addOrEditPatient({Map? patient}) async {
    final name = TextEditingController(text: patient?["name"]);
    final age = TextEditingController(text: patient?["age"]?.toString());
    final symptoms = TextEditingController(text: patient?["symptoms"]);
    final diagnosis = TextEditingController(text: patient?["diagnosis"]);
    final medicines = TextEditingController(text: patient?["medicines"]);
    final dosage = TextEditingController(text: patient?["dosage"]);
    final advice = TextEditingController(text: patient?["advice"]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(patient == null ? "Add Patient" : "Edit Patient"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              field(name, "Name"),
              field(age, "Age"),
              field(symptoms, "Symptoms"),
              field(diagnosis, "Diagnosis"),
              field(medicines, "Medicines"),
              field(dosage, "Dosage"),
              field(advice, "Advice"),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (name.text.isEmpty) return;

              if (patient == null) {
                // INSERT NEW PATIENT
                await DBHelper.insertPatient({
                  "camp_id": widget.camp["id"], // ⭐ link to camp
                  "name": name.text,
                  "age": int.tryParse(age.text) ?? 0,
                  "symptoms": symptoms.text,
                  "diagnosis": diagnosis.text,
                  "medicines": medicines.text,
                  "dosage": dosage.text,
                  "advice": advice.text,
                  "visit_date": DateTime.now().toString(),
                  "synced": 0,
                });
              } else {
                // UPDATE
                await DBHelper.updatePatient(patient["id"], {
                  "name": name.text,
                  "age": int.tryParse(age.text) ?? 0,
                  "symptoms": symptoms.text,
                  "diagnosis": diagnosis.text,
                  "medicines": medicines.text,
                  "dosage": dosage.text,
                  "advice": advice.text,
                  "synced": 0,
                });
              }

              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ================= DELETE =================

  Future<void> deletePatient(int id) async {
    await DBHelper.deletePatient(id);
    setState(() {});
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.camp["name"])),

      floatingActionButton: FloatingActionButton(
        onPressed: () => addOrEditPatient(),
        child: const Icon(Icons.person_add),
      ),

      body: FutureBuilder(
        future: getPatients(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          var patients = snapshot.data as List<Map<String, dynamic>>;

          // 🔍 SEARCH FILTER
          patients = patients
              .where(
                (p) => (p["name"] ?? "").toLowerCase().contains(
                  searchController.text.toLowerCase(),
                ),
              )
              .toList();

          return Column(
            children: [
              // SEARCH BAR
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Search patients...",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: patients.length,
                  itemBuilder: (_, i) {
                    var p = patients[i];
                    bool pending = p["synced"] == 0;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.person)),
                        title: Text(p["name"] ?? ""),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Diagnosis: ${p["diagnosis"] ?? ""}"),
                            if (pending)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  "Pending Sync",
                                  style: TextStyle(color: Colors.orange),
                                ),
                              ),
                          ],
                        ),

                        // 👁 VIEW DETAILS
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text(p["name"]),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Symptoms: ${p["symptoms"]}"),
                                  Text("Diagnosis: ${p["diagnosis"]}"),
                                  Text("Medicines: ${p["medicines"]}"),
                                  Text("Dosage: ${p["dosage"]}"),
                                  Text("Advice: ${p["advice"]}"),
                                ],
                              ),
                            ),
                          );
                        },

                        trailing: PopupMenuButton(
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: "edit", child: Text("Edit")),
                            PopupMenuItem(
                              value: "delete",
                              child: Text("Delete"),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == "edit") {
                              addOrEditPatient(patient: p);
                            } else {
                              deletePatient(p["id"]);
                            }
                          },
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
    );
  }

  Widget field(TextEditingController c, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
