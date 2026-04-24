import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static Database? _db;

  // ================= DATABASE INIT =================

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await initDB();
    return _db!;
  }

  static Future<Database> initDB() async {
    String path = join(await getDatabasesPath(), 'healthcare_camps.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // CAMPS TABLE
        await db.execute('''
        CREATE TABLE camps(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          location TEXT,
          doctor TEXT,
          notes TEXT,
          date TEXT
        )
        ''');

        // PATIENTS TABLE
        await db.execute('''
        CREATE TABLE patients(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          camp_id INTEGER,
          name TEXT,
          age INTEGER,
          symptoms TEXT,

  bp TEXT,
  temp TEXT,
  spo2 TEXT,
  hr TEXT,
          diagnosis TEXT,
          medicines TEXT,
          advice TEXT,
          visit_date TEXT,
          synced INTEGER DEFAULT 0,
          FOREIGN KEY(camp_id) REFERENCES camps(id)
        )
        ''');

        // PROFILE TABLE
        await db.execute('''
        CREATE TABLE doctor_profile(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          doctor_name TEXT,
          qualification TEXT,
          specialization TEXT,
          experience TEXT,
          phone TEXT,
          address TEXT
        )
        ''');
      },
    );
  }

  // ================= CAMPS =================

  static Future insertCamp(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert("camps", data);
  }

  static Future<List<Map<String, dynamic>>> getCamps() async {
    final db = await database;
    return db.query("camps", orderBy: "id DESC");
  }

  static Future updateCamp(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update("camps", data, where: "id=?", whereArgs: [id]);
  }

  static Future deleteCamp(int id) async {
    final db = await database;

    await db.delete("patients", where: "camp_id=?", whereArgs: [id]);

    return db.delete("camps", where: "id=?", whereArgs: [id]);
  }

  // ✅ TOTAL CAMPS
  static Future<int> getCampCount() async {
    final db = await database;
    var result = await db.rawQuery("SELECT COUNT(*) FROM camps");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ================= PATIENTS =================

  static Future insertPatient(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert("patients", data);
  }

  static Future<List<Map<String, dynamic>>> getPatients(int campId) async {
    final db = await database;
    return db.query(
      "patients",
      where: "camp_id=?",
      whereArgs: [campId],
      orderBy: "id DESC",
    );
  }

  static Future updatePatient(int id, Map<String, dynamic> data) async {
    final db = await database;
    return db.update("patients", data, where: "id=?", whereArgs: [id]);
  }

  static Future deletePatient(int id) async {
    final db = await database;
    return db.delete("patients", where: "id=?", whereArgs: [id]);
  }

  // ================= SYNC =================

  static Future<int> getTotalPendingSync() async {
    final db = await database;
    var result = await db.rawQuery(
      "SELECT COUNT(*) FROM patients WHERE synced = 0",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> pendingSyncCount(int campId) async {
    final db = await database;
    var result = await db.rawQuery(
      "SELECT COUNT(*) FROM patients WHERE synced = 0 AND camp_id = ?",
      [campId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ================= PROFILE =================

  static Future saveProfile(Map<String, dynamic> data) async {
    final db = await database;

    var existing = await db.query("doctor_profile");

    if (existing.isEmpty) {
      return db.insert("doctor_profile", data);
    } else {
      return db.update(
        "doctor_profile",
        data,
        where: "id=?",
        whereArgs: [existing.first["id"]],
      );
    }
  }

  static Future<Map<String, dynamic>?> getProfile() async {
    final db = await database;
    var result = await db.query("doctor_profile");
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // ================= DASHBOARD =================

  // ✅ TOTAL PATIENTS
  static Future<int> getTotalPatients() async {
    final db = await database;
    var result = await db.rawQuery("SELECT COUNT(*) FROM patients");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ✅ TODAY VISITS
  static Future<int> getTodayPatients() async {
    final db = await database;

    final today = DateTime.now();

    String start =
        DateTime(today.year, today.month, today.day).toString();

    String end =
        DateTime(today.year, today.month, today.day, 23, 59, 59).toString();

    var result = await db.rawQuery(
      "SELECT COUNT(*) FROM patients WHERE visit_date BETWEEN ? AND ?",
      [start, end],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ✅ WEEKLY DATA
  static Future<List<int>> getWeeklyPatientData() async {
    final db = await database;

    List<int> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));

      String start =
          DateTime(date.year, date.month, date.day).toString();

      String end =
          DateTime(date.year, date.month, date.day, 23, 59, 59).toString();

      var result = await db.rawQuery(
        "SELECT COUNT(*) FROM patients WHERE visit_date BETWEEN ? AND ?",
        [start, end],
      );

      data.add(Sqflite.firstIntValue(result) ?? 0);
    }

    return data;
  }
}