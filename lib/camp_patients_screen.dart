import 'dart:ui';
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
    final advice = TextEditingController(text: patient?["advice"]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),

          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),

          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// HANDLE BAR
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                /// TITLE
                Text(
                  patient == null ? "Add Patient" : "Edit Patient",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                /// FORM FIELDS
                field(name, "Patient Name"),
                field(age, "Age"),
                field(symptoms, "Symptoms", maxLines: 4),
                field(diagnosis, "Diagnosis", maxLines: 4),
                field(medicines, "Medicines", maxLines: 3),
                field(advice, "Advice"),

                const SizedBox(height: 25),

                /// SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text("Save Patient"),

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),

                    onPressed: () async {
                      if (name.text.isEmpty) return;

                      if (patient == null) {
                        await DBHelper.insertPatient({
                          "camp_id": widget.camp["id"],
                          "name": name.text,
                          "age": int.tryParse(age.text) ?? 0,
                          "symptoms": symptoms.text,
                          "diagnosis": diagnosis.text,
                          "medicines": medicines.text,
                          "advice": advice.text,
                          "visit_date": DateTime.now().toString(),
                          "synced": 0,
                        });
                      } else {
                        await DBHelper.updatePatient(patient["id"], {
                          "name": name.text,
                          "age": int.tryParse(age.text) ?? 0,
                          "symptoms": symptoms.text,
                          "diagnosis": diagnosis.text,
                          "medicines": medicines.text,
                          "advice": advice.text,
                          "synced": 0,
                        });
                      }

                      Navigator.pop(context);
                      setState(() {});
                    },
                  ),
                ),

                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= DELETE =================

  Future<void> deletePatient(int id) async {
    await DBHelper.deletePatient(id);
    setState(() {});
  }

  // ================= PATIENT DETAIL =================

  void showPatientDetails(Map p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(p["name"]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            infoRow(Icons.sick, "Symptoms", p["symptoms"]),
            infoRow(Icons.medical_services, "Diagnosis", p["diagnosis"]),
            infoRow(Icons.medication, "Medicines", p["medicines"]),
            infoRow(Icons.notes, "Advice", p["advice"]),
          ],
        ),
      ),
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.camp["name"],

              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const Text(
              "Patient Entries",
              style: TextStyle(fontSize: 20, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 7, 12, 11),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: () => addOrEditPatient(),
        child: const Icon(Icons.person_add),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 50, 89, 141),
              Color.fromARGB(255, 99, 110, 124),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: FutureBuilder(
          future: getPatients(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            var patients = snapshot.data as List<Map<String, dynamic>>;

            patients = patients
                .where(
                  (p) => (p["name"] ?? "").toLowerCase().contains(
                    searchController.text.toLowerCase(),
                  ),
                )
                .toList();

            return Column(
              children: [
                const SizedBox(height: 10),

                // ================= SEARCH BAR =================
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),

                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),

                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),

                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(.3),
                          ),
                        ),

                        child: TextField(
                          controller: searchController,
                          onChanged: (_) => setState(() {}),

                          style: const TextStyle(color: Colors.white),

                          decoration: const InputDecoration(
                            hintText: "Search patients...",
                            hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white70,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ================= PATIENT LIST =================
                Expanded(
                  child: ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (_, i) {
                      var p = patients[i];
                      bool pending = p["synced"] == 0;

                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),

                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),

                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),

                            child: Container(
                              padding: const EdgeInsets.all(12),

                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(.15),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withOpacity(.3),
                                ),
                              ),

                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Colors.teal,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                  ),
                                ),

                                title: Text(
                                  p["name"] ?? "",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),

                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),

                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.medical_services,
                                          size: 16,
                                          color: Colors.white70,
                                        ),
                                        const SizedBox(width: 4),

                                        Expanded(
                                          child: Text(
                                            p["diagnosis"] ?? "",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    if (pending)
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),

                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),

                                        child: const Text(
                                          "Pending Sync",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),

                                trailing: PopupMenuButton(
                                  iconColor: Colors.white,
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: "edit",
                                      child: Text("Edit"),
                                    ),
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

                                onTap: () => showPatientDetails(p),
                              ),
                            ),
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

  // ================= INFO ROW =================

  Widget infoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 6),
          Expanded(child: Text("$title: $value")),
        ],
      ),
    );
  }

  // ================= FIELD =================

  Widget field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
