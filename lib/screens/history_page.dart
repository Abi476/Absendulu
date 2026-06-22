import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/auth_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future data;

  @override
  void initState() {
    super.initState();
    data = AuthService.getAttendance();
  }

  // --- FUNGSI PEMBANTU UNTUK FORMAT TANGGAL ---
  String _formatDate(String dateTimeStr) {
    try {
      DateTime dt = DateTime.parse(dateTimeStr);
      return "${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}";
    } catch (e) {
      return "-";
    }
  }

  // --- FUNGSI PEMBANTU UNTUK FORMAT JAM ---
  String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty || dateTimeStr == 'null') {
      return "--:--";
    }
    try {
      DateTime dt = DateTime.parse(dateTimeStr);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return "--:--";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder(
        future: data,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            );
          }

          final items = snapshot.data as List<Map<String, dynamic>>;

          if (items.isEmpty) {
            return const Center(
              child: Text(
                "Belum ada data presensi.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final lat = item['latitude'];
              final lng = item['longitude'];

              final checkInStr = item['check_in_time']?.toString();
              final checkOutStr = item.containsKey('check_out_time')
                  ? item['check_out_time']?.toString()
                  : null;

              // Menarik nama matkul dari database (Berikan nilai default jika null)
              final String namaMatkul = item['nama_matkul'] ?? 'Presensi Umum';

              return Card(
                margin: const EdgeInsets.only(bottom: 20),
                elevation: 3,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // --- HEADER KARTU: JUDUL & TANGGAL ---
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.08),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Sisi Kiri: Judul Matkul
                          Expanded(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.class_,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    namaMatkul,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    overflow: TextOverflow
                                        .ellipsis, // Mencegah teks kepanjangan tumpah
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Sisi Kanan: Tanggal
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: Colors.grey[600],
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(checkInStr ?? ''),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // --- BODY KARTU: INFO MASUK & PULANG ---
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.login_rounded,
                                    color: Colors.green,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Masuk",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(checkInStr),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          Container(
                            height: 40,
                            width: 1,
                            color: Colors.grey.withOpacity(0.3),
                          ),

                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text(
                                      "Pulang",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _formatTime(checkOutStr),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.orange,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // --- FOOTER KARTU: MINI MAP ---
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20),
                      ),
                      child: SizedBox(
                        height: 150,
                        child: FlutterMap(
                          options: MapOptions(
                            initialCenter: LatLng(lat, lng),
                            initialZoom: 16,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  "https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                              userAgentPackageName:
                                  "com.example.sistem_absensi",
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(lat, lng),
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.redAccent,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
