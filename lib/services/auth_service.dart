import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';
import 'location_service.dart';

class AuthService {

  static Future<bool> updateUser(
    String name,
    String password,
  ) async {

    final db =
        await DatabaseService.database;

    final pref =
        await SharedPreferences.getInstance();

    int? userId =
        pref.getInt('user_id');

    if (userId == null) return false;

    try {

      await db.update(
        'users',
        {
          'name': name,
          'password': password,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );

      return true;

    } catch (e) {

      return false;

    }

  }

  static Future<Map<String, dynamic>?> getUser() async {

    final db =
        await DatabaseService.database;

    final pref =
        await SharedPreferences.getInstance();

    int? userId =
        pref.getInt('user_id');

    if (userId == null) return null;

    final result = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isNotEmpty) {
      return result.first;
    }

    return null;

}

  static Future<List<Map<String, dynamic>>> getAttendance() async {

    final db =
        await DatabaseService.database;

    final pref =
        await SharedPreferences.getInstance();

    int? userId =
        pref.getInt('user_id');

    if (userId == null) return [];

    final result = await db.query(
      'attendance',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );

    return result;

  }

  static Future<bool> checkIn() async {

    final db =
        await DatabaseService.database;

    final pref =
        await SharedPreferences.getInstance();

    int? userId =
        pref.getInt('user_id');

    if (userId == null) return false;

    try {

      final position =
          await LocationService.getLocation();

      await db.insert(
        'attendance',
        {
          'user_id': userId,
          'check_in_time':
              DateTime.now().toString(),
          'latitude': position.latitude,
          'longitude': position.longitude,
          'address': 'Unknown'
        },
      );

      return true;

    } catch (e) {

      return false;

    }

  }

  static Future<bool> register(
    String name,
    String email,
    String password,
  ) async {

    final db = await DatabaseService.database;

    try {

      await db.insert(
        'users',
        {
          'name': name,
          'email': email,
          'password': password,
        },
      );

      return true;

    } catch (e) {

      return false;

    }
  }

  static Future<bool> login(
    String email,
    String password,
  ) async {

    final db = await DatabaseService.database;

    final result = await db.query(
      'users',
      where: 'email=? AND password=?',
      whereArgs: [
        email,
        password,
      ],
    );

    if (result.isNotEmpty) {

      final pref =
          await SharedPreferences.getInstance();

      await pref.setInt(
        'user_id',
        result.first['id'] as int,
      );

      return true;
    }

    return false;
  }

}