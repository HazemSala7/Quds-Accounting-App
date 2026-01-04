// Step 1: Create a custom StatefulWidget for the progress dialog
import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Server/server.dart';

class ProgressDialog extends StatefulWidget {
  @override
  _ProgressDialogState createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<ProgressDialog> {
  double progressValue = 0.0;

  // Function to simulate progress
  void updateProgress() async {
    for (int i = 0; i <= 100; i++) {
      await Future.delayed(Duration(milliseconds: 50)); // Simulate a delay
      setState(() {
        progressValue = i / 100.0; // Update the progress value
      });
    }
  }

  @override
  void initState() {
    super.initState();
    updateProgress(); // Start the progress update when the dialog is shown
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${(progressValue * 100).toInt()}%",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: progressValue, // Set the progress value here
              backgroundColor: Colors.grey[300],
              color: Main_Color, // Replace with your desired color
            ),
          ],
        ),
      ),
    );
  }
}
