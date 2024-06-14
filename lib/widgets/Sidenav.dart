import 'package:flutter/material.dart';

class SideNav extends StatelessWidget {
  const SideNav();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            height: 100, // Adjust the height of the header
            child: DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF6A5ACD), // New color from the image
              ),
              child: Row(
                children: [
                  Icon(Icons.menu, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.assignment),
            title: Text('Tasks'),
            onTap: () {
              Navigator.pushNamed(context, '/tasks'); // Navigate to tasks page
            },
          ),
          ListTile(
            leading: Icon(Icons.check_circle_outline),
            title: Text('Completed Tasks'),
            onTap: () {
              Navigator.pushNamed(
                  context, '/taskscompleted'); // Navigate to equipments page
            },
          ),
          ListTile(
            leading: Icon(Icons.exit_to_app),
            title: Text('Sign Out'),
            onTap: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}
