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
          diagnosis TEXT,
          medicines TEXT,
          dosage TEXT,
          advice TEXT,
          visit_date TEXT,
          synced INTEGER DEFAULT 0
        )
        ''');

        // DOCTOR PROFILE TABLE
        await db.execute('''
        CREATE TABLE doctor_profile(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          doctor_name TEXT,
          hospital TEXT,
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

    // delete patients under this camp first
    await db.delete("patients", where: "camp_id=?", whereArgs: [id]);

    return db.delete("camps", where: "id=?", whereArgs: [id]);
  }

  // ================= PATIENTS =================

  static Future insertPatient(Map<String, dynamic> data) async {
    final db = await database;
    return db.insert("patients", data);
  }

  // ⭐ get patients of selected camp
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

  // ================= DASHBOARD COUNTS =================

  static Future<int> getCampCount() async {
    final db = await database;
    var result = await db.rawQuery("SELECT COUNT(*) FROM camps");
    return Sqflite.firstIntValue(result) ?? 0;
  }

  static Future<int> getTotalPendingSync() async {
    final db = await database;
    var result = await db.rawQuery(
      "SELECT COUNT(*) FROM patients WHERE synced = 0",
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // pending sync count per camp
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
}
