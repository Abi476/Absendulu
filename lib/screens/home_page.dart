import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import '../services/auth_service.dart';

class HomePage extends StatelessWidget {

  const HomePage({super.key});

  Future logout(BuildContext context) async {

    final pref =
        await SharedPreferences.getInstance();

    await pref.clear();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const LoginPage(),
      ),
      (route) => false,
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Home"),
        actions: [

          IconButton(
            onPressed: () =>
                logout(context),
            icon: const Icon(Icons.logout),
          ),

        ],

      ),

      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                bool success = await AuthService.checkIn();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? "Presensi berhasil"
                          : "Gagal presensi",
                    ),
                  ),
                );
              },
              child: const Text("Presensi"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const HistoryPage(),
                  ),
                );
              },
              child: const Text("History Presensi"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const ProfilePage(),
                  ),
                );
              },
              child: const Text("Edit Profil"),
            ),
          ]
        ),
      )
    );
  }
}