import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDatabase();
    return _database!;
  }

  static Future<Database> initDatabase() async {
    String dbPath = await getDatabasesPath();

    return await openDatabase(
      join(dbPath, 'epresensi.db'),
      version: 1, // Versi tetap 1 jika kita uninstall aplikasi lamanya
      onCreate: (db, version) async {
        // --- PENAMBAHAN KOLOM image_path PADA TABEL USERS ---
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            image_path TEXT 
          )
        ''');
        // ----------------------------------------------------
        
        await db.execute('''
          CREATE TABLE attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            check_in_time TEXT,
            latitude REAL,
            longitude REAL,
            address TEXT
          )
        ''');
      },
    );
  }
}