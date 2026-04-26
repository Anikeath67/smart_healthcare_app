// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// class DBHelper {
//   static Database? _db;

//   // ================= INIT =================
//   static Future<Database> get database async {
//     if (_db != null) return _db!;
//     _db = await initDB();
//     return _db!;
//   }

//   static Future<Database> initDB() async {
//     String path = join(await getDatabasesPath(), 'healthcare_camps.db');

//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {

//         // ================= CAMPS =================
//         await db.execute('''
//         CREATE TABLE camps(
//           id INTEGER PRIMARY KEY AUTOINCREMENT,
//           doctor_id INTEGER,
//           name TEXT,
//           location TEXT,
//           doctor TEXT,
//           notes TEXT,
//           date TEXT,
//           synced INTEGER DEFAULT 0
//         )
//         ''');

//         // ================= PATIENTS =================
//         await db.execute('''
//         CREATE TABLE patients(
//           id INTEGER PRIMARY KEY AUTOINCREMENT,
//           doctor_id INTEGER,
//           camp_id INTEGER,
//           name TEXT,
//           age INTEGER,
//           gender TEXT,
//           location TEXT,
//           symptoms TEXT,
//           bp TEXT,
//           temp TEXT,
//           spo2 TEXT,
//           hr TEXT,
//           diagnosis TEXT,
//           medicines TEXT,
//           advice TEXT,
//           visit_date TEXT,
//           synced INTEGER DEFAULT 0
//         )
//         ''');

//         // ================= PROFILE =================
//         await db.execute('''
//         CREATE TABLE doctor_profile(
//           id INTEGER PRIMARY KEY AUTOINCREMENT,
//           doctor_id INTEGER,
//           doctor_name TEXT,
//           email TEXT,
//           qualification TEXT,
//           specialization TEXT,
//           experience TEXT,
//           phone TEXT,
//           address TEXT,
//           synced INTEGER DEFAULT 0
//         )
//         ''');
//       },
//     );
//   }

//   // ================= CAMPS =================

//   static Future insertCamp(Map<String, dynamic> data) async {
//     final db = await database;
//     data["synced"] = 0;
//     return db.insert("camps", data);
//   }

//   static Future<List<Map<String, dynamic>>> getCamps() async {
//     final db = await database;
//     return db.query("camps", orderBy: "id DESC");
//   }

//   static Future updateCamp(int id, Map<String, dynamic> data) async {
//     final db = await database;
//     data["synced"] = 0;
//     return db.update("camps", data, where: "id=?", whereArgs: [id]);
//   }

//   static Future deleteCamp(int id) async {
//     final db = await database;
//     await db.delete("patients", where: "camp_id=?", whereArgs: [id]);
//     return db.delete("camps", where: "id=?", whereArgs: [id]);
//   }

//   static Future<int> getCampCount() async {
//     final db = await database;
//     var result = await db.rawQuery("SELECT COUNT(*) FROM camps");
//     return Sqflite.firstIntValue(result) ?? 0;
//   }

//   // ================= PATIENTS =================

//   static Future insertPatient(Map<String, dynamic> data) async {
//     final db = await database;
//     data["synced"] = 0;
//     return db.insert("patients", data);
//   }

//   static Future<List<Map<String, dynamic>>> getPatients(int campId) async {
//     final db = await database;
//     return db.query(
//       "patients",
//       where: "camp_id=?",
//       whereArgs: [campId],
//       orderBy: "id DESC",
//     );
//   }

//   // 🔥 FIXED METHOD (YOUR ERROR)
//   static Future updatePatient(int id, Map<String, dynamic> data) async {
//     final db = await database;
//     data["synced"] = 0;
//     return db.update(
//       "patients",
//       data,
//       where: "id=?",
//       whereArgs: [id],
//     );
//   }

//   static Future deletePatient(int id) async {
//     final db = await database;
//     return db.delete("patients", where: "id=?", whereArgs: [id]);
//   }

//   // ================= SYNC =================

//   static Future<int> getTotalPendingSync() async {
//     final db = await database;
//     var result = await db.rawQuery(
//       "SELECT COUNT(*) FROM patients WHERE synced = 0",
//     );
//     return Sqflite.firstIntValue(result) ?? 0;
//   }

//   static Future<int> pendingSyncCount(int campId) async {
//     final db = await database;
//     var result = await db.rawQuery(
//       "SELECT COUNT(*) FROM patients WHERE synced = 0 AND camp_id = ?",
//       [campId],
//     );
//     return Sqflite.firstIntValue(result) ?? 0;
//   }

//   // ================= PROFILE =================

//   static Future saveProfile(Map<String, dynamic> data) async {
//     final db = await database;

//     var existing = await db.query("doctor_profile");

//     data["synced"] = 0;

//     if (existing.isEmpty) {
//       return db.insert("doctor_profile", data);
//     } else {
//       return db.update(
//         "doctor_profile",
//         data,
//         where: "id=?",
//         whereArgs: [existing.first["id"]],
//       );
//     }
//   }

//   static Future<Map<String, dynamic>?> getProfile() async {
//     final db = await database;
//     var result = await db.query("doctor_profile");
//     return result.isNotEmpty ? result.first : null;
//   }

//   // ================= DASHBOARD =================

//   static Future<int> getTotalPatients() async {
//     final db = await database;
//     var result = await db.rawQuery("SELECT COUNT(*) FROM patients");
//     return Sqflite.firstIntValue(result) ?? 0;
//   }

//   static Future<int> getTodayPatients() async {
//     final db = await database;

//     final today = DateTime.now();

//     String start =
//         DateTime(today.year, today.month, today.day).toString();

//     String end =
//         DateTime(today.year, today.month, today.day, 23, 59, 59).toString();

//     var result = await db.rawQuery(
//       "SELECT COUNT(*) FROM patients WHERE visit_date BETWEEN ? AND ?",
//       [start, end],
//     );

//     return Sqflite.firstIntValue(result) ?? 0;
//   }

//   static Future<List<int>> getWeeklyPatientData() async {
//     final db = await database;

//     List<int> data = [];

//     for (int i = 6; i >= 0; i--) {
//       final date = DateTime.now().subtract(Duration(days: i));

//       String start =
//           DateTime(date.year, date.month, date.day).toString();

//       String end =
//           DateTime(date.year, date.month, date.day, 23, 59, 59).toString();

//       var result = await db.rawQuery(
//         "SELECT COUNT(*) FROM patients WHERE visit_date BETWEEN ? AND ?",
//         [start, end],
//       );

//       data.add(Sqflite.firstIntValue(result) ?? 0);
//     }

//     return data;
//   }
// // }


// import 'package:sqflite/sqflite.dart';
// import 'package:path/path.dart';

// class DBHelper {
//   static Database? _db;

//   static Future<Database> get database async {
//     if (_db != null) return _db!;
//     _db = await initDB();
//     return _db!;
//   }

//   static Future<Database> initDB() async {
//     String path = join(await getDatabasesPath(), 'healthcare_camps.db');

//     return await openDatabase(
//       path,
//       version: 1,
//       onCreate: (db, version) async {

//         await db.execute('''
//         CREATE TABLE camps(
//           id INTEGER PRIMARY KEY AUTOINCREMENT,
//           doctor_id INTEGER,
//           name TEXT,
//           location TEXT,
//           doctor TEXT,
//           notes TEXT,
//           date TEXT,
//           synced INTEGER DEFAULT 0
//         )
//         ''');

//         await db.execute('''
//         CREATE TABLE patients(
//           id INTEGER PRIMARY KEY AUTOINCREMENT,
//           doctor_id INTEGER,
//           camp_id INTEGER,
//           name TEXT,
//           age INTEGER,
//           gender TEXT,
//           location TEXT,
//           symptoms TEXT,
//           bp TEXT,
//           temp TEXT,
//           spo2 TEXT,
//           hr TEXT,
//           diagnosis TEXT,
//           medicines TEXT,
//           advice TEXT,
//           visit_date TEXT,
//           synced INTEGER DEFAULT 0
//         )
//         ''');

//         await db.execute('''
//         CREATE TABLE doctor_profile(
//           id INTEGER PRIMARY KEY AUTOINCREMENT,
//           doctor_id INTEGER,
//           doctor_name TEXT,
//           qualification TEXT,
//           specialization TEXT,
//           experience TEXT,
//           phone TEXT,
//           address TEXT,
//           synced INTEGER DEFAULT 0
//         )
//         ''');
//       },
//     );
//   }

//   // ================= CAMPS =================

//   static Future insertCamp(Map<String, dynamic> data) async {
//     final db = await database;
//     data["synced"] = 0; // 🔥 ensure unsynced
//     return db.insert("camps", data);
//   }

//   static Future<List<Map<String, dynamic>>> getCamps() async {
//     final db = await database;
//     return db.query("camps", orderBy: "id DESC");
//   }

//   static Future updateCamp(int id, Map<String, dynamic> data) async {
//     final db = await database;
//     data["synced"] = 0; // 🔥 ensure resync
//     return db.update("camps", data, where: "id=?", whereArgs: [id]);
//   }

//   static Future deleteCamp(int id) async {
//     final db = await database;
//     await db.delete("patients", where: "camp_id=?", whereArgs: [id]);
//     return db.delete("camps", where: "id=?", whereArgs: [id]);
//   }

//   // ================= PATIENT =================

//   static Future insertPatient(Map<String, dynamic> data) async {
//     final db = await database;
//     data["synced"] = 0;
//     return db.insert("patients", data);
//   }

//   static Future<List<Map<String, dynamic>>> getPatients(int campId) async {
//     final db = await database;
//     return db.query("patients", where: "camp_id=?", whereArgs: [campId]);
//   }

//   // ================= PROFILE =================

//   static Future saveProfile(Map<String, dynamic> data) async {
//     final db = await database;

//     var existing = await db.query("doctor_profile");

//     data["synced"] = 0; // 🔥 IMPORTANT

//     if (existing.isEmpty) {
//       return db.insert("doctor_profile", data);
//     } else {
//       return db.update(
//         "doctor_profile",
//         data,
//         where: "id=?",
//         whereArgs: [existing.first["id"]],
//       );
//     }
//   }

//   static Future<Map<String, dynamic>?> getProfile() async {
//     final db = await database;
//     var result = await db.query("doctor_profile");
//     return result.isNotEmpty ? result.first : null;
//   }
// }
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

        // ================= CAMPS =================
        await db.execute('''
        CREATE TABLE camps(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          doctor_id INTEGER,
          name TEXT,
          location TEXT,
          doctor TEXT,
          notes TEXT,
          date TEXT,
          synced INTEGER DEFAULT 0
        )
        ''');

        // ================= PATIENTS =================
        await db.execute('''
        CREATE TABLE patients(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          doctor_id INTEGER,
          camp_id INTEGER,
          name TEXT,
          age INTEGER,
          gender TEXT,
          location TEXT,
          symptoms TEXT,
          bp TEXT,
          temp TEXT,
          spo2 TEXT,
          hr TEXT,
          diagnosis TEXT,
          medicines TEXT,
          advice TEXT,
          visit_date TEXT,
          synced INTEGER DEFAULT 0
        )
        ''');

        // ================= PROFILE =================
        await db.execute('''
        CREATE TABLE doctor_profile(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          doctor_id INTEGER,
          doctor_name TEXT,
          qualification TEXT,
          specialization TEXT,
          experience TEXT,
          phone TEXT,
          address TEXT,
          synced INTEGER DEFAULT 0
        )
        ''');
      },
    );
  }

  // ================= CAMPS =================

  static Future<int> insertCamp(Map<String, dynamic> data) async {
    final db = await database;
    data["synced"] = 0;
    return db.insert("camps", data);
  }

  static Future<List<Map<String, dynamic>>> getCamps() async {
    final db = await database;
    return db.query("camps", orderBy: "id DESC");
  }

  static Future<int> updateCamp(int id, Map<String, dynamic> data) async {
    final db = await database;
    data["synced"] = 0;
    return db.update("camps", data, where: "id=?", whereArgs: [id]);
  }

  static Future<int> deleteCamp(int id) async {
    final db = await database;
    await db.delete("patients", where: "camp_id=?", whereArgs: [id]);
    return db.delete("camps", where: "id=?", whereArgs: [id]);
  }

  static Future<int> getCampCount() async {
    final db = await database;
    var res = await db.rawQuery("SELECT COUNT(*) FROM camps");
    return Sqflite.firstIntValue(res) ?? 0;
  }

  // ================= PATIENTS =================

  static Future<int> insertPatient(Map<String, dynamic> data) async {
    final db = await database;
    data["synced"] = 0;
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

  static Future<int> updatePatient(int id, Map<String, dynamic> data) async {
    final db = await database;
    data["synced"] = 0;
    return db.update("patients", data, where: "id=?", whereArgs: [id]);
  }

  static Future<int> deletePatient(int id) async {
    final db = await database;
    return db.delete("patients", where: "id=?", whereArgs: [id]);
  }

  // ================= SYNC =================

  static Future<int> getTotalPendingSync() async {
    final db = await database;

    var result = await db.rawQuery('''
      SELECT 
      (SELECT COUNT(*) FROM patients WHERE synced = 0) +
      (SELECT COUNT(*) FROM camps WHERE synced = 0) +
      (SELECT COUNT(*) FROM doctor_profile WHERE synced = 0)
    ''');

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

    data["synced"] = 0;

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
    return result.isNotEmpty ? result.first : null;
  }

  // ================= DASHBOARD =================

  static Future<int> getTotalPatients() async {
    final db = await database;
    var res = await db.rawQuery("SELECT COUNT(*) FROM patients");
    return Sqflite.firstIntValue(res) ?? 0;
  }

  static Future<int> getTodayPatients() async {
    final db = await database;

    final today = DateTime.now();

    String start =
        DateTime(today.year, today.month, today.day).toString();

    String end =
        DateTime(today.year, today.month, today.day, 23, 59, 59)
            .toString();

    var res = await db.rawQuery(
      "SELECT COUNT(*) FROM patients WHERE visit_date BETWEEN ? AND ?",
      [start, end],
    );

    return Sqflite.firstIntValue(res) ?? 0;
  }

  static Future<List<int>> getWeeklyPatientData() async {
    final db = await database;

    List<int> data = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));

      String start =
          DateTime(date.year, date.month, date.day).toString();

      String end =
          DateTime(date.year, date.month, date.day, 23, 59, 59)
              .toString();

      var res = await db.rawQuery(
        "SELECT COUNT(*) FROM patients WHERE visit_date BETWEEN ? AND ?",
        [start, end],
      );

      data.add(Sqflite.firstIntValue(res) ?? 0);
    }

    return data;
  }
}