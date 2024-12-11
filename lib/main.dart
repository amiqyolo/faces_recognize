import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

void main() => runApp(const FaceRecognitionApp());

class FaceRecognitionApp extends StatelessWidget {
  const FaceRecognitionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FaceRecognitionScreen(),
    );
  }
}

class FaceRecognitionScreen extends StatefulWidget {
  const FaceRecognitionScreen({super.key});

  @override
  _FaceRecognitionScreenState createState() => _FaceRecognitionScreenState();
}

class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
  File? _referenceImage;
  File? _inputImage;
  String _result = "Upload two images to compare.";
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(bool isReference) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (isReference) {
          _referenceImage = File(pickedFile.path);
        } else {
          _inputImage = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> _compareFaces() async {
    if (_referenceImage == null || _inputImage == null) {
      setState(() {
        _result = "Both images are required.";
      });
      return;
    }

    final faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableContours: true,
        enableClassification: true,
      ),
    );

    // Analyze reference image
    final referenceInputImage = InputImage.fromFilePath(_referenceImage!.path);
    final inputInputImage = InputImage.fromFilePath(_inputImage!.path);

    final referenceFaces = await faceDetector.processImage(referenceInputImage);
    final inputFaces = await faceDetector.processImage(inputInputImage);

    if (referenceFaces.isEmpty || inputFaces.isEmpty) {
      setState(() {
        _result = "No faces detected in one or both images.";
      });
      return;
    }

    // Compare the largest face (e.g., first detected face)
    final referenceFace = referenceFaces.first;
    final inputFace = inputFaces.first;

    final similarityScore = _calculateSimilarity(referenceFace, inputFace);

    setState(() {
      _result = "Similarity: ${(similarityScore * 100).toStringAsFixed(2)}%";
    });

    faceDetector.close();
  }

  double _calculateSimilarity(Face face1, Face face2) {
    // Simplistic similarity calculation: compare smiling probability as an example
    final smileDifference =
        (face1.smilingProbability ?? 0) - (face2.smilingProbability ?? 0);
    return 1.0 - smileDifference.abs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Face Recognition"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildImagePreview(_referenceImage, "Reference Image"),
          ElevatedButton(
            onPressed: () => _pickImage(true),
            child: Text("Pick Reference Image"),
          ),
          SizedBox(height: 20),
          _buildImagePreview(_inputImage, "Input Image"),
          ElevatedButton(
            onPressed: () => _pickImage(false),
            child: Text("Pick Input Image"),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _compareFaces,
            child: Text("Compare Faces"),
          ),
          SizedBox(height: 20),
          Text(
            _result,
            style: TextStyle(fontSize: 16, color: Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(File? imageFile, String label) {
    return Column(
      children: [
        Text(label),
        SizedBox(height: 10),
        imageFile != null
            ? Image.file(imageFile, height: 150)
            : Container(
                width: 150,
                height: 150,
                color: Colors.grey[300],
                child: Center(child: Text("No image selected")),
              ),
      ],
    );
  }
}
