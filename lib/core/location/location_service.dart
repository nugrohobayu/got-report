import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';

/// Whether the app can read the GPS right now.
enum LocationAccess {
  granted,

  /// Not asked yet (or denied once): can ask again.
  needsPermission,

  /// Denied permanently: only the app settings can fix it.
  deniedForever,

  /// Location (GPS) is turned off on the phone.
  serviceOff,
}

class DeviceLocation extends Equatable {
  final double latitude;
  final double longitude;
  final double accuracyM;

  /// Android mock location provider.
  final bool mock;

  /// Device time of the reading; only used to decide when it is stale.
  final DateTime readAt;

  const DeviceLocation({
    required this.latitude,
    required this.longitude,
    required this.accuracyM,
    required this.mock,
    required this.readAt,
  });

  @override
  List<Object?> get props => [latitude, longitude, accuracyM, mock, readAt];
}

/// Shown when the fix comes from a mock location (fake GPS) app.
const mockLocationMessage =
    'Terdeteksi lokasi palsu (fake GPS). Matikan aplikasi lokasi palsu '
    'dan opsi "Aplikasi lokasi palsu" di Opsi pengembang, lalu coba lagi.';

/// Throws [LocationUnavailable] when [fix] comes from a mock location app,
/// so evidence is never sent with a fake position.
void ensureRealLocation(DeviceLocation fix) {
  if (fix.mock) throw const LocationUnavailable(mockLocationMessage);
}

/// Thrown by [LocationService.current] when no fix could be read.
class LocationUnavailable implements Exception {
  final LocationAccess? access;
  final String message;

  const LocationUnavailable(this.message, {this.access});

  @override
  String toString() => 'LocationUnavailable: $message';
}

abstract class LocationService {
  Future<LocationAccess> access();

  /// Shows the OS permission prompt when possible.
  Future<LocationAccess> requestAccess();

  /// A fresh high-accuracy fix. Throws [LocationUnavailable].
  Future<DeviceLocation> current();

  /// Opens the phone's location settings ([LocationAccess.serviceOff]) or
  /// the app settings ([LocationAccess.deniedForever]).
  Future<void> openSettings(LocationAccess access);

  double distanceM(double lat1, double lng1, double lat2, double lng2);
}

class GeolocatorLocationService implements LocationService {
  const GeolocatorLocationService();

  @override
  Future<LocationAccess> access() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    return _map(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> requestAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationAccess.serviceOff;
    }
    return _map(await Geolocator.requestPermission());
  }

  @override
  Future<DeviceLocation> current() async {
    final state = await access();
    if (state != LocationAccess.granted) {
      throw LocationUnavailable('Izin lokasi belum diberikan.', access: state);
    }
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          timeLimit: Duration(seconds: 20),
        ),
      );
      return DeviceLocation(
        latitude: p.latitude,
        longitude: p.longitude,
        accuracyM: p.accuracy,
        mock: p.isMocked,
        readAt: DateTime.now(),
      );
    } catch (_) {
      throw const LocationUnavailable(
        'Lokasi belum didapat. Pastikan GPS aktif dan coba di tempat '
        'terbuka.',
      );
    }
  }

  @override
  Future<void> openSettings(LocationAccess access) async {
    if (access == LocationAccess.serviceOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  double distanceM(double lat1, double lng1, double lat2, double lng2) =>
      Geolocator.distanceBetween(lat1, lng1, lat2, lng2);

  static LocationAccess _map(LocationPermission p) => switch (p) {
        LocationPermission.always ||
        LocationPermission.whileInUse =>
          LocationAccess.granted,
        LocationPermission.deniedForever => LocationAccess.deniedForever,
        _ => LocationAccess.needsPermission,
      };
}
