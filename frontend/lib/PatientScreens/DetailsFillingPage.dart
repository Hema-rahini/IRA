import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'HomePageNav.dart';

class DetailsUpdatePage extends StatefulWidget {
  final String email;
  const DetailsUpdatePage({Key? key, required this.email}) : super(key: key);

  @override
  State<DetailsUpdatePage> createState() => _DetailsUpdatePageState();
}

class _DetailsUpdatePageState extends State<DetailsUpdatePage> {
  String base64Image = "";

  String _age = "";
  String _height = "";
  String _weight = "";
  String _occupation = "";
  Uint8List? _profileBytes;
  String? _selectedGender;
  String username = "";
  bool _isSaving = false;

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
        String fetchedUsername = responseData['Name'] ?? '';

        if (mounted) {
          setState(() {
            username = fetchedUsername;
          });
        }
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  final ImagePicker _imagePicker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      List<int> imageBytes = await pickedFile.readAsBytes();
      base64Image = base64Encode(imageBytes);
      if (mounted) {
        setState(() {
          _profileBytes = Uint8List.fromList(imageBytes);
        });
      }
    }
  }

  Future<void> onUploadImage() async {
    try {
      if (base64Image.isEmpty) return;

      await http.post(
        Uri.parse(api.ip + "/upload"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"image": base64Image, "Email_ID": widget.email}),
      );
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  Future<void> _updateDetails() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (base64Image.isNotEmpty) {
        await onUploadImage();
      }

      Map<String, dynamic> data = {
        'Email_ID': widget.email,
        'Age': _age,
        'Height': _height,
        'Weight': _weight,
        'Gender': _selectedGender ?? '',
        'Occupation': _occupation,
        'ProfileImage': widget.email + '.jpg',
      };

      var response = await http.post(
        Uri.parse(api.ip + '/update_details'),
        body: jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile details saved successfully!'),
            backgroundColor: AppColors.positiveGreen,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PhomePage(email: widget.email)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update details (${response.statusCode})'),
            backgroundColor: AppColors.negativeRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating details: $e'),
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
        title: const Text('Complete Bio-Data'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Container(
          padding: const EdgeInsets.all(22.0),
          decoration: AppStyles.cardDecoration(
            backgroundColor: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar Picker with Camera Badge
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
                        radius: 50,
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
              const SizedBox(height: 12),
              Text(
                username.isNotEmpty ? username : 'New Patient',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Inputs
              _buildFieldLabel('Age (Years)'),
              const SizedBox(height: 6),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) => _age = value,
                decoration: AppStyles.inputDecoration(
                  hintText: 'e.g., 25',
                  prefixIcon: const Icon(Icons.cake_outlined, color: AppColors.patientPrimary, size: 20),
                ),
              ),

              const SizedBox(height: 16),
              _buildFieldLabel('Height (cm)'),
              const SizedBox(height: 6),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) => _height = value,
                decoration: AppStyles.inputDecoration(
                  hintText: 'e.g., 175',
                  prefixIcon: const Icon(Icons.height_rounded, color: AppColors.patientPrimary, size: 20),
                ),
              ),

              const SizedBox(height: 16),
              _buildFieldLabel('Weight (kg)'),
              const SizedBox(height: 6),
              TextField(
                keyboardType: TextInputType.number,
                onChanged: (value) => _weight = value,
                decoration: AppStyles.inputDecoration(
                  hintText: 'e.g., 70',
                  prefixIcon: const Icon(Icons.monitor_weight_outlined, color: AppColors.patientPrimary, size: 20),
                ),
              ),

              const SizedBox(height: 16),
              _buildFieldLabel('Occupation'),
              const SizedBox(height: 6),
              TextField(
                onChanged: (value) => _occupation = value,
                decoration: AppStyles.inputDecoration(
                  hintText: 'e.g., Software Engineer, Student',
                  prefixIcon: const Icon(Icons.work_outline_rounded, color: AppColors.patientPrimary, size: 20),
                ),
              ),

              const SizedBox(height: 16),
              _buildFieldLabel('Gender'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                hint: const Text('Select your gender', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                items: const [
                  DropdownMenuItem(value: "Male", child: Text("Male")),
                  DropdownMenuItem(value: "Female", child: Text("Female")),
                  DropdownMenuItem(value: "Others", child: Text("Others")),
                ],
                onChanged: (newValue) {
                  setState(() {
                    _selectedGender = newValue;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.people_outline_rounded, color: AppColors.patientPrimary, size: 20),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.patientPrimary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _updateDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.patientPrimary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
