import 'package:geolocator/geolocator.dart';

class LocationService {

  static Future<Position> getLocation() async {

    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("GPS tidak aktif");
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {

      permission =
          await Geolocator.requestPermission();

      if (permission ==
          LocationPermission.denied) {
        throw Exception("Izin lokasi ditolak");
      }

    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception("Izin lokasi permanen ditolak");
    }

    return await Geolocator
        .getCurrentPosition(
      desiredAccuracy:
      LocationAccuracy.high,
    );

  }

}