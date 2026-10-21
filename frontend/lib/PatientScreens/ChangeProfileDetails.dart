import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:ira/PatientScreens/settings.dart';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';

class ChangeProfileData extends StatefulWidget {
  final String email;

  const ChangeProfileData({Key? key, required this.email}) : super(key: key);

  @override
  State<ChangeProfileData> createState() => _ChangeProfileDataState();
}

class _ChangeProfileDataState extends State<ChangeProfileData> {
  String base64Image = "";

  String _name = "";
  String _bio = "";
  String _email = "";
  String _phone = "";
  String? _selectedGender;
  Uint8List? _profileBytes;
  String username = "";
  bool _isLoading = true;
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _getProfileData();
  }

  Future<void> _getProfileData() async {
    try {
      var response = await http.post(
        Uri.parse(api.ip + '/get_profile_image'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"Email_ID": widget.email}),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _name = responseData['Name'] ?? '';
            _bio = responseData['Occupation'] ?? '';
            _email = responseData['Email_ID'] ?? '';
            _phone = responseData['Mobile_No'] ?? '';
            _selectedGender = responseData['Gender'];
            username = _name;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching profile data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      List<int> imageBytes = await pickedFile.readAsBytes();
      if (mounted) {
        setState(() {
          base64Image = base64Encode(imageBytes);
          _profileBytes = Uint8List.fromList(imageBytes);
        });
      }
    }
  }

  Future<void> onUploadImage() async {
    if (base64Image.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a new profile photo to update'),
          backgroundColor: AppColors.negativeRed,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      var response = await http.post(
        Uri.parse(api.ip + "/upload"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": base64Image, "Email_ID": widget.email}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: AppColors.positiveGreen,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSettingsPage(
              email: widget.email,
              img: base64Image,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update photo (${response.statusCode})'),
            backgroundColor: AppColors.negativeRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $e'),
          backgroundColor: AppColors.negativeRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        title: const Text('Edit Profile Photo'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.patientPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Container(
                padding: const EdgeInsets.all(22.0),
                decoration: AppStyles.cardDecoration(
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  children: [
                    // Avatar Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.patientPrimary.withValues(alpha: 0.3), width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 54,
                              backgroundColor: AppColors.patientBackground,
                              backgroundImage: _profileBytes != null
                                  ? MemoryImage(_profileBytes!)
                                  : const AssetImage('assets/profilebanner.png') as ImageProvider<Object>,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.patientPrimary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      username.isNotEmpty ? username : 'Patient',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Read-only Information tiles
                    _buildInfoTile('Full Name', _name, Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    _buildInfoTile('Occupation', _bio, Icons.work_outline_rounded),
                    const SizedBox(height: 12),
                    _buildInfoTile('Email Address', _email, Icons.email_outlined),
                    const SizedBox(height: 12),
                    _buildInfoTile('Contact Number', _phone, Icons.phone_outlined),
                    if (_selectedGender != null && _selectedGender!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildInfoTile('Gender', _selectedGender!, Icons.people_outline_rounded),
                    ],

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: _isSaving
                            ? const SizedBox.shrink()
                            : const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: _isSaving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Save Profile Photo',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.patientPrimary,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _isSaving ? null : onUploadImage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.patientBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.patientPrimary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : '--',
                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
