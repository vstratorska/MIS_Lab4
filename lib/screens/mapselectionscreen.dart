import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;


class MapSelectionScreen extends StatefulWidget {
  @override
  _MapSelectionScreenState createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  LatLng? selectedLatLng;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Location'),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(42.003427134685474, 21.407355698444054),
          zoom: 15,
        ),
        onTap: (LatLng latLng) {
          setState(() {
            selectedLatLng = latLng;
          });
        },
        markers: selectedLatLng == null
            ? {}
            : {
          Marker(
            markerId: MarkerId('selected-location'),
            position: selectedLatLng!,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (selectedLatLng != null) {
            Navigator.pop(context, selectedLatLng);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select a location.')),
            );
          }
        },
        child: Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}