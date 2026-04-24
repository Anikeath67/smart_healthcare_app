import 'package:flutter/material.dart';

import 'db_helper.dart';
import 'connectivity_service.dart';

import 'camp_patients_screen.dart';
import 'dart:ui';
import 'login_screen.dart';
import 'dashboard_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DBHelper.database;
  ConnectivityService.startListening();
  runApp(const MyApp());
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

//////////////////// MAIN NAVIGATION ////////////////////

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int index = 0;

   final pages = const [
  HomeScreen(),
  DashboardScreen(),
  ProfileScreen(),
];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // ⭐ required for floating effect
      body: pages[index],

      // ⭐ FLOATING NAV BAR
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            backgroundColor: const Color.fromARGB(255, 1, 131, 118),
            elevation: 0,
            selectedItemColor: const Color.fromARGB(255, 2, 12, 15),
            unselectedItemColor: const Color.fromARGB(255, 144, 160, 158),
            currentIndex: index,
            onTap: (i) => setState(() => index = i),
            type: BottomNavigationBarType.fixed,
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

// ================= DASHBOARD SUMMARY =================

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
            child: dashCard(
              "Total Camps",
              camps.toString(),
              Icons.local_hospital,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: dashCard(
              "Pending Sync",
              pending.toString(),
              Icons.sync_problem,
              Colors.orange,
            ),
          ),
        ],
      );
    },
  );
}

Widget dashCard(String title, String value, IconData icon, Color color) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(18),

    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),

      child: Container(
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15), // transparent panel

          borderRadius: BorderRadius.circular(18),

          border: Border.all(color: Colors.white.withOpacity(0.3)),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),

            const SizedBox(height: 8),

            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    ),
  );
}

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
              field(notes, "Notes", maxLines: 4),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (camp == null) {
                await DBHelper.insertCamp({
                  "name": name.text,
                  "location": location.text,
                  "doctor": doctor.text,
                  "notes": notes.text,
                  "date": DateTime.now().toString(),
                });
              } else {
                await DBHelper.updateCamp(camp["id"], {
                  "name": name.text,
                  "location": location.text,
                  "doctor": doctor.text,
                  "notes": notes.text,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add),
        onPressed: () => addOrEditCamp(),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 54, 98, 136),
              Color.fromARGB(255, 106, 118, 129),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FutureBuilder(
          future: getCamps(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            var camps = snapshot.data as List<Map<String, dynamic>>;

            camps = camps
                .where(
                  (c) => (c["name"] ?? "").toLowerCase().contains(
                    searchController.text.toLowerCase(),
                  ),
                )
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 60, 16, 100),
              children: [
                const Text(
                  "Medical Camps",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                // ⭐ DASHBOARD SUMMARY HERE
                dashboard(),

                const SizedBox(height: 16),

                TextField(
                  controller: searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Search camps...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                ElevatedButton.icon(
                  onPressed: () => addOrEditCamp(),
                  icon: const Icon(Icons.add),
                  label: const Text("Add New Camp"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                ...camps.map((camp) => campCard(camp)).toList(),
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
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: .3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .2),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ],
            ),

            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.teal,
                child: Icon(Icons.local_hospital, color: Colors.white),
              ),

              title: Text(
                camp["name"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),

                  Text(
                    "📍 ${camp["location"] ?? "Unknown"}",
                    style: const TextStyle(color: Colors.white70),
                  ),

                  if (camp["doctor"] != null)
                    Text(
                      "👨‍⚕️ ${camp["doctor"]}",
                      style: const TextStyle(color: Colors.white70),
                    ),

                  if (pending > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$pending pending sync",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              /// ⭐ EDIT / DELETE MENU ADDED
              trailing: PopupMenuButton(
                icon: const Icon(
                  Icons.more_vert,
                  color: Colors.white,
                ),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: "edit", child: Text("Edit")),
                  PopupMenuItem(value: "delete", child: Text("Delete")),
                ],
                onSelected: (value) async {
                  if (value == "edit") {
                    addOrEditCamp(camp: camp);
                  } else if (value == "delete") {
                    await DBHelper.deleteCamp(camp["id"]);
                    setState(() {});
                  }
                },
              ),

              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CampPatientsScreen(camp: camp),
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
  Widget field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: maxLines > 1
            ? TextInputType.multiline
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

//////////////////// CALENDAR ////////////////////

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

  Future<void> saveProfile() async {
    await DBHelper.saveProfile({
      "doctor_name": name.text,
      "qualification": qualification.text,
      "specialization": specialization.text,
      "experience": experience.text,
      "phone": phone.text,
      "address": address.text,
    });

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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 54, 98, 136),
              Color.fromARGB(255, 106, 118, 129),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
          children: [
            /// PROFILE HEADER
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.teal,
                    child: const Icon(
                      Icons.medical_services,
                      size: 45,
                      color: Colors.white,
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

                  const Text(
                    "Healthcare Camp System",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// EDIT BUTTON
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (editMode)
                  TextButton(
                    onPressed: () {
                      editMode = false;
                      loadProfile();
                    },
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
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

            /// FORM CARD
            glassCard(
              Column(
                children: [
                  field(name, "Doctor Name", Icons.person),
                  field(qualification, "Qualification", Icons.school),
                  field(
                      specialization, "Specialization", Icons.medical_services),
                  field(experience, "Experience", Icons.timeline),
                  field(phone, "Phone", Icons.phone),
                  field(address, "Address", Icons.location_on, maxLines: 3),
                ],
              ),
            ),

            const SizedBox(height: 30),

            /// LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
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
            ),

            /// 🔥 IMPORTANT FIX (SPACE FOR NAVBAR)
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  /// GLASS CARD
  Widget glassCard(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }

  /// INPUT FIELD
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
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}