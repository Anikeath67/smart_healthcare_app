import 'package:flutter/material.dart';
import 'db_helper.dart';
import 'connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'camp_patients_screen.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DBHelper.database; // ✅ Init DB
  ConnectivityService.startListening(); // ✅ Auto sync

  runApp(const MyApp());
}

// ================= DOCTOR ID =================
Future<int> getDoctorId() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getInt("doctor_id") ?? 0;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(),
    );
  }
}

//////////////////// MAIN NAV ////////////////////

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

  // ❌ DO NOT USE const LIST
  final pages = [
    const HomeScreen(),
    const DashboardScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: pages[index],

      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            backgroundColor: const Color(0xFF018376),
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.white70,
            currentIndex: index,
            onTap: (i) => setState(() => index = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.local_hospital),
                label: "Camps",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_month),
                label: "Dashboard",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Profile",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//////////////////// HOME SCREEN ////////////////////

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

//////////////// DASHBOARD //////////////////

Widget dashboard() {
  return FutureBuilder(
    future: Future.wait([
      DBHelper.getCampCount(),
      DBHelper.getTotalPendingSync(),
    ]),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox();

      int camps = snapshot.data![0] as int;
      int pending = snapshot.data![1] as int;

      return Row(
        children: [
          Expanded(
            child: dashCard("Camps", camps.toString(),
                Icons.local_hospital, Colors.blue),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: dashCard("Sync", pending.toString(),
                Icons.sync_problem, Colors.orange),
          ),
        ],
      );
    },
  );
}

Widget dashCard(
    String title, String value, IconData icon, Color color) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: Colors.white.withOpacity(0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}

//////////////// MAIN STATE //////////////////

class _HomeScreenState extends State<HomeScreen> {
  final searchController = TextEditingController();

  Future<List<Map<String, dynamic>>> getCamps() async {
    return DBHelper.getCamps();
  }

  Future<void> addOrEditCamp({Map? camp}) async {
    final name = TextEditingController(text: camp?["name"]);
    final location = TextEditingController(text: camp?["location"]);
    final doctor = TextEditingController(text: camp?["doctor"]);
    final notes = TextEditingController(text: camp?["notes"]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(camp == null ? "Create Camp" : "Edit Camp"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              field(name, "Camp Name"),
              field(location, "Location"),
              field(doctor, "Doctor"),
              field(notes, "Notes", maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (camp == null) {
                await DBHelper.insertCamp({
                  "doctor_id": await getDoctorId(),
                  "name": name.text,
                  "location": location.text,
                  "doctor": doctor.text,
                  "notes": notes.text,
                  "date": DateTime.now().toString(),
                  "synced": 0,
                });
              } else {
                await DBHelper.updateCamp(camp["id"], {
                  "name": name.text,
                  "location": location.text,
                  "doctor": doctor.text,
                  "notes": notes.text,
                  "synced": 0,
                });
              }

              await SyncService.syncAll();
              if (!mounted) return;
              Navigator.pop(context);
            
              setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 70),
        child: FloatingActionButton(
          backgroundColor: Colors.teal,
          onPressed: () => addOrEditCamp(),
          child: const Icon(Icons.add),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF366288), Color(0xFF6A7681)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder(
          future: getCamps(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child:
                    CircularProgressIndicator(color: Colors.white),
              );
            }

            var camps =
                snapshot.data as List<Map<String, dynamic>>;

            if (searchController.text.isNotEmpty) {
              camps = camps
                  .where((c) => (c["name"] ?? "")
                      .toLowerCase()
                      .contains(
                          searchController.text.toLowerCase()))
                  .toList();
            }

            return ListView(
              padding:
                  const EdgeInsets.fromLTRB(16, 60, 16, 120),
              children: [
                const Text("Medical Camps",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),

                const SizedBox(height: 10),

                dashboard(),

                const SizedBox(height: 14),

                TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Search camps...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                ...camps.map((c) => campCard(c)).toList(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget campCard(Map camp) {
    return FutureBuilder<int>(
      future: DBHelper.pendingSyncCount(camp["id"]),
      builder: (context, snapshot) {
        int pending = snapshot.data ?? 0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                    color: Colors.white.withOpacity(0.3)),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Icon(Icons.local_hospital,
                      color: Colors.white),
                ),
                title: Text(
                  camp["name"],
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      "📍 ${camp["location"] ?? ""}",
                      style: const TextStyle(
                          color: Colors.white70),
                    ),
                    if (camp["doctor"] != null)
                      Text(
                        "👨‍⚕️ ${camp["doctor"]}",
                        style: const TextStyle(
                            color: Colors.white70),
                      ),
                    if (pending > 0)
                      Container(
                        margin:
                            const EdgeInsets.only(top: 6),
                        padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange
                              .withOpacity(0.8),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          "$pending pending sync",
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12),
                        ),
                      ),
                  ],
                ),
                trailing: PopupMenuButton(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                        value: "edit",
                        child: Text("Edit")),
                    PopupMenuItem(
                        value: "delete",
                        child: Text("Delete")),
                  ],
                  onSelected: (value) async {
                    if (value == "edit") {
                      addOrEditCamp(camp: camp);
                    } else if (value == "delete") {
                      await DBHelper.deleteCamp(
                          camp["id"]);
                      setState(() {});
                    }
                  },
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CampPatientsScreen(camp: camp),
                    ),
                  ).then((_) => setState(() {}));
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget field(TextEditingController c, String label,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

//////////////////// PROFILE ////////////////////



class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final name = TextEditingController();
  final qualification = TextEditingController();
  final specialization = TextEditingController();
  final experience = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();

  bool editMode = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  // 🔥 GET doctor_id
  Future<int> getDoctorId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("doctor_id") ?? 0;
  }

  // LOAD PROFILE
  Future<void> loadProfile() async {
    final data = await DBHelper.getProfile();

    if (data != null) {
      name.text = data["doctor_name"] ?? "";
      qualification.text = data["qualification"] ?? "";
      specialization.text = data["specialization"] ?? "";
      experience.text = data["experience"] ?? "";
      phone.text = data["phone"] ?? "";
      address.text = data["address"] ?? "";
      setState(() {});
    }
  }

  // SAVE PROFILE
  Future<void> saveProfile() async {
    int doctorId = await getDoctorId();

    await DBHelper.saveProfile({
      "doctor_id":  doctorId,
      "doctor_name": name.text,
      "qualification": qualification.text,
      "specialization": specialization.text,
      "experience": experience.text,
      "phone": phone.text,
      "address": address.text,
      "synced": 0,
    });

    await SyncService.syncAll();
    
  
    setState(() => editMode = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Profile Saved")),
    );
  }

  void logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 🔥 DASHBOARD COLOR APPLIED
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF018376),
              Color(0xFF015E57),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
          children: [

            // 🔷 HEADER
            Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    name.text.isEmpty ? "Doctor Profile" : name.text,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 4),

                  const Text(
                    "Healthcare Camp System",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🔷 EDIT BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (editMode)
                  TextButton(
                    onPressed: () {
                      editMode = false;
                      loadProfile();
                    },
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white)),
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                  ),
                  icon: Icon(editMode ? Icons.save : Icons.edit),
                  label: Text(editMode ? "Save" : "Edit"),
                  onPressed: () {
                    if (editMode) {
                      saveProfile();
                    } else {
                      setState(() => editMode = true);
                    }
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 🔷 PROFESSIONAL INFO
            sectionTitle("Professional Info"),
            glassCard(
              Column(
                children: [
                  field(name, "Doctor Name", Icons.person),
                  field(qualification, "Qualification", Icons.school),
                  field(specialization, "Specialization", Icons.medical_services),
                  field(experience, "Experience", Icons.timeline),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 🔷 CONTACT INFO
            sectionTitle("Contact Info"),
            glassCard(
              Column(
                children: [
                  field(phone, "Phone", Icons.phone),
                  field(address, "Address", Icons.location_on, maxLines: 3),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔴 LOGOUT
            ElevatedButton.icon(
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: logout,
            ),
          ],
        ),
      ),
    );
  }

  // 🔷 SECTION TITLE
  Widget sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // 🔷 GLASS CARD
  Widget glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }

  // 🔷 INPUT FIELD
  Widget field(TextEditingController controller, String label, IconData icon,
      {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        enabled: editMode,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.white),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: Colors.white.withOpacity(0.08),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final name = TextEditingController();
//   final qualification = TextEditingController();
//   final specialization = TextEditingController();
//   final experience = TextEditingController();
//   final phone = TextEditingController();
//   final address = TextEditingController();

//   bool editMode = false;

//   @override
//   void initState() {
//     super.initState();
//     loadProfile();
//   }

//   // 🔥 GET doctor_id
//   Future<int> getDoctorId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt("doctor_id") ?? 0;
//   }

//   // LOAD PROFILE
//   Future<void> loadProfile() async {
//     final data = await DBHelper.getProfile();

//     if (data != null) {
//       name.text = data["doctor_name"] ?? "";
//       qualification.text = data["qualification"] ?? "";
//       specialization.text = data["specialization"] ?? "";
//       experience.text = data["experience"] ?? "";
//       phone.text = data["phone"] ?? "";
//       address.text = data["address"] ?? "";
//       setState(() {});
//     }
//   }

//   // SAVE PROFILE
//   Future<void> saveProfile() async {
//     int doctorId = await getDoctorId();

//     await DBHelper.saveProfile({
//       "doctor_id": doctorId,
//       "doctor_name": name.text,
//       "qualification": qualification.text,
//       "specialization": specialization.text,
//       "experience": experience.text,
//       "phone": phone.text,
//       "address": address.text,
//       "synced": 0,
//     });

//     await SyncService.syncAll();

//     setState(() => editMode = false);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Profile Saved")),
//     );
//   }

//   void logout() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         // 🔥 DASHBOARD COLOR APPLIED
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color(0xFF018376),
//               Color(0xFF015E57),
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),

//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(20, 50, 20, 120),
//           children: [

//             // 🔷 HEADER
//             Center(
//               child: Column(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.3),
//                           blurRadius: 20,
//                         ),
//                       ],
//                     ),
//                     child: const CircleAvatar(
//                       radius: 50,
//                       backgroundColor: Colors.teal,
//                       child: Icon(Icons.person, size: 50, color: Colors.white),
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   Text(
//                     name.text.isEmpty ? "Doctor Profile" : name.text,
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),

//                   const SizedBox(height: 4),

//                   const Text(
//                     "Healthcare Camp System",
//                     style: TextStyle(color: Colors.white70),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 25),

//             // 🔷 EDIT BUTTON
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 if (editMode)
//                   TextButton(
//                     onPressed: () {
//                       editMode = false;
//                       loadProfile();
//                     },
//                     child: const Text("Cancel",
//                         style: TextStyle(color: Colors.white)),
//                   ),
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.black87,
//                   ),
//                   icon: Icon(editMode ? Icons.save : Icons.edit),
//                   label: Text(editMode ? "Save" : "Edit"),
//                   onPressed: () {
//                     if (editMode) {
//                       saveProfile();
//                     } else {
//                       setState(() => editMode = true);
//                     }
//                   },
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),

//             // 🔷 PROFESSIONAL INFO
//             sectionTitle("Professional Info"),
//             glassCard(
//               Column(
//                 children: [
//                   field(name, "Doctor Name", Icons.person),
//                   field(qualification, "Qualification", Icons.school),
//                   field(specialization, "Specialization", Icons.medical_services),
//                   field(experience, "Experience", Icons.timeline),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 16),

//             // 🔷 CONTACT INFO
//             sectionTitle("Contact Info"),
//             glassCard(
//               Column(
//                 children: [
//                   field(phone, "Phone", Icons.phone),
//                   field(address, "Address", Icons.location_on, maxLines: 3),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),

//             // 🔴 LOGOUT
//             ElevatedButton.icon(
//               icon: const Icon(Icons.logout),
//               label: const Text("Logout"),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.red,
//                 padding: const EdgeInsets.symmetric(vertical: 14),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//               onPressed: logout,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // 🔷 SECTION TITLE
//   Widget sectionTitle(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Text(
//         text,
//         style: const TextStyle(
//           color: Colors.white70,
//           fontSize: 14,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//     );
//   }

//   // 🔷 GLASS CARD
//   Widget glassCard(Widget child) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(18),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.15),
//             borderRadius: BorderRadius.circular(18),
//             border: Border.all(color: Colors.white.withOpacity(0.3)),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }

//   // 🔷 INPUT FIELD
//   Widget field(TextEditingController controller, String label, IconData icon,
//       {int maxLines = 1}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: TextField(
//         controller: controller,
//         enabled: editMode,
//         maxLines: maxLines,
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: Colors.white),
//           labelText: label,
//           labelStyle: const TextStyle(color: Colors.white70),
//           filled: true,
//           fillColor: Colors.white.withOpacity(0.08),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(14),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }
// }

// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({super.key});

//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }

// class _ProfileScreenState extends State<ProfileScreen> {
//   final name = TextEditingController();
//   final qualification = TextEditingController();
//   final specialization = TextEditingController();
//   final experience = TextEditingController();
//   final phone = TextEditingController();
//   final address = TextEditingController();

//   bool editMode = false;

//   @override
//   void initState() {
//     super.initState();
//     loadProfile();
//   }

//   /// 🔥 GET doctor_id
//   Future<int> getDoctorId() async {
//     final prefs = await SharedPreferences.getInstance();
//     return prefs.getInt("doctor_id") ?? 0;
//   }

//   /// LOAD LOCAL PROFILE
//   Future<void> loadProfile() async {
//     final data = await DBHelper.getProfile();

//     if (data != null) {
//       name.text = data["doctor_name"] ?? "";
//       qualification.text = data["qualification"] ?? "";
//       specialization.text = data["specialization"] ?? "";
//       experience.text = data["experience"] ?? "";
//       phone.text = data["phone"] ?? "";
//       address.text = data["address"] ?? "";
//       setState(() {});
//     }
//   }

//   /// 🔥 SAVE PROFILE (UPDATED)
//   Future<void> saveProfile() async {
//     int doctorId = await getDoctorId();

//     // ✅ SAVE LOCALLY
//     await DBHelper.saveProfile({
//       "doctor_id": doctorId,
//       "doctor_name": name.text,
//       "qualification": qualification.text,
//       "specialization": specialization.text,
//       "experience": experience.text,
//       "phone": phone.text,
//       "address": address.text,
//       "synced": 0,
//     });

//     // ✅ SYNC TO BACKEND
//     await SyncService.syncAll();

//     setState(() => editMode = false);

//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Profile Saved")),
//     );
//   }

//   void logout() {
//     Navigator.pushAndRemoveUntil(
//       context,
//       MaterialPageRoute(builder: (_) => const LoginScreen()),
//       (route) => false,
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             colors: [
//               Color.fromARGB(255, 54, 98, 136),
//               Color.fromARGB(255, 106, 118, 129),
//             ],
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//           ),
//         ),
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
//           children: [
//             /// PROFILE HEADER
//             Center(
//               child: Column(
//                 children: [
//                   CircleAvatar(
//                     radius: 45,
//                     backgroundColor: Colors.teal,
//                     child: const Icon(
//                       Icons.medical_services,
//                       size: 45,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     name.text.isEmpty ? "Doctor Profile" : name.text,
//                     style: const TextStyle(
//                       fontSize: 22,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const Text(
//                     "Healthcare Camp System",
//                     style: TextStyle(color: Colors.white70),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),

//             /// EDIT BUTTON
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 if (editMode)
//                   TextButton(
//                     onPressed: () {
//                       editMode = false;
//                       loadProfile();
//                     },
//                     child: const Text(
//                       "Cancel",
//                       style: TextStyle(color: Colors.white),
//                     ),
//                   ),
//                 ElevatedButton.icon(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.teal,
//                   ),
//                   icon: Icon(editMode ? Icons.save : Icons.edit),
//                   label: Text(editMode ? "Save" : "Edit"),
//                   onPressed: () {
//                     if (editMode) {
//                       saveProfile();
//                     } else {
//                       setState(() => editMode = true);
//                     }
//                   },
//                 ),
//               ],
//             ),

//             const SizedBox(height: 20),

//             /// FORM CARD
//             glassCard(
//               Column(
//                 children: [
//                   field(name, "Doctor Name", Icons.person),
//                   field(qualification, "Qualification", Icons.school),
//                   field(
//                       specialization, "Specialization", Icons.medical_services),
//                   field(experience, "Experience", Icons.timeline),
//                   field(phone, "Phone", Icons.phone),
//                   field(address, "Address", Icons.location_on, maxLines: 3),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 30),

//             /// LOGOUT BUTTON
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.logout),
//                 label: const Text("Logout"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 onPressed: logout,
//               ),
//             ),

//             const SizedBox(height: 120),
//           ],
//         ),
//       ),
//     );
//   }

//   /// GLASS CARD
//   Widget glassCard(Widget child) {
//     return ClipRRect(
//       borderRadius: BorderRadius.circular(20),
//       child: BackdropFilter(
//         filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//         child: Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Colors.white.withOpacity(0.15),
//             borderRadius: BorderRadius.circular(20),
//             border: Border.all(color: Colors.white.withOpacity(0.3)),
//           ),
//           child: child,
//         ),
//       ),
//     );
//   }

//   /// INPUT FIELD
//   Widget field(TextEditingController controller, String label, IconData icon,
//       {int maxLines = 1}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 14),
//       child: TextField(
//         controller: controller,
//         enabled: editMode,
//         maxLines: maxLines,
//         style: const TextStyle(color: Colors.white),
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: Colors.white),
//           labelText: label,
//           labelStyle: const TextStyle(color: Colors.white70),
//           filled: true,
//           fillColor: Colors.white.withOpacity(0.08),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(15),
//             borderSide: BorderSide.none,
//           ),
//         ),
//       ),
//     );
//   }
// }