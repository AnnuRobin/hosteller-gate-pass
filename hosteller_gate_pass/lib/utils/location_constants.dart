import 'package:geolocator/geolocator.dart';

class LocationConstants {
  // Replace these with actual college coordinates
  static const double collegeLatitude = 9.727177;
  static const double collegeLongitude = 76.726452;

  // Maximum allowed radius in meters from the college coordinates
  // to be considered "inside the campus"
  static const double validRadiusInMeters = 500.0;

  static bool isWithinCampus(double latitude, double longitude) {
    final distance = Geolocator.distanceBetween(
      collegeLatitude,
      collegeLongitude,
      latitude,
      longitude,
    );
    return distance <= validRadiusInMeters;
  }
}
