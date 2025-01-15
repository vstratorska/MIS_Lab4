import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:labs4/screens/examcalendarscreen.dart';
import 'package:location/location.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

import 'service/locationservice.dart';

void main() {
  runApp(ExamCalendarApp());
}

class ExamCalendarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ExamCalendarScreen(),
      theme: ThemeData(primarySwatch: Colors.pink),
    );
  }
}

