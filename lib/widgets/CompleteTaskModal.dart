import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ImageCaptureModal extends StatefulWidget {
  final Function onComplete;
  final dynamic item; // Add this line

  ImageCaptureModal(
      {required this.onComplete, required this.item}); // Add item parameter

  @override
  _ImageCaptureModalState createState() => _ImageCaptureModalState();
}

class _ImageCaptureModalState extends State<ImageCaptureModal> {
  Uint8List? _imageBytes;
  File? _image;
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
        _imageBytes = bytes;
      });

      final String uploadUrl = 'http://localhost:3000/upload';
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
          final SharedPreferences prefs = await _prefs;
          final url = Uri.parse('http://localhost:3000/donetasks');

          final requestData = {
            'photo': _fileName,
            'userID': int.parse(prefs.getString('user_id')!),
            'okay': 1,
            'problem': "",
            'solution': "",
            'roomID': prefs.getInt('room_id')!,
          };

          if (prefs.containsKey('task_id') == false) {
            requestData["taskID"] = null;
            requestData["equipmentID"] = prefs.getInt('equipment_id')!;
          } else {
            requestData["taskID"] = prefs.getInt('task_id')!;
            requestData["equipmentID"] = null;
          }

          final responseDoneTask = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(requestData),
          );

          print(requestData);

          widget.onComplete(); // Call onComplete to remove the item
        } else {
          print('Failed to upload image: ${response.statusCode}');
        }
      } catch (e) {
        print('Error uploading image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Capture Image',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _image == null ? Text('No image selected.') : Image.file(_image!),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImageAndUpload,
              child: Text('Capture and Upload Image'),
            ),
            SizedBox(height: 16),
            _fileName != null
                ? Text('File uploaded successfully: $_fileName')
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
