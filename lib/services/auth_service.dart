import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';
import 'location_service.dart';

class AuthService {

  // --- FUNGSI PEMBANTU UNTUK VALIDASI WAKTU ---
  // Mengecek apakah waktu saat ini (sekarang) >= waktu target (misal: "13:00")
  static bool _isTimeValid(String targetTime) {
    try {
      final now = DateTime.now();
      final parts = targetTime.split(':');
      if (parts.length != 2) return false;
      
      final targetHour = int.parse(parts[0]);
      final targetMinute = int.parse(parts[1]);

      final targetDateTime = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
      
      // Mengembalikan true jika waktu sekarang SESUDAH atau SAMA DENGAN waktu target
      return now.isAfter(targetDateTime) || now.isAtSameMomentAs(targetDateTime);
    } catch (e) {
      return false;
    }
  }

  // FITUR JADWAL MATA KULIAH (SCHEDULES)
  static Future<bool> addSchedule(String namaMatkul, String jamMasuk, String jamPulang) async {
    final db = await DatabaseService.database;
    final pref = await SharedPreferences.getInstance();
    int? userId = pref.getInt('user_id');

    if (userId == null) return false;

    try {
      await db.insert('schedules', {
        'user_id': userId,
        'nama_matkul': namaMatkul,
        'jam_masuk': jamMasuk,
        'jam_pulang': jamPulang,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSchedules() async {
    final db = await DatabaseService.database;
    final pref = await SharedPreferences.getInstance();
    int? userId = pref.getInt('user_id');

    if (userId == null) return [];

    return await db.query(
      'schedules',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }

  static Future<bool> deleteSchedule(int scheduleId) async {
    final db = await DatabaseService.database;
    try {
      // Karena kita pakai PRAGMA foreign_keys = ON, history absen matkul ini akan ikut terhapus!
      await db.delete(
        'schedules',
        where: 'id = ?',
        whereArgs: [scheduleId],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // edit 
  static Future<bool> updateSchedule(int id, String namaMatkul, String jamMasuk, String jamPulang) async {
    final db = await DatabaseService.database;
    try {
      await db.update(
        'schedules',
        {
          'nama_matkul': namaMatkul,
          'jam_masuk': jamMasuk,
          'jam_pulang': jamPulang,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // FITUR PRESENSI (ATTENDANCE)
  static Future<List<Map<String, dynamic>>> getAttendance() async {
    final db = await DatabaseService.database;
    final pref = await SharedPreferences.getInstance();
    int? userId = pref.getInt('user_id');

    if (userId == null) return [];

    // gunakan JOIN agar bisa mendapatkan nama_matkul dari tabel schedules
    final result = await db.rawQuery('''
      SELECT a.*, s.nama_matkul 
      FROM attendance a 
      LEFT JOIN schedules s ON a.schedule_id = s.id 
      WHERE a.user_id = ? 
      ORDER BY a.id DESC
    ''', [userId]);

    return result;
  }

  // Diperbarui: Menerima ID Jadwal dan Jam Masuk target
  static Future<String> checkIn(int scheduleId, String jamMasuk) async {
    // Validasi Waktu
    if (!_isTimeValid(jamMasuk)) {
      return "belum_waktunya"; // Mengembalikan status spesifik
    }

    final db = await DatabaseService.database;
    final pref = await SharedPreferences.getInstance();
    int? userId = pref.getInt('user_id');

    if (userId == null) return "error";

    try {
      // Cek apakah hari ini sudah check-in untuk matkul ini
      final today = DateTime.now().toString().substring(0, 10); // Ambil YYYY-MM-DD
      final existing = await db.query(
        'attendance',
        where: 'user_id = ? AND schedule_id = ? AND check_in_time LIKE ?',
        whereArgs: [userId, scheduleId, '$today%'],
      );

      if (existing.isNotEmpty) {
        return "sudah_absen";
      }

      final position = await LocationService.getLocation();

      await db.insert('attendance', {
        'user_id': userId,
        'schedule_id': scheduleId,
        'check_in_time': DateTime.now().toString(),
        'check_out_time': null, // Pulang masih kosong
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': 'Unknown'
      });

      return "sukses";
    } catch (e) {
      return "error";
    }
  }

  // Fungsi Baru: Untuk Absen Pulang
  static Future<String> checkOut(int attendanceId, String jamPulang) async {
    // Validasi Waktu
    if (!_isTimeValid(jamPulang)) {
      return "belum_waktunya";
    }

    final db = await DatabaseService.database;
    try {
      await db.update(
        'attendance',
        {'check_out_time': DateTime.now().toString()},
        where: 'id = ?',
        whereArgs: [attendanceId],
      );
      return "sukses";
    } catch (e) {
      return "error";
    }
  }
  // FITUR USER (TETAP SAMA SEPERTI SEBELUMNYA)
  static Future<bool> updateUser(String name, String password, {String? imagePath}) async {
    final db = await DatabaseService.database;
    final pref = await SharedPreferences.getInstance();
    int? userId = pref.getInt('user_id');
    if (userId == null) return false;

    try {
      Map<String, dynamic> dataToUpdate = {'name': name, 'password': password};
      if (imagePath != null) dataToUpdate['image_path'] = imagePath;

      await db.update('users', dataToUpdate, where: 'id = ?', whereArgs: [userId]);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final db = await DatabaseService.database;
    final pref = await SharedPreferences.getInstance();
    int? userId = pref.getInt('user_id');
    if (userId == null) return null;

    final result = await db.query('users', where: 'id = ?', whereArgs: [userId], limit: 1);
    if (result.isNotEmpty) return result.first;
    return null;
  }

  static Future<bool> register(String name, String email, String password) async {
    final db = await DatabaseService.database;
    try {
      await db.insert('users', {'name': name, 'email': email, 'password': password});
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> login(String email, String password) async {
    final db = await DatabaseService.database;
    final result = await db.query('users', where: 'email=? AND password=?', whereArgs: [email, password]);

    if (result.isNotEmpty) {
      final pref = await SharedPreferences.getInstance();
      await pref.setInt('user_id', result.first['id'] as int);
      return true;
    }
    return false;
  }

  static Future<bool> checkEmailExists(String email) async {
    final db = await DatabaseService.database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return result.isNotEmpty;
  }

  static Future<bool> resetPassword(String email, String newPassword) async {
    final db = await DatabaseService.database;
    try {
      await db.update('users', {'password': newPassword}, where: 'email = ?', whereArgs: [email]);
      return true;
    } catch (e) {
      return false;
    }
  }
}