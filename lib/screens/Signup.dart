import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'Login.dart';

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  Uint8List? _imageBytes;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _cinController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  bool? _success = false;
  String _fileName = "";

  int? _selectedBranchId; // Track the selected branch ID
  List<Map<String, dynamic>> _branches = []; // List to store branches

  @override
  void initState() {
    super.initState();
    _fetchBranches(); // Call method to fetch branches when screen initializes
  }

  void _fetchBranches() async {
    final String apiUrl = 'http://localhost:3000/branches';
    final url = Uri.parse(apiUrl);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _branches = data.cast<Map<String, dynamic>>();
        });
      } else {
        print('Failed to load branches: ${response.statusCode}');
        // Handle error loading branches
      }
    } catch (e) {
      print('Error loading branches: $e');
      // Handle network error
    }
  }

  Future<bool> hasCamera() async {
    if (Platform.isWindows) {
      // Initialize the cameras
      try {
        final cameras = await availableCameras();
        return cameras.isNotEmpty;
      } catch (e) {
        return false;
      }
    }
    return false; // Default false for non-Windows platforms
  }

  void _capturePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image;

    if (Platform.isAndroid) {
      image = await picker.pickImage(source: ImageSource.camera);
    } else if (Platform.isWindows) {
      if (await hasCamera()) {
        image = await picker.pickImage(source: ImageSource.camera);
      } else {
        image = await picker.pickImage(source: ImageSource.gallery);
      }
    } else {
      image = await picker.pickImage(source: ImageSource.gallery);
    }

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });

      // Now send a POST request to your upload endpoint
      final String uploadUrl =
          'http://localhost:3000/upload'; // Replace with your endpoint
      final Uri uri = Uri.parse(uploadUrl);
      final multipartRequest = http.MultipartRequest('POST', uri);
      multipartRequest.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: image.path.split('/').last,
        ),
      );

      try {
        final streamedResponse = await multipartRequest.send();
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          _fileName = data['fileName'];
          setState(() {
            _fileName = _fileName;
          });
          print(_fileName);
          // Handle success if needed
        } else {
          print('Failed to upload image: ${response.statusCode}');
          // Handle error
        }
      } catch (e) {
        print('Error uploading image: $e');
        // Handle network error
      }
    }
  }

  void _signUp() {
    setState(() {
      _errorMessage = null;
      _success = false;
    });
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        setState(() {
          _errorMessage = 'Password and confirmation do not match';
        });
        return;
      }

      final formData = {
        'name': _nameController.text,
        "username": _usernameController.text,
        'CIN': _cinController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'role': "",
        "branchID": _selectedBranchId,
        'photo': _fileName,
      };

      print(formData);

      final String apiUrl = 'http://localhost:3000/users/signup';
      final url = Uri.parse(apiUrl);

      http
          .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(formData),
      )
          .then((response) {
        if (response.statusCode == 201) {
          setState(() {
            _success = true;
          });
          print('User signed up successfully');
        } else if (response.statusCode == 409) {
          setState(() {
            _errorMessage = 'A user with the given username already exists';
          });
        } else {
          print('Failed to sign up: ${response.body}');
        }
      }).catchError((error) {
        print('Error sending request: $error');
      });
    } else {
      setState(() {
        _errorMessage = 'All fields are required';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.png', // Add a logo image in your assets
                  height: 100,
                ),
                SizedBox(height: 20),
                Text(
                  'Create Account',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_errorMessage != null)
                        Container(
                          padding: EdgeInsets.all(8.0),
                          color: Colors.red,
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.white),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_success == true)
                        Container(
                          padding: EdgeInsets.all(8.0),
                          color: Colors.green,
                          child: const Row(
                            children: [
                              Icon(Icons.check, color: Colors.white),
                              SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  "Your account has been created and is awaiting admin approval",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _cinController,
                        decoration: InputDecoration(
                          labelText: 'CIN',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your CIN';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        value: _selectedBranchId,
                        onChanged: (int? value) {
                          setState(() {
                            _selectedBranchId = value;
                          });
                        },
                        items: _branches.map((branch) {
                          return DropdownMenuItem<int>(
                            value: branch['branchID'],
                            child: Text(branch['branchName']),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Select Branch',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a branch';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      _imageBytes == null
                          ? Text('No image selected')
                          : Image.memory(_imageBytes!),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _capturePhoto,
                        child: Text('Capture Photo'),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _signUp,
                        child: Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).primaryColor,
                          minimumSize: Size(double.infinity,
                              50), // Set the minimum size to full width and height to 50
                          maximumSize: Size(double.infinity,
                              50), // Set the maximum size to full width and height to 50
                        ),
                      ),
                      SizedBox(height: 20),
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        },
                        child: Text(
                          'Already have an account? Login',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
