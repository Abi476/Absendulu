import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/auth_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() =>
      _HistoryPageState();
}

class _HistoryPageState
    extends State<HistoryPage> {

  late Future data;

  @override
  void initState() {
    super.initState();
    data = AuthService.getAttendance();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("History Presensi"),
      ),

      body: FutureBuilder(
        future: data,
        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final items = snapshot.data!;

          return ListView.builder(

            itemCount: items.length,

            itemBuilder: (context, index) {

              final item = items[index];

              final lat = item['latitude'];
              final lng = item['longitude'];

              return Card(

                margin: const EdgeInsets.all(10),

                child: Column(

                  children: [

                    ListTile(
                      title: Text(item['check_in_time']),
                      subtitle: Text("Lat: $lat, Lng: $lng"),
                    ),

                    // 🗺️ MINI MAP
                    SizedBox(
                      height: 200,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: LatLng(lat, lng),
                          initialZoom: 16,
                        ),
                        children: [

                          TileLayer(
                            urlTemplate: "https://a.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png",
                            userAgentPackageName: "com.example.sistem_absensi",
                          ),

                          MarkerLayer(
                            markers: [
                              Marker(
                                point: LatLng(lat, lng),
                                width: 40,
                                height: 40,
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),

                        ],
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