import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testing/widgets/ReportModal.dart';
import 'package:testing/widgets/Sidenav.dart';
import '../widgets/CompleteTaskModal.dart';

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<Task> tasks = [];
  List<Equipment> equipments = [];

  List<dynamic> dailyItems = [];
  List<dynamic> weeklyItems = [];
  List<dynamic> monthlyItems = [];
  List<dynamic> yearlyItems = [];
  String _fileName = "";
  bool isLoading = true;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    fetchTasksAndEquipments();
  }

  Future<void> fetchTasksAndEquipments() async {
    final SharedPreferences prefs = await _prefs;
    final int? roomId = prefs.getInt('room_id');

    String tasksUrl = 'http://localhost:3000/tasks';
    String equipmentsUrl = 'http://localhost:3000/equipments?roomID=$roomId';
    String completedTasksUrl = 'http://localhost:3000/donetasks';

    final tasksResponse = await http.get(Uri.parse(tasksUrl));
    final equipmentsResponse = await http.get(Uri.parse(equipmentsUrl));
    final completedTasksResponse = await http.get(Uri.parse(completedTasksUrl));

    if (tasksResponse.statusCode == 200 &&
        equipmentsResponse.statusCode == 200 &&
        completedTasksResponse.statusCode == 200) {
      List<dynamic> tasksData = json.decode(tasksResponse.body);
      List<dynamic> equipmentsData = json.decode(equipmentsResponse.body);
      List<dynamic> completedTasksData =
          json.decode(completedTasksResponse.body);

      List<Task> loadedTasks =
          tasksData.map((task) => Task.fromJson(task)).toList();
      List<Equipment> loadedEquipments = equipmentsData
          .map((equipment) => Equipment.fromJson(equipment))
          .toList();

      List<int> completedTaskIds = completedTasksData
          .where((completedItem) => completedItem['taskID'] != null)
          .map<int>((completedItem) => completedItem['taskID'] as int)
          .toList();
      List<int> completedEquipmentIds = completedTasksData
          .where((completedItem) => completedItem['equipmentID'] != null)
          .map<int>((completedItem) => completedItem['equipmentID'] as int)
          .toList();

      tasks = loadedTasks
          .where((task) => !completedTaskIds.contains(task.taskID))
          .toList();
      equipments = loadedEquipments
          .where((equipment) =>
              !completedEquipmentIds.contains(equipment.equipmentID))
          .toList();

      dailyItems = [
        ...tasks.where((task) => task.checklistID == 1),
        ...equipments.where((equipment) => equipment.checklistID == 1)
      ];

      weeklyItems = [
        ...tasks.where((task) => task.checklistID == 2),
        ...equipments.where((equipment) => equipment.checklistID == 2)
      ];

      monthlyItems = [
        ...tasks.where((task) => task.checklistID == 3),
        ...equipments.where((equipment) => equipment.checklistID == 3)
      ];

      yearlyItems = [
        ...tasks.where((task) => task.checklistID == 4),
        ...equipments.where((equipment) => equipment.checklistID == 4)
      ];

      setState(() {
        isLoading = false;
      });

      print(dailyItems);
    }
  }

  void _removeItemFromList(dynamic item) {
    setState(() {
      dailyItems.remove(item);
      weeklyItems.remove(item);
      monthlyItems.remove(item);
      yearlyItems.remove(item);
      if (item is Task) {
        tasks.remove(item);
      } else if (item is Equipment) {
        equipments.remove(item);
      }
    });
  }

  void _openImageCaptureModal(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ImageCaptureModal(
          onComplete: () {
            _removeItemFromList(item);
          },
          item: item, // Pass the item here
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tasks and Equipments'),
      ),
      drawer: SideNav(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 32.0),
                  Text('Daily checklist'),
                  SizedBox(height: 32.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: buildDataTable(dailyItems, 'daily'),
                    ),
                  ),
                  SizedBox(height: 32.0),
                  Text('Weekly checklist'),
                  SizedBox(height: 32.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: buildDataTable(weeklyItems, 'weekly'),
                    ),
                  ),
                  SizedBox(height: 32.0),
                  Text('Monthly checklist'),
                  SizedBox(height: 32.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: buildDataTable(monthlyItems, 'monthly'),
                    ),
                  ),
                  SizedBox(height: 32.0),
                  Text('Yearly checklist'),
                  SizedBox(height: 32.0),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      child: buildDataTable(yearlyItems, 'yearly'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildDataTable(List<dynamic> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No $type items',
          style: TextStyle(
            color: Colors.red,
          ),
        ),
      );
    }

    return DataTable(
      columns: [
        DataColumn(label: Text('Title')),
        DataColumn(label: Text('Actions'))
      ],
      rows: items.map((item) {
        String title;
        IconData icon;
        if (item is Task) {
          title = item.taskTitle;
          icon = Icons.task; // Icon for tasks
        } else if (item is Equipment) {
          title = item.equipmentName;
          icon = Icons.build; // Icon for equipment
        } else {
          title = 'Unknown';
          icon = Icons.error; // Icon for unknown
        }
        return DataRow(cells: [
          DataCell(Row(
            children: [
              Icon(icon),
              SizedBox(width: 8),
              Text(title),
            ],
          )),
          DataCell(Row(
            children: [
              IconButton(
                icon: Icon(Icons.check_circle, color: Colors.green),
                onPressed: () async {
                  final SharedPreferences prefs = await _prefs;
                  if (item is Task) {
                    prefs.setInt('task_id', item.taskID);
                    prefs.remove('equipment_id');
                  } else {
                    prefs.setInt('equipment_id', item.equipmentID);
                    prefs.remove('task_id');
                  }
                  _openImageCaptureModal(context, item);
                },
              ),
              IconButton(
                icon: Icon(Icons.report_problem, color: Colors.red),
                onPressed: () async {
                  final SharedPreferences prefs = await _prefs;
                  if (item is Task) {
                    prefs.setInt('task_id', item.taskID);
                    prefs.remove('equipment_id');
                  } else {
                    prefs.setInt('equipment_id', item.equipmentID);
                    prefs.remove('task_id');
                  }
                  _openReportModal(context, item);
                },
              ),
            ],
          )),
        ]);
      }).toList(),
    );
  }

  void _openReportModal(BuildContext context, dynamic item) {
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ReportModal(
          onSubmit: (problem, solution) async {
            final SharedPreferences prefs = await _prefs;

            final data = {
              "okay": 0,
              "problem": problem,
              "solution": solution,
              "userID": int.parse(prefs.getString('user_id')!),
              "roomID": prefs.getInt('room_id')!,
              "taskID": null,
              "equipmentID": null,
              "photo":
                  prefs.getString('fileName') // Add the photo file name here
            };

            if (prefs.containsKey('task_id') == false) {
              data["taskID"] = null;
              data["equipmentID"] = prefs.getInt('equipment_id')!;
            } else {
              data["taskID"] = prefs.getInt('task_id')!;
              data["equipmentID"] = null;
            }

            final url = Uri.parse('http://localhost:3000/donetasks');

            final responseDoneTask = await http.post(
              url,
              headers: {'Content-Type': 'application/json'},
              body: json.encode(data),
            );

            // Optionally, remove the item from the list or mark it as reported
            _removeItemFromList(item);
          },
        );
      },
    );
  }
}

class Task {
  final int taskID;
  final String taskTitle;
  final int checklistID;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.taskID,
    required this.taskTitle,
    required this.checklistID,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      taskID: json['taskID'],
      taskTitle: json['taskTitle'],
      checklistID: json['checklistID'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class Equipment {
  final int equipmentID;
  final int roomID;
  final String equipmentName;
  final int checklistID;
  final DateTime createdAt;
  final DateTime updatedAt;

  Equipment({
    required this.equipmentID,
    required this.roomID,
    required this.equipmentName,
    required this.checklistID,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Equipment.fromJson(Map<String, dynamic> json) {
    return Equipment(
      equipmentID: json['equipmentID'],
      roomID: json['roomID'],
      equipmentName: json['equipmentName'],
      checklistID: json['checklistID'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
