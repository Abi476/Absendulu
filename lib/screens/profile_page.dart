import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class ProfilePage extends StatefulWidget {

  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() =>
      _ProfilePageState();

}

class _ProfilePageState
extends State<ProfilePage> {

  final nameController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  bool loading = true;

  @override
  void initState() {

    super.initState();

    loadUser();

  }

  Future loadUser() async {

    final user =
        await AuthService.getUser();

    if (user != null) {

      nameController.text =
          user['name'];

      passwordController.text =
          user['password'];

    }

    setState(() {
      loading = false;
    });

  }

  Future save() async {

    setState(() {
      loading = true;
    });

    bool success =
        await AuthService.updateUser(
      nameController.text,
      passwordController.text,
    );

    setState(() {
      loading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Profil berhasil diupdate"
              : "Gagal update profil",
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title:
        const Text("Edit Profil"),
      ),

      body: loading
          ? const Center(
              child:
              CircularProgressIndicator(),
            )
          : Padding(

              padding:
              const EdgeInsets.all(20),

              child: Column(

                children: [

                  TextField(
                    controller:
                    nameController,
                    decoration:
                    const InputDecoration(
                      labelText: "Nama",
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller:
                    passwordController,
                    obscureText: true,
                    decoration:
                    const InputDecoration(
                      labelText: "Password",
                    ),
                  ),

                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: save,
                    child:
                    const Text("Simpan"),
                  ),

                ],

              ),

            ),

    );

  }

}