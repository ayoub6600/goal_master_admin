import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeFormatter extends StatelessWidget {
  final String startTime; // مثل: "23:00:00"
  final String endTime; // مثل: "00:00:00"

  const TimeFormatter(
      {super.key, required this.startTime, required this.endTime});

  String formatTime(String timeString) {
    final dateTime = DateFormat("HH:mm:ss").parse(timeString);
    return DateFormat("h:mm a").format(dateTime); // مثل: 11:00 PM
  }

  @override
  Widget build(BuildContext context) {
    final formattedStart = formatTime(startTime);
    final formattedEnd = formatTime(endTime);

    return Text('$formattedStart - $formattedEnd');
  }
}
