import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'db_helper.dart';
import 'connectivity_service.dart';
import 'sync_service.dart';
import 'camp_patients_screen.dart';

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

  final pages = const [HomeScreen(), CalendarScreen(), ProfileScreen()];

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
                label: "Calendar",
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
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ],
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
              field(notes, "Notes"),
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
            colors: [Color(0xff4facfe), Color(0xff00f2fe)],
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

                // dashboard(),

                //const SizedBox(height: 16),

                // 🔍 SEARCH CAMPS
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

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(
              camp["name"],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text("📍 ${camp["location"] ?? "Unknown"}"),
                if (camp["doctor"] != null) Text("👨‍⚕️ ${camp["doctor"]}"),
                if (pending > 0)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$pending pending sync",
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
              ],
            ),

            // open patients inside this camp
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CampPatientsScreen(camp: camp),
                ),
              ).then((_) => setState(() {}));
            },

            trailing: PopupMenuButton(
              itemBuilder: (_) => const [
                PopupMenuItem(value: "edit", child: Text("Edit")),
                PopupMenuItem(value: "delete", child: Text("Delete")),
              ],
              onSelected: (value) async {
                if (value == "edit") {
                  addOrEditCamp(camp: camp);
                } else {
                  await DBHelper.deleteCamp(camp["id"]);
                  setState(() {});
                }
              },
            ),
          ),
        );
      },
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

//////////////////// CALENDAR ////////////////////

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime today = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [

          // 🌈 GRADIENT HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff4facfe), Color(0xff00f2fe)],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Camp Calendar",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "${today.day} / ${today.month} / ${today.year}",
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 📅 CALENDAR CARD
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              child: TableCalendar(
                focusedDay: today,
                firstDay: DateTime(2020),
                lastDay: DateTime(2035),

                selectedDayPredicate: (day) =>
                    isSameDay(day, today),

                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    today = selectedDay;
                  });
                },

                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.teal.shade300,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  weekendTextStyle:
                      const TextStyle(color: Colors.redAccent),
                ),

                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          // 📋 SELECTED DATE CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.event_available,
                    color: Colors.teal),
                title: const Text("Selected Date"),
                subtitle:
                    Text("${today.day}-${today.month}-${today.year}"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

//////////////////// PROFILE ////////////////////

//import 'package:flutter/material.dart';
//import 'db_helper.dart';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final name = TextEditingController();
  //  final hospital = TextEditingController();
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
      //hospital.text = data["hospital"] ?? "";
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
      // "hospital": hospital.text,
      "qualification": qualification.text,
      "specialization": specialization.text,
      "experience": experience.text,
      "phone": phone.text,
      "address": address.text,
    });

    setState(() => editMode = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Profile Saved")));
  }

  void cancelEdit() {
    editMode = false;
    loadProfile(); // reload old data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff43cea2), Color(0xff185a9d)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 30),

            /// TOP ACTION BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (editMode)
                  TextButton(
                    onPressed: cancelEdit,
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
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

            const SizedBox(height: 10),

            /// PROFILE ICON
            const CircleAvatar(
              radius: 45,
              backgroundColor: Colors.white,
              child: Icon(Icons.person, size: 50, color: Colors.teal),
            ),

            const SizedBox(height: 15),

            const Center(
              child: Text(
                "MAX CARE  ",
                style: TextStyle(
                  color: Color.fromARGB(255, 17, 7, 7),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 25),

            profileField(name, "Doctor Name"),
            //  profileField(hospital, "Hospital Name"),
            profileField(qualification, "Qualification"),
            profileField(specialization, "Specialization"),
            profileField(experience, "Experience"),
            profileField(phone, "Phone Number"),
            profileField(address, "Address"),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget profileField(TextEditingController controller, String label) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: controller,
        enabled: editMode,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
