import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:http/http.dart' as http;
import 'package:ira/theme/app_theme.dart';
import '../OnboardingScreens/authoptions.dart';
import '../urls.dart';
import '../utilsn.dart';
import 'PatientDetails.dart';

class DoctorHomepage extends StatefulWidget {
  const DoctorHomepage({Key? key}) : super(key: key);

  @override
  State<DoctorHomepage> createState() => _DoctorHomepageState();
}

class _DoctorHomepageState extends State<DoctorHomepage> {
  List<Map<String, dynamic>> patients = [];
  String selectedCategory = 'Teen';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPatients();
  }

  Future<void> fetchPatients() async {
    try {
      var response = await http.get(
        Uri.parse(api.ip + '/get_details_with_images'),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body)['details'];
        if (mounted) {
          setState(() {
            patients = List<Map<String, dynamic>>.from(data);
            _isLoading = false;
          });
        }
      } else {
        print('Failed to load patients: ${response.statusCode}');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
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
              'Patient Directory',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: AppColors.doctorPrimary,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              'Clinical Cohort Management',
              style: TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.doctorPrimary),
            tooltip: 'Refresh Patients',
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              fetchPatients();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.negativeRed),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: const Text('Doctor Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('Are you sure you want to log out of your clinician session?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.negativeRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthPage()),
                          (route) => false,
                        );
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: fetchPatients,
        color: AppColors.doctorPrimary,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16.0),
              _buildCategoryRow(),
              const SizedBox(height: 14.0),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: AppColors.doctorPrimary),
                      )
                    : _buildCardList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: AppStyles.cardDecoration(
        backgroundColor: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await showSearch(
              context: context,
              delegate: CustomSearchDelegate(patients),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: const [
                Icon(Icons.search_rounded, color: AppColors.doctorSecondary, size: 22),
                SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Search patients by name or email...',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 15.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryRow() {
    return Row(
      children: [
        _buildCategoryButton('Teen', Icons.school_outlined),
        const SizedBox(width: 10),
        _buildCategoryButton('Women', Icons.female_rounded),
        const SizedBox(width: 10),
        _buildCategoryButton('Men', Icons.male_rounded),
      ],
    );
  }

  Widget _buildCategoryButton(String category, IconData icon) {
    final bool isSelected = selectedCategory == category;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = category;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.doctorPrimary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.doctorPrimary : AppColors.borderSubtle,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.doctorPrimary.withValues(alpha: 0.2),
                      offset: const Offset(0, 4),
                      blurRadius: 10,
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardList() {
    List<Map<String, dynamic>> filteredPatients = [];

    // Filter patients based on the selected category
    if (selectedCategory == 'Teen') {
      filteredPatients = patients
          .where((patient) => patient['Age'] != null && patient['Age'] < 20)
          .toList();
    } else if (selectedCategory == 'Men') {
      filteredPatients = patients
          .where((patient) =>
              patient['Gender'] == 'Male' &&
              patient['Age'] != null &&
              patient['Age'] >= 20)
          .toList();
    } else if (selectedCategory == 'Women') {
      filteredPatients = patients
          .where((patient) =>
              patient['Gender'] == 'Female' &&
              patient['Age'] != null &&
              patient['Age'] >= 20)
          .toList();
    }

    if (filteredPatients.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_outlined, size: 54, color: AppColors.textMuted.withValues(alpha: 0.6)),
            const SizedBox(height: 12),
            Text(
              'No patients in $selectedCategory cohort',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Registered patients in this category will appear here.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 0.77,
      ),
      itemCount: filteredPatients.length,
      itemBuilder: (context, index) {
        final patient = filteredPatients[index];
        final String name = patient['Name'] ?? 'Patient';
        final String email = patient['Email_ID'] ?? '';
        final String? profileImg = patient['ProfileImage'];
        final dynamic age = patient['Age'];

        return FadeInUp(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: index * 40),
          child: Container(
            decoration: AppStyles.cardDecoration(
              backgroundColor: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientDetails(email: email),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.doctorSecondary.withValues(alpha: 0.3), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 34,
                          backgroundColor: AppColors.doctorBackground,
                          backgroundImage: getSafeImageProvider(profileImg),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11.0,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.doctorPrimary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          age != null ? 'Age: $age' : selectedCategory,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.doctorPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomSearchDelegate extends SearchDelegate<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> patients;

  CustomSearchDelegate(this.patients);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.doctorPrimary),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 16),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
      onPressed: () {
        close(context, <Map<String, dynamic>>[]);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(query, context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(query, context);
  }

  Widget _buildSearchResults(String query, BuildContext context) {
    final List<Map<String, dynamic>> results = patients
        .where((patient) =>
            (patient['Name'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
            (patient['Email_ID'] ?? '').toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (results.isEmpty) {
      return Container(
        color: AppColors.doctorBackground,
        child: const Center(
          child: Text(
            'No matching patients found.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.doctorBackground,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: results.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final patient = results[index];
          final String name = patient['Name'] ?? 'Patient';
          final String email = patient['Email_ID'] ?? '';
          final String? profileImg = patient['ProfileImage'];

          return Container(
            decoration: AppStyles.cardDecoration(
              backgroundColor: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              leading: CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.doctorBackground,
                backgroundImage: getSafeImageProvider(profileImg),
              ),
              title: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                email,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.0,
                ),
              ),
              trailing: const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.doctorSecondary,
                size: 16,
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
