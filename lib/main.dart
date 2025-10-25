import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Google Maps', home: const MyHomePage());
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  //Initialize Location
  final Location _locationController = Location();

  final Completer<GoogleMapController> _mapController =
      Completer<GoogleMapController>();
  static const _pGooglePlex = LatLng(37.7749, -122.4194);
  static const _pApplePark = LatLng(37.3382, -121.8863);
  LatLng? currentP = null;

  @override
  void initState() {
    super.initState();
    _getLocationUpdate().then((_) => {_getPolylinePoints()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Google Maps")),
      body: currentP == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.hybrid,
              initialCameraPosition: CameraPosition(
                target: _pGooglePlex,
                zoom: 13,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController.complete(controller);
              },
              markers: {
                Marker(
                  markerId: MarkerId("_currentLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _pGooglePlex,
                ),
                Marker(
                  markerId: MarkerId("_sourceLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _pApplePark,
                ),
                Marker(
                  markerId: MarkerId("_destinationLocation"),
                  icon: BitmapDescriptor.defaultMarker,
                  position: _pApplePark,
                ),
              },
            ),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _mapController.future;
    CameraPosition _newCameraPositon = CameraPosition(target: pos, zoom: 13);
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPositon),
    );
  }

  Future<void> _getLocationUpdate() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;

    serviceEnabled = await _locationController.serviceEnabled();
    if (serviceEnabled) {
      serviceEnabled = await _locationController.requestService();
    } else {
      return;
    }

    permissionGranted = await _locationController.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _locationController.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationController.onLocationChanged.listen((
      LocationData currentLocation,
    ) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          currentP = LatLng(
            currentLocation.latitude!,
            currentLocation.longitude!,
          );
          _cameraToPosition(currentP!);
        });
      }
    });
  }

  ///Legacy Direction API(Backward Compatibility

  Future<List<LatLng>> _getPolylinePoints() async {
    List<LatLng> polyLineCoordinates = [];

    //Initialize PolylinePoints
    PolylinePoints polylinePoints = PolylinePoints(
      apiKey: "AIzaSyCgc1ztY-jjwuP33XzSFwh4NGXeiq1deTY",
    );

    //Get route using legacy Directions API
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      request: PolylineRequest(
        origin: PointLatLng(37.7749, -122.4194), //San Francisco
        destination: PointLatLng(37.3382, -121.8863), //San Jose
        mode: TravelMode.driving,
      ),
    );

    if (result.points.isNotEmpty) {
      //Convert to LatLng for Google Maps
      result.points.forEach((PointLatLng point) {
        polyLineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    } else {
      print(result.errorMessage);
    }
    return polyLineCoordinates;
  }
}
