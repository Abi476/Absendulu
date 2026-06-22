import 'dart:io'; 

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_page.dart';
import 'history_page.dart';
import 'profile_page.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _pageIndex = 0;
  final PageController _pageController = PageController();
  
  final GlobalKey<ProfilePageState> _profileKey = GlobalKey<ProfilePageState>();
  
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadUserData(); 
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _imagePath = user['image_path'];
      });
    }
  }

  // Fungsi ini dipanggil saat user menekan Logout atau Yes pada tombol Back
  Future logout(BuildContext context) async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear(); // Hapus sesi (Logout)

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    switch (_pageIndex) {
      case 0:
        return "Catat Presensi";
      case 1:
        return "History Presensi";
      case 2:
        return "Profil Pengguna";
      default:
        return "Sistem Absensi";
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, 
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        // MENGUBAH DIALOG MENJADI LOGOUT 
        final bool shouldLogout = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Konfirmasi Logout'),
            content: const Text('Apakah Anda yakin ingin keluar (logout) dari akun ini? Anda harus login kembali nantinya.'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Ya, Logout'),
              ),
            ],
          ),
        ) ?? false;

        // Jika user memilih 'Ya, Logout', panggil fungsi logout
        if (shouldLogout) {
          if (!context.mounted) return;
          logout(context);
        }
        // 
      },
      child: Scaffold(
        extendBody: true, 
        backgroundColor: Colors.grey[50],
        
        appBar: AppBar(
          backgroundColor: Colors.white, 
          foregroundColor: Colors.black87, 
          elevation: 0,
          centerTitle: true,
          title: Text(
            _getAppBarTitle(), 
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_pageIndex != 2)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  iconSize: 32, 
                  onPressed: () {
                    setState(() {
                      _pageIndex = 2;
                    });
                    _pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  icon: _imagePath != null && _imagePath!.isNotEmpty
                      ? CircleAvatar(
                          radius: 16,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          backgroundImage: FileImage(File(_imagePath!)),
                        )
                      : const Icon(Icons.account_circle, size: 28),
                ),
              ),
          ],
        ),
        
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), 
          children: [
            _buildPresensiView(), 
            const HistoryPage(),  
            ProfilePage(key: _profileKey),  
          ],
        ),

        bottomNavigationBar: CurvedNavigationBar(
          index: _pageIndex,
          height: 60.0,
          color: Theme.of(context).primaryColor, 
          buttonBackgroundColor: Theme.of(context).primaryColor, 
          backgroundColor: Colors.transparent, 
          animationCurve: Curves.easeInOut,
          animationDuration: const Duration(milliseconds: 400),
          items: const [
            Icon(Icons.fingerprint, size: 30, color: Colors.white), 
            Icon(Icons.history, size: 30, color: Colors.white),     
            Icon(Icons.person, size: 30, color: Colors.white),      
          ],
          onTap: (index) async {
            if (_pageIndex == 2 && index != 2) {
              final profileState = _profileKey.currentState;
              
              if (profileState != null && profileState.hasUnsavedChanges()) {
                
                bool? isLeaving = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Perubahan Belum Disimpan'),
                    content: const Text(
                      'Anda memiliki perubahan profil yang belum disimpan. Yakin ingin meninggalkan halaman ini? Perubahan akan dibatalkan.',
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false), 
                        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true), 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tinggalkan'),
                      ),
                    ],
                  ),
                );

                if (isLeaving == true) {
                  profileState.discardChanges();
                } else {
                  setState(() {});
                  return; 
                }
              }
            }

            if (index != 2 && _pageIndex == 2) {
              _loadUserData(); 
            }
            
            setState(() {
              _pageIndex = index;
            });
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
        ),
      ),
    );
  }

  Widget _buildPresensiView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 100,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(height: 20),
          const Text(
            "Catat Kehadiran Anda",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          
          SizedBox(
            height: 50,
            width: 200,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () async {
                bool success = await AuthService.checkIn();
                
                if (!mounted) return;
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? "Presensi berhasil!" : "Gagal presensi",
                    ),
                    backgroundColor: success ? Colors.green : Colors.redAccent,
                  ),
                );
              },
              child: const Text(
                "Presensi",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}