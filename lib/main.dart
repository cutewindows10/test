import 'package:flutter/material.dart';
import 'package:testing/screens/Tasks.dart';
import 'package:testing/screens/TasksCompleted.dart';
import 'screens/login.dart'; // Import your login screen file
import 'screens/signup.dart'; // Import your signup screen file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To do app',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/login',
      routes: {
        '/': (context) => TasksScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) =>
            SignUpScreen(), // Add route to the signup screen

        '/tasks': (context) => TasksScreen(),
        '/taskscompleted': (context) => CompletedTasksScreen(),
      },
    );
  }
}
