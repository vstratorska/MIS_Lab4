import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:labs4/screens/exammapscreen.dart';
import 'package:location/location.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;

import '../service/locationservice.dart';
import 'mapselectionscreen.dart';

class ExamCalendarScreen extends StatefulWidget {
  @override
  _ExamCalendarScreenState createState() => _ExamCalendarScreenState();
}

class _ExamCalendarScreenState extends State<ExamCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Map<String, String>>> _examSchedule = {};
  final LocationService locationService = LocationService();

  @override
  void initState() {
    super.initState();
    locationService.initializeNotifications();
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    return _examSchedule[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  void _addExam(DateTime date, String time, String subject, LatLng location) {
    final formattedDate = DateTime.utc(date.year, date.month, date.day);
    setState(() {
      if (_examSchedule[formattedDate] == null) {
        _examSchedule[formattedDate] = [];
      }
      _examSchedule[formattedDate]!.add({
        'subject': subject,
        'time': time,
        'latitude': location.latitude.toString(),
        'longitude': location.longitude.toString(),
      });
    });
    locationService.checkProximityAndNotify(location.latitude, location.longitude, subject);
  }

  void _showAddExamDialog() {
    final _formKey = GlobalKey<FormState>();
    DateTime selectedDate = _selectedDay ?? _focusedDay;
    String subject = '';
    String time = '';
    LatLng? selectedLatLng;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Exam'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: 'Subject'),
                  onChanged: (value) => subject = value,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter a subject' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: 'Time'),
                  onChanged: (value) => time = value,
                  validator: (value) =>
                  value == null || value.isEmpty ? 'Enter a time' : null,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapSelectionScreen(),
                      ),
                    );
                    if (result is LatLng) {
                      setState(() {
                        selectedLatLng = result;
                      });
                    }
                  },
                  child: Text(selectedLatLng == null
                      ? 'Choose Location'
                      : 'Location Selected'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text('Add'),
              onPressed: () {
                if (_formKey.currentState!.validate() &&
                    selectedLatLng != null) {
                  _addExam(selectedDate, time, subject, selectedLatLng!);
                  Navigator.pop(context);
                } else if (selectedLatLng == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a location.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exam Calendar'),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 1, 1),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader: _getEventsForDay,
            headerStyle: HeaderStyle(
              formatButtonVisible: false, // Hides the "two weeks" button
              titleCentered: true, // Centers the title
              titleTextStyle: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            calendarStyle: CalendarStyle(
              selectedDecoration: BoxDecoration(
                color: Colors.pink, // Changes the selected day color to pink
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.pink[
                200], // Highlights today's date with a similar color
                shape: BoxShape.circle,
              ),
              selectedTextStyle:
              TextStyle(color: Colors.white), // Selected day text color
            ),
          ),
          const SizedBox(height: 8.0),
          Expanded(
            flex: 2, // Adjust the height of the list relative to the map
            child: ListView(
              children: _getEventsForDay(_selectedDay ?? _focusedDay)
                  .map((event) => ListTile(
                title: Text(event['subject']!),
                subtitle: Text(
                    'Time: ${event['time']} | Location: ${event['latitude']}, ${event['longitude']}'),
              ))
                  .toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _showAddExamDialog,
            child: Icon(Icons.add),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) =>  ExamMapScreen(examSchedule: _examSchedule)),
              );
            },
            child: Icon(Icons.map),
          ),
        ],
      ),
    );
  }
}