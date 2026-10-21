import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import '../urls.dart';

class ProfileDetailsDisplay extends StatefulWidget {
  final String email;
  const ProfileDetailsDisplay({Key? key, required this.email}) : super(key: key);

  @override
  State<ProfileDetailsDisplay> createState() => _ProfileDetailsDisplayState();
}

class _ProfileDetailsDisplayState extends State<ProfileDetailsDisplay> {
  String profileImageUrl = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getProfileImage();
  }

  Widget _buildAvatarImage() {
    if (profileImageUrl.isEmpty) {
      return const Icon(
        Icons.person_rounded,
        size: 80,
        color: AppColors.textSecondary,
      );
    }

    if (profileImageUrl.startsWith('http://') || profileImageUrl.startsWith('https://')) {
      return Image.network(
        profileImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.person_rounded,
          size: 80,
          color: AppColors.textSecondary,
        ),
      );
    }

    if (!kIsWeb) {
      try {
        final f = File(profileImageUrl);
        if (f.existsSync()) {
          return Image.file(
            f,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.person_rounded,
              size: 80,
              color: AppColors.textSecondary,
            ),
          );
        }
      } catch (_) {}
    }

    return const Icon(
      Icons.person_rounded,
      size: 80,
      color: AppColors.textSecondary,
    );
  }

  Future<void> getProfileImage() async {
    try {
      var response = await http.post(
        Uri.parse(api.ip + '/get_profile_image'),
        headers: {'Content-Type': 'application/json'},
        body: '{"Email_ID": "${widget.email}"}',
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        String imageUrl = responseData['ProfileImage'] ?? '';

        if (mounted) {
          setState(() {
            profileImageUrl = imageUrl;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        print('Failed to get profile image: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error: $e');
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
          'Profile Photo',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(32),
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const CircularProgressIndicator(color: AppColors.patientPrimary)
                  else if (profileImageUrl.isNotEmpty)
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _buildAvatarImage(),
                      ),
                    )
                  else
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.patientSecondary.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 80,
                        color: AppColors.patientPrimary,
                      ),
                    ),
                  const SizedBox(height: 20),
                  Text(
                    widget.email,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Patient Account',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
