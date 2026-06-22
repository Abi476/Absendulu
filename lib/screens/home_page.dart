import 'dart:io';
import 'dart:async'; 

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
  String _userName = ''; 
  Timer? _timer; 
  
  // Menggabungkan data jadwal dan riwayat presensi hari ini agar UI sinkron
  late Future<Map<String, dynamic>> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _refreshHomeData();
    
    // Timer ini akan me-refresh tampilan setiap 1 detik.
    // Jika waktu di HP berubah dan masuk jadwal absen, tombol otomatis menyala.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {}); 
      }
    });
  }

  void _refreshHomeData() {
    setState(() {
      _homeDataFuture = Future.wait([
        AuthService.getSchedules(),
        AuthService.getAttendance(),
      ]).then((results) {
        return {
          'schedules': results[0] as List<Map<String, dynamic>>,
          'attendance': results[1] as List<Map<String, dynamic>>,
        };
      });
    });
  }

  Future<void> _loadUserData() async {
    final user = await AuthService.getUser();
    if (user != null && mounted) {
      setState(() {
        _imagePath = user['image_path'];
        _userName = user['name'] ?? 'Pengguna';
      });
    }
  }

  Future logout(BuildContext context) async {
    final pref = await SharedPreferences.getInstance();
    await pref.clear();

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
    _timer?.cancel(); // Sangat penting: Matikan timer saat pindah halaman agar aplikasi tidak berat
    _pageController.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    switch (_pageIndex) {
      case 0:
        return "Jadwal Presensi"; 
      case 1:
        return "History Presensi";
      case 2:
        return "Profil Pengguna";
      default:
        return "Sistem Absensi";
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // --- DIALOG TAMBAH JADWAL MATKUL ---
  void _showAddScheduleDialog() {
    final matkulController = TextEditingController();
    TimeOfDay? jamMasuk;
    TimeOfDay? jamPulang;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Tambah Jadwal Matkul'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: matkulController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Mata Kuliah',
                      prefixIcon: Icon(Icons.book),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Jam Masuk"),
                    subtitle: Text(jamMasuk == null ? "Belum diatur" : _formatTime(jamMasuk!)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => jamMasuk = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Jam Pulang"),
                    subtitle: Text(jamPulang == null ? "Belum diatur" : _formatTime(jamPulang!)),
                    trailing: const Icon(Icons.access_time_filled),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => jamPulang = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (matkulController.text.isEmpty || jamMasuk == null || jamPulang == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Harap lengkapi semua data!'), backgroundColor: Colors.orange),
                    );
                    return;
                  }

                  bool success = await AuthService.addSchedule(
                    matkulController.text,
                    _formatTime(jamMasuk!),
                    _formatTime(jamPulang!),
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  if (success) {
                    _refreshHomeData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Jadwal berhasil ditambahkan'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DIALOG EDIT JADWAL MATKUL ---
  void _showEditScheduleDialog(Map<String, dynamic> schedule) {
    final matkulController = TextEditingController(text: schedule['nama_matkul']);
    
    final partsMasuk = schedule['jam_masuk'].split(':');
    final partsPulang = schedule['jam_pulang'].split(':');
    
    TimeOfDay jamMasuk = TimeOfDay(hour: int.parse(partsMasuk[0]), minute: int.parse(partsMasuk[1]));
    TimeOfDay jamPulang = TimeOfDay(hour: int.parse(partsPulang[0]), minute: int.parse(partsPulang[1]));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Jadwal Matkul'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: matkulController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Mata Kuliah',
                      prefixIcon: Icon(Icons.book),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Jam Masuk"),
                    subtitle: Text(_formatTime(jamMasuk)),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: jamMasuk);
                      if (picked != null) {
                        setDialogState(() => jamMasuk = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("Jam Pulang"),
                    subtitle: Text(_formatTime(jamPulang)),
                    trailing: const Icon(Icons.access_time_filled),
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: jamPulang);
                      if (picked != null) {
                        setDialogState(() => jamPulang = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (matkulController.text.isEmpty) return;

                  bool success = await AuthService.updateSchedule(
                    schedule['id'],
                    matkulController.text,
                    _formatTime(jamMasuk),
                    _formatTime(jamPulang),
                  );

                  if (!context.mounted) return;
                  Navigator.pop(context);

                  if (success) {
                    _refreshHomeData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Jadwal diperbarui'), backgroundColor: Colors.green),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                child: const Text('Simpan', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleCheckIn(int scheduleId, String jamMasukTarget) async {
    String result = await AuthService.checkIn(scheduleId, jamMasukTarget);
    if (!mounted) return;

    if (result == "sukses") {
      _refreshHomeData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Absen Masuk Berhasil!"), backgroundColor: Colors.green),
      );
    } else if (result == "belum_waktunya") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Belum bisa absen! Batas masuk: $jamMasukTarget s.d 30 menit ke depan"), backgroundColor: Colors.orange),
      );
    } else if (result == "sudah_absen") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda sudah absen masuk hari ini."), backgroundColor: Colors.blue),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan sistem."), backgroundColor: Colors.redAccent),
      );
    }
  }

  Future<void> _handleCheckOut(int scheduleId, String jamPulangTarget, List<Map<String, dynamic>> attendanceRecords) async {
    final today = DateTime.now().toString().substring(0, 10);
    final todayRecord = attendanceRecords.firstWhere(
      (r) => r['schedule_id'] == scheduleId && r['check_in_time'].toString().startsWith(today),
      orElse: () => {},
    );

    if (!mounted) return;

    if (todayRecord.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda belum melakukan absen masuk hari ini!"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    if (todayRecord['check_out_time'] != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Anda sudah absen pulang."), backgroundColor: Colors.blue),
      );
      return;
    }

    String result = await AuthService.checkOut(todayRecord['id'], jamPulangTarget);
    if (!mounted) return;

    if (result == "sukses") {
      _refreshHomeData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Absen Pulang Berhasil!"), backgroundColor: Colors.green),
      );
    } else if (result == "belum_waktunya") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Belum bisa pulang! Batas pulang: $jamPulangTarget s.d 60 menit ke depan"), backgroundColor: Colors.orange),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        final bool shouldLogout = await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Konfirmasi Logout'),
                content: const Text('Apakah Anda yakin ingin keluar (logout) dari akun ini? Anda harus login kembali nantinya.'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
            ) ??
            false;

        if (shouldLogout) {
          if (!context.mounted) return;
          logout(context);
        }
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

        floatingActionButton: _pageIndex == 0
            ? FloatingActionButton.extended(
                onPressed: _showAddScheduleDialog,
                backgroundColor: Theme.of(context).primaryColor,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text("Jadwal", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              )
            : null,

        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildScheduleView(), 
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
            Icon(Icons.event_available, size: 30, color: Colors.white), 
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
                    content: const Text('Anda memiliki perubahan profil yang belum disimpan. Yakin ingin meninggalkan halaman ini? Perubahan akan dibatalkan.'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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
            if (index == 0) {
              _refreshHomeData();
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

  Widget _buildScheduleView() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _homeDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
        }

        final schedules = snapshot.data?['schedules'] as List<Map<String, dynamic>>? ?? [];
        final attendanceRecords = snapshot.data?['attendance'] as List<Map<String, dynamic>>? ?? [];

        return ListView.builder(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 100), 
          itemCount: schedules.length + 1, 
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: 20, top: 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.waving_hand, color: Theme.of(context).primaryColor, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Selamat datang,", style: TextStyle(fontSize: 14, color: Colors.black54)),
                          Text(
                            _userName.isNotEmpty ? _userName : "Memuat nama...",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }

            final schedule = schedules[index - 1];
            final scheduleId = schedule['id'];
            final jamMasuk = schedule['jam_masuk'];
            final jamPulang = schedule['jam_pulang'];

            final now = DateTime.now();
            final todayStr = now.toString().substring(0, 10);

            final partsM = jamMasuk.split(':');
            final dtMasukStart = DateTime(now.year, now.month, now.day, int.parse(partsM[0]), int.parse(partsM[1]));
            final dtMasukEnd = dtMasukStart.add(const Duration(minutes: 30));

            final partsP = jamPulang.split(':');
            final dtPulangStart = DateTime(now.year, now.month, now.day, int.parse(partsP[0]), int.parse(partsP[1]));
            final dtPulangEnd = dtPulangStart.add(const Duration(minutes: 60));

            final todayRecord = attendanceRecords.firstWhere(
              (r) => r['schedule_id'] == scheduleId && r['check_in_time'].toString().startsWith(todayStr),
              orElse: () => {},
            );

            final bool hasCheckedIn = todayRecord.isNotEmpty;
            final bool hasCheckedOut = todayRecord.isNotEmpty && todayRecord['check_out_time'] != null;

            // --- PERBAIKAN LOGIKA BATAS WAKTU (Lebih dari/Sama dengan) ---
            final bool isCheckInWindow = now.compareTo(dtMasukStart) >= 0 && now.compareTo(dtMasukEnd) <= 0;
            final bool isCheckOutWindow = now.compareTo(dtPulangStart) >= 0 && now.compareTo(dtPulangEnd) <= 0;
            
            final bool isCheckInMissed = now.compareTo(dtMasukEnd) > 0 && !hasCheckedIn;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isCheckInMissed 
                    ? const BorderSide(color: Colors.redAccent, width: 1.5) 
                    : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            schedule['nama_matkul'],
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                              onPressed: () => _showEditScheduleDialog(schedule),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () async {
                                bool? confirm = await showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Hapus Jadwal?"),
                                    content: const Text("Menghapus jadwal ini juga akan menghapus semua riwayat presensi yang terkait. Lanjutkan?"),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Batal")),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        child: const Text("Hapus", style: TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await AuthService.deleteSchedule(scheduleId);
                                  _refreshHomeData();
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        const Icon(Icons.login, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("Masuk: $jamMasuk", style: const TextStyle(color: Colors.black87)),
                        const SizedBox(width: 16),
                        const Icon(Icons.logout, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text("Pulang: $jamPulang", style: const TextStyle(color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (isCheckInMissed)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text(
                              "Jam presensi terlewat",
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (isCheckInWindow && !hasCheckedIn && !isCheckInMissed)
                                ? () => _handleCheckIn(scheduleId, jamMasuk)
                                : null,
                            icon: const Icon(Icons.fingerprint, color: Colors.white, size: 20),
                            label: Text(hasCheckedIn ? "Sudah Masuk" : "Masuk"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              disabledBackgroundColor: Colors.grey[200],
                              disabledForegroundColor: Colors.grey[400],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (hasCheckedIn && isCheckOutWindow && !hasCheckedOut && !isCheckInMissed)
                                ? () => _handleCheckOut(scheduleId, jamPulang, attendanceRecords)
                                : null,
                            icon: const Icon(Icons.directions_run, color: Colors.white, size: 20),
                            label: Text(hasCheckedOut ? "Sudah Pulang" : "Pulang"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              disabledBackgroundColor: Colors.grey[200],
                              disabledForegroundColor: Colors.grey[400],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ), 
            );
          },
        );
      },
    );
  }
}