import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testing/screens/RoomSelect.dart';
import 'Signup.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  String _errorMessage = '';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  Future<void> _login() async {
    setState(() {
      _errorMessage = '';
    });

    final formData = {
      'username': _usernameController.text,
      'password': _passwordController.text,
    };

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'All fields are required';
      });
      return;
    }

    final String apiUrl = 'http://localhost:3000/users/login';
    final url = Uri.parse(apiUrl);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final userId = responseData['userId'];
        final role = responseData['role'];

        if (role == null || role.toString().isEmpty) {
          setState(() {
            _errorMessage = 'Your account is awaiting admin verification';
          });
          return;
        }

        final SharedPreferences prefs = await _prefs;
        prefs.setString('user_id', userId.toString()).then((bool success) {
          if (success) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RoomSelect()),
            );
          }
        });

        print('Login successful: User ID - $userId, Role - $role');
      } else if (response.statusCode == 404) {
        setState(() {
          _errorMessage = 'User was not found';
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _errorMessage = 'Invalid password';
        });
      } else {
        print('Login failed: ${response.body}');
      }
    } catch (error) {
      print('Error sending request: $error');
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Center(
                child: Image.asset(
                  'assets/images/logo.png', // Add a logo image in your assets
                  height: 100,
                ),
              ),
              SizedBox(height: 32.0),
              if (_errorMessage.isNotEmpty) ...[
                Container(
                  color: Colors.red,
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.white),
                      SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.0),
              ],
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _login,
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white, // Change the text color to white
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: Text(
                  "Don't have an account? Sign up",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    decoration: TextDecoration.underline,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
