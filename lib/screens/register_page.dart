import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {

  const RegisterPage({
    super.key,
  });

  @override
  State<RegisterPage> createState() =>
      _RegisterPageState();

}

class _RegisterPageState
extends State<RegisterPage> {

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = false;

  Future register() async {

    setState(() {
      loading = true;
    });

    bool success =
        await AuthService.register(

      nameController.text,

      emailController.text,

      passwordController.text,

    );

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    if (success) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content:
          Text("Register berhasil"),

        ),

      );

      Navigator.pop(
        context,
      );

    }

    else {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content:
          Text("Email sudah dipakai"),

        ),

      );

    }

  }

  @override
  Widget build(
    BuildContext context,
  ) {

    return Scaffold(

      appBar: AppBar(

        title:
        const Text(
          "Register",
        ),

      ),

      body:

      Padding(

        padding:
        const EdgeInsets.all(
          20,
        ),

        child:

        Column(

          children: [

            TextField(

              controller:
              nameController,

              decoration:
              const InputDecoration(

                labelText:
                "Nama",

              ),

            ),

            const SizedBox(
              height: 15,
            ),

            TextField(

              controller:
              emailController,

              decoration:
              const InputDecoration(

                labelText:
                "Email",

              ),

            ),

            const SizedBox(
              height: 15,
            ),

            TextField(

              controller:
              passwordController,

              obscureText: true,

              decoration:
              const InputDecoration(

                labelText:
                "Password",

              ),

            ),

            const SizedBox(
              height: 30,
            ),

            ElevatedButton(

              onPressed:
              loading
                  ? null
                  : register,

              child:

              Text(

                loading
                    ? "Loading..."
                    : "Daftar",

              ),

            ),

          ],

        ),

      ),

    );

  }

}