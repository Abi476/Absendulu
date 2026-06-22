import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login_page.dart';
import 'screens/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  Future<bool> checkLogin() async {

    final pref =
        await SharedPreferences.getInstance();

    return pref.getInt('user_id') != null;

  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: FutureBuilder<bool>(

        future: checkLogin(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {

            return const Scaffold(
              body: Center(
                child:
                CircularProgressIndicator(),
              ),
            );

          }

          if (snapshot.data == true) {

            return const HomePage();

          }

          return const LoginPage();

        },

      ),

    );

  }

}