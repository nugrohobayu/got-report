import 'package:ada_tugas/core/location/location_service.dart';

/// Location service for widget tests: permission state is set by the test,
/// fixes are fixed coordinates.
class FakeLocationService implements LocationService {
  LocationAccess accessState;
  int requests = 0;
  final List<LocationAccess> openedSettings = [];

  FakeLocationService({this.accessState = LocationAccess.granted});

  @override
  Future<LocationAccess> access() async => accessState;

  @override
  Future<LocationAccess> requestAccess() async {
    requests++;
    return accessState = LocationAccess.granted;
  }

  @override
  Future<DeviceLocation> current() async => DeviceLocation(
        latitude: -6.914744,
        longitude: 107.60981,
        accuracyM: 7,
        mock: false,
        readAt: DateTime.now(),
      );

  @override
  Future<void> openSettings(LocationAccess access) async =>
      openedSettings.add(access);

  @override
  double distanceM(double lat1, double lng1, double lat2, double lng2) => 0;
}
