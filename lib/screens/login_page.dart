import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'register_page.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() =>
      _LoginPageState();

}

class _LoginPageState
extends State<LoginPage> {

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;

  Future login() async {

    setState(() {
      loading = true;
    });

    bool success =
        await AuthService.login(
      emailController.text,
      passwordController.text,
    );

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    if (success) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const HomePage(),
        ),
      );

    } else {

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
          Text("Login gagal"),
        ),
      );

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Login"),
      ),

      body: Padding(

        padding:
        const EdgeInsets.all(20),

        child: Column(

          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: "Email",
              ),
            ),

            const SizedBox(height: 10),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Password",
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(

              onPressed:
              loading ? null : login,

              child: Text(
                loading
                    ? "Loading..."
                    : "Login",
              ),

            ),

            TextButton(

              onPressed: () {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const RegisterPage(),
                  ),
                );

              },

              child:
              const Text("Register"),

            ),

          ],

        ),

      ),

    );

  }

}