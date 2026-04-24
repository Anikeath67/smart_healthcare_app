import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db_helper.dart';

class SyncService {
  static const String BASE_URL = "http://192.168.1.3:3000";

  static Future<void> syncCamp(int campId) async {
    final db = await DBHelper.database;

    final unsynced = await db.query(
      "patients",
      where: "camp_id=? AND synced=0",
      whereArgs: [campId],
    );

    for (var patient in unsynced) {
      try {
        print("🔄 Syncing: ${patient["name"]}");

        final response = await http
            .post(
              Uri.parse("$BASE_URL/addPatient"),
              headers: {"Content-Type": "application/json"},
              body: jsonEncode({
                "camp_id": patient["camp_id"],
                "name": patient["name"],
                "age": patient["age"],
                "symptoms": patient["symptoms"],
                "diagnosis": patient["diagnosis"],
                "medicines": patient["medicines"],
                "advice": patient["advice"],
                // ✅ FIX: ISO date format
                "visit_date": DateTime.parse(
                  patient["visit_date"].toString(),
                ).toIso8601String(),
              }),
            )
            .timeout(const Duration(seconds: 10));

        print("✅ Status: ${response.statusCode}");
        print("📦 Body: ${response.body}");

        if (response.statusCode == 200 || response.statusCode == 201) {
          await db.update(
            "patients",
            {"synced": 1},
            where: "id=?",
            whereArgs: [patient["id"]],
          );
          print("✔ Synced successfully");
        } else {
          print("❌ Server error");
        }
      } catch (e) {
        print("❌ Sync failed: $e");
      }
    }
  }

  static Future<void> syncAllCamps() async {
    final db = await DBHelper.database;
    final camps = await db.query("camps");

    for (var camp in camps) {
      await syncCamp(camp["id"] as int);
    }
  }
}
