// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart'; 

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: ImageFetcher(),
    );
  }
}

class ImageFetcher extends StatefulWidget {
  const ImageFetcher({super.key});

  @override
  State<ImageFetcher> createState() => _ImageFetcherState();
}

class _ImageFetcherState extends State<ImageFetcher> {
  final TextEditingController _controller = TextEditingController();
  String? _imagePath; 
  bool _isLoading = false;
  File? _downloadedImage;

  Future<void> fetchImage(String userInput) async {
    setState(() {
      _isLoading = true; 
    });

    // Show a Snackbar indicating the process has started
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing the image, please wait...'),
        duration: Duration(seconds: 2),
      ),
    );

    final url = Uri.parse(
        'https://api-inference.huggingface.co/models/black-forest-labs/FLUX.1-schnell');
    final headers = {
      'Authorization':
          'Bearer Replace with your actual API token', // Replace with your actual API token
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({'inputs': userInput});

    try {
      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        // Save image to local storage
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/generated_image.jpg';
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _imagePath = filePath;
          _downloadedImage = file;
          _isLoading = false;
        });

       
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image processed successfully!'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        setState(() {
          _isLoading = false; 
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: ${response.statusCode}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false; 
      });

    
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void shareImage() async {
    if (_downloadedImage != null) {
      await Share.shareXFiles([XFile(_downloadedImage!.path)],
          text: 'Check out this image!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Generator'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(onPressed: _imagePath != null
                  ? () async {
                      shareImage();
                    }
                  : null,child: const Icon(Icons.share),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width*0.9,
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Enter input',
                  border: OutlineInputBorder()
                ),
                
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                fetchImage(_controller.text);
              },
              child: const Text('Get Image'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator() // Show loading indicator
                : _imagePath != null
                    ? Image.file(File(_imagePath!)) // Show downloaded image
                    : const Text('Enter input and press the button to see an image'),
             SizedBox(height: MediaQuery.of(context).size.height*0.2),
            const Text("Powered by Hanami UX",style: TextStyle(fontSize: 15),)
           
          ],
        ),
      ),
    );
  }
}
