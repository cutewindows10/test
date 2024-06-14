import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CompletedTasksScreen extends StatefulWidget {
  @override
  _CompletedTasksScreenState createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  List<CompletedItem> completedItems = [];
  bool isLoading = true;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    fetchCompletedTasks();
  }

  Future<void> fetchCompletedTasks() async {
    final SharedPreferences prefs = await _prefs;
    final userID = prefs.getString('user_id');
    String url = 'http://localhost:3000/donetasks?userID=$userID';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      List<CompletedItem> loadedItems =
          data.map((item) => CompletedItem.fromJson(item)).toList();

      List<CompletedItem> loadedItemsData = [];

      for (var item in loadedItems) {
        if (item.taskID != null) {
          String url = "http://localhost:3000/tasks/${item.taskID}";
          final response = await http.get(Uri.parse(url));

          final task = json.decode(response.body);
          item.taskTitle = task["taskTitle"];
          loadedItemsData.add(item);
        } else if (item.equipmentID != null) {
          String url = "http://localhost:3000/equipments/${item.equipmentID}";
          final response = await http.get(Uri.parse(url));
          final equipment = json.decode(response.body);
          item.equipmentName = equipment["equipmentName"];
          loadedItemsData.add(item);
        }
      }

      setState(() {
        completedItems = loadedItemsData;
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load completed tasks');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Completed Tasks and Equipments'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Title')),
                        DataColumn(label: Text('Okay')),
                        DataColumn(label: Text('Problem')),
                        DataColumn(label: Text('Solution')),
                        DataColumn(label: Text('Room ID')),
                        DataColumn(label: Text('User ID')),
                      ],
                      rows: completedItems.map((item) {
                        return DataRow(cells: [
                          DataCell(Text(item.taskID != null
                              ? 'Task Title: ${item.taskTitle}'
                              : 'Equipment Name: ${item.equipmentName}')),
                          DataCell(Icon(
                              item.okay ? Icons.check_circle : Icons.error,
                              color: item.okay ? Colors.green : Colors.red)),
                          DataCell(Text(item.problem ?? 'None')),
                          DataCell(Text(item.solution ?? 'None')),
                          DataCell(Text(item.roomID?.toString() ?? 'None')),
                          DataCell(Text(item.userID.toString())),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class CompletedItem {
  final int doneTaskID;
  final int? taskID;
  final int? equipmentID;
  String? taskTitle;
  String? equipmentName;
  final DateTime? date;
  final String? photo;
  final bool okay;
  final String? problem;
  final String? solution;
  final int userID;
  final int? roomID;
  final DateTime createdAt;
  final DateTime updatedAt;

  CompletedItem({
    required this.doneTaskID,
    this.taskID,
    this.equipmentID,
    this.taskTitle,
    this.equipmentName,
    this.date,
    this.photo,
    required this.okay,
    this.problem,
    this.solution,
    required this.userID,
    this.roomID,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CompletedItem.fromJson(Map<String, dynamic> json) {
    print(json); // Debug print
    return CompletedItem(
      doneTaskID: json['doneTaskID'],
      taskID: json['taskID'],
      equipmentID: json['equipmentID'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      photo: json['photo'],
      okay: json['okay'],
      problem: json['problem'],
      solution: json['solution'],
      userID: json['userID'],
      roomID: json['roomID'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
