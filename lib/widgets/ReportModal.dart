import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

class ReportModal extends StatefulWidget {
  final Function(String, String) onSubmit;

  ReportModal({required this.onSubmit});

  @override
  _ReportModalState createState() => _ReportModalState();
}

class _ReportModalState extends State<ReportModal> {
  TextEditingController problemController = TextEditingController();
  TextEditingController solutionController = TextEditingController();
  File? _imageFile;
  String? _fileName;
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

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

  Future<void> _pickImageAndUpload() async {
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
        _imageFile = File(image!.path);
      });

      final String uploadUrl = 'http://localhost:3000/upload';
      final Uri uri = Uri.parse(uploadUrl);
      final multipartRequest = http.MultipartRequest('POST', uri);
      multipartRequest.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: image.name,
        ),
      );

      try {
        final streamedResponse = await multipartRequest.send();
        final response = await http.Response.fromStream(streamedResponse);
        if (response.statusCode == 201) {
          final data = json.decode(response.body);
          final SharedPreferences prefs = await _prefs;
          prefs.setString('fileName', data['fileName']);
          print("uploaded image : ${data['fileName']}");
        } else {
          print('Failed to upload image: ${response.statusCode}');
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  Future<void> _searchSolution() async {
    final String problem = problemController.text;
    final Uri searchUri = Uri.parse('http://localhost:3000/search/donetasks?problem=$problem');
    try {
      final response = await http.get(searchUri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        solutionController.text = data['solution'];
      } else {
        print('Failed to fetch solution: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching solution: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report problem'),
      content: Container(
        width: double.maxFinite, // Take up full width of the AlertDialog
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: problemController,
                    decoration: InputDecoration(labelText: 'Problem'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _searchSolution,
                ),
              ],
            ),
            SizedBox(height: 10),
            TextField(
              controller: solutionController,
              decoration: InputDecoration(labelText: 'Solution'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImageAndUpload,
              child: Text('Pick Image'),
            ),
            SizedBox(height: 10),
            _imageFile != null
                ? Image.file(_imageFile!)
                : Text('No image selected'),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: Text('Submit'),
          onPressed: () {
            String problem = problemController.text;
            String solution = solutionController.text;
            widget.onSubmit(problem, solution);
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
