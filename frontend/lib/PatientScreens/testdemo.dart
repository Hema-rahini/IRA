import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../urls.dart';
import 'demotest2.dart';

class MyHomePag extends StatefulWidget {
  const MyHomePag({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePagState createState() => _MyHomePagState();
}

class _MyHomePagState extends State<MyHomePag> {
  dynamic resJson;
  String base64Image = "";
  bool isUploading = false;

  Future<void> onUploadImage() async {
    try {
      if (base64Image.isEmpty) return;

      setState(() {
        isUploading = true;
      });

      var response = await http.post(
        Uri.parse(api.ip + "/upload"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": base64Image, "Email_ID": 't'}),
      );

      if (mounted) {
        setState(() {
          resJson = jsonDecode(response.body);
          isUploading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploading = false;
        });
      }
      print("Error: $e");
    }
  }

  Future<void> getImage() async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image != null) {
      List<int> imageBytes = await image.readAsBytes();
      setState(() {
        base64Image = base64Encode(imageBytes);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded, color: AppColors.patientPrimary),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckImages()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Preview Card
              Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(
                  color: AppColors.patientSurface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: base64Image.isEmpty
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 64,
                            color: AppColors.textSecondary.withOpacity(0.4),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No image selected',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tap the camera button below to choose an image',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.memory(
                          base64Decode(base64Image),
                          fit: BoxFit.contain,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              if (isUploading)
                const CircularProgressIndicator(color: AppColors.patientPrimary)
              else
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: base64Image.isEmpty ? null : onUploadImage,
                    icon: const Icon(Icons.cloud_upload_rounded),
                    label: const Text(
                      'Upload Image',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ),

              if (resJson != null && resJson['message'] != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    resJson['message'].toString(),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.patientPrimary,
        foregroundColor: Colors.white,
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: const Icon(Icons.add_a_photo_rounded),
      ),
    );
  }
}
