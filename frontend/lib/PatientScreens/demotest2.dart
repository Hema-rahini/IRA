import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../urls.dart';

class CheckImages extends StatefulWidget {
  const CheckImages({Key? key}) : super(key: key);

  @override
  State<CheckImages> createState() => _CheckImagesState();
}

class _CheckImagesState extends State<CheckImages> {
  List<String> base64Images = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAllImagesWithRetry();
  }

  Future<void> fetchAllImagesWithRetry() async {
    int maxRetries = 3;

    while (maxRetries > 0) {
      try {
        final response = await http.get(
          Uri.parse(api.ip + '/fetch_all_images'),
          headers: {
            'content-type': 'application/json',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          List<Map<String, dynamic>> imagesData =
              List<Map<String, dynamic>>.from(json.decode(response.body));

          if (mounted) {
            setState(() {
              base64Images =
                  imagesData.map((image) => image["base64_image"].toString()).toList();
              isLoading = false;
            });
          }
          break;
        } else {
          print('Failed to fetch images: ${response.statusCode}');
        }
      } catch (e) {
        print('Error: $e');
        maxRetries--;
        if (maxRetries > 0) {
          await Future.delayed(const Duration(seconds: 5));
        }
      }
    }

    if (mounted && isLoading) {
      setState(() {
        isLoading = false;
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
        title: const Text(
          'Image Gallery',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.patientPrimary),
            )
          : base64Images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined, size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'No images found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12.0,
                    mainAxisSpacing: 12.0,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: base64Images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          base64Decode(base64Images[index]),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_rounded, color: AppColors.textSecondary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
