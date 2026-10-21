import 'package:flutter/material.dart';
import 'package:ira/theme/app_theme.dart';
import '../utilsn.dart';
import 'PatientDetails.dart';

class SearchResults extends StatelessWidget {
  final List<Map<String, dynamic>> searchResults;

  const SearchResults({Key? key, required this.searchResults}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.doctorBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Search Results',
          style: TextStyle(
            color: AppColors.doctorPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.doctorPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: searchResults.isEmpty
          ? const Center(
              child: Text(
                'No patients found.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              itemCount: searchResults.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final patient = searchResults[index];
                final String name = patient['Name'] ?? 'Patient';
                final String email = patient['Email_ID'] ?? '';
                final String? profileImg = patient['ProfileImage'];

                return Container(
                  decoration: AppStyles.cardDecoration(
                    backgroundColor: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.doctorBackground,
                      backgroundImage: getSafeImageProvider(profileImg),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: AppColors.doctorSecondary,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PatientDetails(email: email),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
