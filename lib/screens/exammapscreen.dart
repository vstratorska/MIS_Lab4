import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

class ExamMapScreen extends StatefulWidget {
  final Map<DateTime, List<Map<String, String>>> examSchedule;

  ExamMapScreen({required this.examSchedule});

  @override
  _ExamMapScreenState createState() => _ExamMapScreenState();
}

class _ExamMapScreenState extends State<ExamMapScreen> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _routeCoordinates = [];
  LatLng _currentPosition = LatLng(0, 0);
  bool _isLoading = true;
  LatLng? _selectedDestination;

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get the current location
    return await Geolocator.getCurrentPosition();
  }


  Future<void> _initializeMap() async {
    try {
      // Determine user's current location
      Position position = await _determinePosition();
      _currentPosition = LatLng(position.latitude, position.longitude);

      Set<Marker> newMarkers = {
        Marker(
          markerId: MarkerId("user"),
          position: _currentPosition,
          infoWindow: InfoWindow(title: 'Your Current Location'),
        ),
      };

      // Add exam markers and routes
      for (var entry in widget.examSchedule.entries) {
        for (var exam in entry.value) {
          if (exam.containsKey('latitude') && exam.containsKey('longitude')) {
            LatLng examLocation = LatLng(
              double.parse(exam['latitude']!),
              double.parse(exam['longitude']!),
            );
            newMarkers.add(
              Marker(
                markerId: MarkerId('${exam['subject']}-${entry.key}'),
                position: examLocation,
                infoWindow: InfoWindow(
                  title: exam['subject'],
                  snippet: 'Date: ${entry.key.day}/${entry.key.month}/${entry.key.year} | Time: ${exam['time']}',
                ),
                onTap: () {
                  setState(() {
                    _selectedDestination = examLocation;
                  });
                },
              ),
            );
          }
        }
      }

      setState(() {
        _markers = newMarkers;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _showRoute(LatLng destination) async {
    final String googleApiKey = 'AIzaSyAWZnEqpFuCXjuZ34El_Y-YDeODS63jbk0';

    try {
      List<LatLng> coordinates = await _getRouteCoordinates(_currentPosition, destination, googleApiKey);
      setState(() {
        _routeCoordinates = coordinates;
        _polylines = {
          Polyline(
            polylineId: PolylineId('route'),
            points: _routeCoordinates,
            color: Colors.red,
            width: 4,
          ),
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching route: $e')));
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15,
            ),
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: () async {
                if (_selectedDestination != null) {
                  await _showRoute(_selectedDestination!);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No destination selected.')),
                  );
                }
              },
              child: Text('Show Route'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<List<LatLng>> _getRouteCoordinates(LatLng origin, LatLng destination, String apiKey) async {
  final String url =
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    if (data['status'] == 'OK') {
      final route = data['routes'][0]['legs'][0];
      final List<LatLng> coordinates = _decodePolyline(route['steps']);
      return coordinates;
    } else {
      throw Exception('Error fetching directions: ${data['status']}');
    }
  } else {
    throw Exception('Failed to load route data');
  }
}

List<LatLng> _decodePolyline(List<dynamic> steps) {
  List<LatLng> polylineCoordinates = [];
  for (var step in steps) {
    if (step['polyline'] != null) {
      final polyline = step['polyline']['points'];
      final decodedPoints = _decodePolylineFromGoogle(polyline);
      polylineCoordinates.addAll(decodedPoints);
    }
  }
  return polylineCoordinates;
}

List<LatLng> _decodePolylineFromGoogle(String encoded) {
  List<LatLng> points = [];
  int index = 0;
  int len = encoded.length;
  int lat = 0;
  int lng = 0;

  while (index < len) {
    int b;
    int shift = 0;
    int result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lat += dLat;

    shift = 0;
    result = 0;
    do {
      b = encoded.codeUnitAt(index++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
    } while (b >= 0x20);
    int dLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
    lng += dLng;

    points.add(LatLng(lat / 1E5, lng / 1E5));
  }
  return points;
}
