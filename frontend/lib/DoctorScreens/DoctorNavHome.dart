import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:ira/theme/app_theme.dart';
import 'DoctorHomePage.dart';
import 'Upload page.dart';
import 'thirdtab.dart';
import 'thoughtsCheckingpage.dart';

class DhomePage extends StatefulWidget {
  final String email;
  const DhomePage({Key? key, required this.email}) : super(key: key);

  @override
  State<DhomePage> createState() => _DhomePageState();
}

class _DhomePageState extends State<DhomePage> {
  int _selectedIndex = 0;

  void _onTabChange(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const DoctorHomepage(),
      const ThoughtsList(),
      const UploadPage(),
      ThirdTab(email: widget.email),
    ];

    return Scaffold(
      backgroundColor: AppColors.doctorBackground,
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SafeArea(
          top: false,
          child: Container(
            height: 66,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(33),
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.doctorPrimary.withValues(alpha: 0.14),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDoctorNavItem(
                  index: 0,
                  icon: Icons.people_alt_rounded,
                ),
                _buildDoctorNavItem(
                  index: 1,
                  icon: Icons.psychology_rounded,
                ),
                _buildDoctorNavItem(
                  index: 2,
                  icon: Iconsax.video_add,
                ),
                _buildDoctorNavItem(
                  index: 3,
                  icon: Icons.manage_accounts_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorNavItem({
    required int index,
    required IconData icon,
  }) {
    final isSelected = _selectedIndex == index;
    const double iconSize = 24.0; // All icons strictly the same size

    return GestureDetector(
      onTap: () => _onTabChange(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 48,
        height: 46,
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [
                    AppColors.doctorPrimary,
                    Color(0xFF285686),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.doctorPrimary.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            icon,
            size: iconSize,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
