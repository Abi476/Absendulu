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
      version: 1,
      // --- FUNGSI MENGAKTIFKAN CASCADE DELETE ---
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      
      onCreate: (db, version) async {
        // TABEL USERS
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            email TEXT UNIQUE,
            password TEXT,
            image_path TEXT 
          )
        ''');
        
        // TABEL SCHEDULES 
        await db.execute('''
          CREATE TABLE schedules(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            nama_matkul TEXT,
            jam_masuk TEXT,
            jam_pulang TEXT,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        // TABEL ATTENDANCE
        await db.execute('''
          CREATE TABLE attendance(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER,
            schedule_id INTEGER, 
            check_in_time TEXT,
            check_out_time TEXT, 
            latitude REAL,
            longitude REAL,
            address TEXT,
            FOREIGN KEY (schedule_id) REFERENCES schedules (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}