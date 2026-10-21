import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:iconsax/iconsax.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({Key? key}) : super(key: key);

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  File? _videoFile;
  List<int>? _videoBytes;
  String? _fileName;
  String? _selectedActivity;
  String? _selectedAnger;
  bool _isUploading = false;

  final List<String> activityList = List.generate(26, (index) {
    int day = (index ~/ 2) + 1;
    int activity = index.isEven ? 1 : 2;
    return 'Day-$day Activity $activity';
  });

  final List<String> angerscale = [
    "Minimal Anger",
    "Mild Anger",
    "Moderate Anger",
    "Sever Anger",
  ];

  void uploadFile() async {
    if (_selectedActivity == null || _selectedAnger == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both Anger Scale and Activity Day'),
          backgroundColor: AppColors.negativeRed,
        ),
      );
      return;
    }

    if (_videoBytes == null && (_videoFile == null || _videoFile!.path.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file first'),
          backgroundColor: AppColors.negativeRed,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(api.ip + '/upload_video?activity=$_selectedActivity&scale=$_selectedAnger'),
      );

      if (_videoBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            _videoBytes!,
            filename: _fileName ?? 'video.mp4',
          ),
        );
      } else if (_videoFile != null && _videoFile!.path.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('file', _videoFile!.path));
      }
      var response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video activity uploaded successfully!'),
            backgroundColor: AppColors.positiveGreen,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed with status: ${response.statusCode}'),
            backgroundColor: AppColors.negativeRed,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload error: $e'),
          backgroundColor: AppColors.negativeRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _selectedAnger = null;
          _selectedActivity = null;
          _isUploading = false;
          _videoFile = null;
          _fileName = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.doctorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Upload Activity Video',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: AppColors.doctorPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Curriculum Media Management',
              style: TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Container(
          padding: const EdgeInsets.all(22.0),
          decoration: AppStyles.cardDecoration(
            backgroundColor: Colors.white,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Clinical Anger Severity',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedAnger,
                hint: const Text('Select Anger Scale category', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                items: angerscale.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAnger = value;
                  });
                },
                decoration: InputDecoration(
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
                    borderSide: const BorderSide(color: AppColors.doctorPrimary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              const Text(
                'Curriculum Day & Session',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedActivity,
                hint: const Text('Select Day and Activity Step', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                items: activityList.map((activity) {
                  return DropdownMenuItem<String>(
                    value: activity,
                    child: Text(activity, style: const TextStyle(fontSize: 15, color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedActivity = value;
                  });
                },
                decoration: InputDecoration(
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
                    borderSide: const BorderSide(color: AppColors.doctorPrimary, width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                'Video Lesson File',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              GestureDetector(
                onTap: () async {
                  FilePickerResult? result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mp4', 'mov', 'avi'],
                    withData: true,
                  );

                  if (result != null && result.files.isNotEmpty) {
                    final picked = result.files.single;
                    setState(() {
                      _fileName = picked.name;
                      _videoBytes = picked.bytes;
                      if (picked.path != null && picked.path!.isNotEmpty) {
                        _videoFile = File(picked.path!);
                      }
                    });
                  }
                },
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(16),
                  dashPattern: const [8, 4],
                  strokeWidth: 1.5,
                  color: (_videoFile != null || _videoBytes != null || _fileName != null) ? AppColors.positiveGreen : AppColors.doctorSecondary,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                    decoration: BoxDecoration(
                      color: ((_videoFile != null || _videoBytes != null || _fileName != null) ? AppColors.positiveGreen : AppColors.doctorSecondary).withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          (_videoFile != null || _videoBytes != null || _fileName != null) ? Icons.check_circle_outline_rounded : Iconsax.video_add,
                          color: (_videoFile != null || _videoBytes != null || _fileName != null) ? AppColors.positiveGreen : AppColors.doctorSecondary,
                          size: 46,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _fileName != null
                              ? _fileName!
                              : 'Tap to select video file (.mp4, .mov, .avi)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: _fileName != null ? FontWeight.bold : FontWeight.normal,
                            color: _fileName != null ? AppColors.textPrimary : AppColors.textSecondary,
                          ),
                        ),
                        if (_videoFile == null && _videoBytes == null) ...[
                          const SizedBox(height: 4),
                          const Text(
                            'Supported formats: MP4, MOV, AVI',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _isUploading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.cloud_upload_outlined, size: 22),
                  label: _isUploading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Upload Therapy Video',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.doctorPrimary,
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _isUploading
                      ? null
                      : () {
                          if (_videoFile == null && _videoBytes == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please select a video file first'),
                                backgroundColor: AppColors.negativeRed,
                              ),
                            );
                            return;
                          }
                          uploadFile();
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
