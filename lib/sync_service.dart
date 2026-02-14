import 'dart:convert';
import 'package:http/http.dart' as http;
import 'db_helper.dart';

class SyncService {
  static const String BASE_URL = "http: 192.168.1.18:3000";

  static Future<void> syncCamp(int campId) async {
    final db = await DBHelper.database;

    final unsynced = await db.query(
      "patients",
      where: "camp_id=? AND synced=0",
      whereArgs: [campId],
    );

    for (var patient in unsynced) {
      try {
        final res = await http.post(
          Uri.parse("$BASE_URL/addPatient"),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(patient),
        );

        if (res.statusCode == 200) {
          await db.update(
            "patients",
            {"synced": 1},
            where: "id=?",
            whereArgs: [patient["id"]],
          );
        }
      } catch (_) {}
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
