import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db_helper.dart';

class SyncService {
  static const String BASE_URL = "http://192.168.1.4:3000";

  // ================= PATIENT SYNC =================
  static Future<void> syncCamp(int campId) async {
    final db = await DBHelper.database;

    final unsynced = await db.query(
      "patients",
      where: "camp_id=? AND synced=0",
      whereArgs: [campId],
    );

    for (var patient in unsynced) {
      try {
        final response = await http.post(
          Uri.parse("$BASE_URL/patients"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "doctor_id": patient["doctor_id"],
            "camp_id": patient["camp_id"],
            "name": patient["name"],
            "age": patient["age"],
            "gender": patient["gender"],
            "location": patient["location"],
            "symptoms": patient["symptoms"],
            "temp": patient["temp"],
            "bp": patient["bp"],
            "hr": patient["hr"],
            "diagnosis": patient["diagnosis"],
            "medicines": patient["medicines"],
            "advice": patient["advice"],
            "visit_date": DateTime.parse(
              patient["visit_date"].toString(),
            ).toIso8601String(),
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await db.update(
            "patients",
            {"synced": 1},
            where: "id=?",
            whereArgs: [patient["id"]],
          );
        }
      } catch (e) {
        print("Patient sync error: $e");
      }
    }
  }

  // ================= ALL PATIENTS =================
  static Future<void> syncAllPatients() async {
    final db = await DBHelper.database;

    final camps = await db.query("camps");

    for (var camp in camps) {
      await syncCamp(camp["id"] as int);
    }
  }

  // ================= CAMP SYNC =================
  static Future<void> syncCamps() async {
    final db = await DBHelper.database;

    final camps = await db.query(
      "camps",
      where: "synced=0",
    );

    for (var camp in camps) {
      try {
        final response = await http.post(
          Uri.parse("$BASE_URL/camps"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "doctor_id": camp["doctor_id"],
            "name": camp["name"],
            "location": camp["location"],
            "doctor": camp["doctor"],
            "notes": camp["notes"],
            "date": camp["date"],
          }),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await db.update(
            "camps",
            {"synced": 1},
            where: "id=?",
            whereArgs: [camp["id"]],
          );
        }
      } catch (e) {
        print("Camp sync error: $e");
      }
    }
  }

  // ================= PROFILE SYNC =================
  // static Future<void> syncProfile() async {
  //   final db = await DBHelper.database;

  //   final profile = await db.query("doctor_profile");

  //   if (profile.isEmpty) return;

  //   final p = profile.first;

  //   try {
  //     final response = await http.put(
  //       Uri.parse("$BASE_URL/doctor/${p["doctor_id"]}"),
  //       headers: {"Content-Type": "application/json"},
  //       body: jsonEncode({
  //         "name": p["doctor_name"],
  //         "qualification": p["qualification"],
  //         "specialization": p["specialization"],
  //         "experience": p["experience"],
  //         "phone": p["phone"],
  //         "address": p["address"],
  //       }),
  //     );

  //     print("Profile sync: ${response.statusCode}");
  //   } catch (e) {
  //     print("Profile sync error: $e");
  //   }
  // }
  static Future<void> syncProfile() async {
  final db = await DBHelper.database;

  final profile = await db.query("doctor_profile");

  if (profile.isEmpty) return;

  final p = profile.first;
  print("PROFILE DATA: $p"); 
  try {
    final response = await http.put(
      Uri.parse("$BASE_URL/doctor/${p["doctor_id"]}"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": p["doctor_name"],
        "qualification": p["qualification"],
        "specialization": p["specialization"],
        "experience": p["experience"],
        "phone": p["phone"],
        "address": p["address"],
      }),
    );

    print("Profile sync: ${response.statusCode}");

    // ✅ MOVE THIS HERE (INSIDE FUNCTION)
    if (response.statusCode == 200) {
      await db.update(
        "doctor_profile",
        {"synced": 1},
        where: "id=?",
        whereArgs: [p["id"]],
      );
    }

  } catch (e) {
    print("Profile sync error: $e");
  }
}
  
  // ================= MAIN SYNC =================
  static Future<void> syncAll() async {
    await syncProfile();     // doctor
    await syncCamps();       // camps
    await syncAllPatients(); // patients
  }
}
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'db_helper.dart';

// class SyncService {
//   static const String BASE_URL = "http://192.168.1.5:3000";

//   // ================= PROFILE SYNC =================
//   static Future<void> syncProfile() async {
//     final db = await DBHelper.database;

//     final profile = await db.query(
//       "doctor_profile",
//       where: "synced = 0",
//     );

//     if (profile.isEmpty) {
//       print("❌ No unsynced profile");
//       return;
//     }

//     for (var p in profile) {
//       try {
//         print("🔄 Syncing doctor: ${p["doctor_id"]}");

//         final response = await http.put(
//           Uri.parse("$BASE_URL/doctor/${p["doctor_id"]}"),
//           headers: {"Content-Type": "application/json"},
//           body: jsonEncode({
//             "name": p["doctor_name"],
//             "qualification": p["qualification"],
//             "specialization": p["specialization"],
//             "experience": p["experience"],
//             "phone": p["phone"],
//             "address": p["address"],
//           }),
//         );

//         print("Status: ${response.statusCode}");
//         print("Body: ${response.body}");

//         if (response.statusCode == 200) {
//           // ✅ IMPORTANT FIX
//           await db.update(
//             "doctor_profile",
//             {"synced": 1},
//             where: "id=?",
//             whereArgs: [p["id"]],
//           );

//           print("✅ Profile synced");
//         } else {
//           print("❌ Sync failed");
//         }
//       } catch (e) {
//         print("❌ Profile sync error: $e");
//       }
//     }
//   }

//   // ================= PATIENT SYNC =================
//   static Future<void> syncCamp(int campId) async {
//     final db = await DBHelper.database;

//     final unsynced = await db.query(
//       "patients",
//       where: "camp_id=? AND synced=0",
//       whereArgs: [campId],
//     );

//     for (var patient in unsynced) {
//       try {
//         final response = await http.post(
//           Uri.parse("$BASE_URL/patients"),
//           headers: {"Content-Type": "application/json"},
//           body: jsonEncode({
//             "doctor_id": patient["doctor_id"],
//             "camp_id": patient["camp_id"],
//             "name": patient["name"],
//             "age": patient["age"],
//             "gender": patient["gender"],
//             "location": patient["location"],
//             "symptoms": patient["symptoms"],
//             "temp": patient["temp"],
//             "bp": patient["bp"],
//             "hr": patient["hr"],
//             "diagnosis": patient["diagnosis"],
//             "medicines": patient["medicines"],
//             "advice": patient["advice"],
//             "visit_date": DateTime.parse(
//               patient["visit_date"].toString(),
//             ).toIso8601String(),
//           }),
//         );

//         if (response.statusCode == 200 || response.statusCode == 201) {
//           await db.update(
//             "patients",
//             {"synced": 1},
//             where: "id=?",
//             whereArgs: [patient["id"]],
//           );
//         }
//       } catch (e) {
//         print("Patient sync error: $e");
//       }
//     }
//   }

//   // ================= ALL PATIENTS =================
//   static Future<void> syncAllPatients() async {
//     final db = await DBHelper.database;
//     final camps = await db.query("camps");

//     for (var camp in camps) {
//       await syncCamp(camp["id"] as int);
//     }
//   }

//   // ================= CAMP SYNC =================
//   static Future<void> syncCamps() async {
//     final db = await DBHelper.database;

//     final camps = await db.query(
//       "camps",
//       where: "synced=0",
//     );

//     for (var camp in camps) {
//       try {
//         final response = await http.post(
//           Uri.parse("$BASE_URL/camps"),
//           headers: {"Content-Type": "application/json"},
//           body: jsonEncode({
//             "doctor_id": camp["doctor_id"],
//             "name": camp["name"],
//             "location": camp["location"],
//             "doctor": camp["doctor"],
//             "notes": camp["notes"],
//             "date": camp["date"],
//           }),
//         );

//         if (response.statusCode == 200 || response.statusCode == 201) {
//           await db.update(
//             "camps",
//             {"synced": 1},
//             where: "id=?",
//             whereArgs: [camp["id"]],
//           );
//         }
//       } catch (e) {
//         print("Camp sync error: $e");
//       }
//     }
//   }

//   // ================= MAIN SYNC =================
//   static Future<void> syncAll() async {
//     print("🔥 SYNC STARTED");

//     await syncProfile();     // ✅ FIRST
//     await syncCamps();
//     await syncAllPatients();
//   }
// }