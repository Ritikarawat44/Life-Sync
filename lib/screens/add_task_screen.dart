import 'package:flutter/material.dart';

class AddTaskScreen extends StatefulWidget {
  @override
  _AddTaskScreenState createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  TextEditingController controller = TextEditingController();

  void saveTask() {
    if (controller.text.trim().isEmpty) return;
    Navigator.pop(context, controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Task"),
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "Enter task...",
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveTask,
              child: Text("Add Task"),
            ),
          ],
        ),
      ),
    );
  }
}