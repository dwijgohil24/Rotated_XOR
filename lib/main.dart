import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BMP XOR Processor',
      theme: ThemeData.dark(),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? image1;
  File? image2;
  File? xorImage;
  bool isLoading = false;

  Future<void> pickImage(int index) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        if (index == 1) {
          image1 = File(pickedFile.path);
        } else {
          image2 = File(pickedFile.path);
        }
      });
    }
  }

  Future<void> performXor() async {
    if (image1 == null || image2 == null) return;
    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://cryptographydecodeapi-production.up.railway.app/xor"), // API-Endpoint updated with Live production based secure API endpoint.
      );

      request.files.add(await http.MultipartFile.fromPath('image1', image1!.path));
      request.files.add(await http.MultipartFile.fromPath('image2', image2!.path));

      var response = await request.send();

      if (response.statusCode == 200) {
        // Save the response image
        var bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/xor_result.bmp';
        File file = File(filePath);
        await file.writeAsBytes(bytes);

        setState(() {
          xorImage = file;
          isLoading = false;
        });
      } else {
        showError("Failed to process images");
      }
    } catch (e) {
      showError("Error: $e");
    }
  }

  void showError(String message) {
    setState(() => isLoading = false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
      ),
    );
  }

  Widget buildImageContainer(File? image) {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.blueAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: image != null ? Image.file(image, fit: BoxFit.cover) : Icon(Icons.image, size: 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("BMP XOR Processor"), centerTitle: true),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildImageContainer(image1),
                buildImageContainer(image2),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () => pickImage(1), child: Text("Select Image 1")),
                ElevatedButton(onPressed: () => pickImage(2), child: Text("Select Image 2")),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: performXor, child: Text("Perform XOR")),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator()
                : xorImage != null
                ? Column(
              children: [
                Text("XOR Result"),
                buildImageContainer(xorImage),
              ],
            )
                : Container(),
          ],
        ),
      ),
    );
  }
}
