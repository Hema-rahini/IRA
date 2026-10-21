import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';
import 'DairyPage.dart';
import 'DoctorConsultationPage.dart';
import 'InsightsPage.dart';
import 'TrackActivity.dart';

class PatientNotificationsPage extends StatefulWidget {
  final String email;
  const PatientNotificationsPage({Key? key, required this.email}) : super(key: key);

  @override
  State<PatientNotificationsPage> createState() => _PatientNotificationsPageState();
}

class _PatientNotificationsPageState extends State<PatientNotificationsPage> {
  String _selectedStatus = 'Unread'; // 'Unread', 'Read', 'All'
  String _selectedCategory = 'All';
  bool _isLoading = true;

  bool _dailyTherapyReminders = true;
  bool _clinicianGuidanceAlerts = true;

  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await http.post(
        Uri.parse(api.ip + '/get_patient_notifications'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({"email": widget.email}),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> list = data['notifications'] ?? [];

        final mapped = list.map<Map<String, dynamic>>((item) {
          final String cat = item['category']?.toString() ?? 'Therapy';
          final String priority = item['priority']?.toString().toLowerCase() ?? 'normal';
          final String actionType = item['action_type']?.toString().toLowerCase() ?? 'none';
          final String createdAt = item['created_at']?.toString() ?? '';

          Color color = AppColors.patientPrimary;
          IconData icon = Icons.notifications_active_outlined;

          if (priority == 'critical' || priority == 'severe') {
            color = const Color(0xFFE11D48);
            icon = Icons.warning_amber_rounded;
          } else if (cat == 'Clinician') {
            color = const Color(0xFFE11D48);
            icon = Icons.support_agent_rounded;
          } else if (cat == 'Mindfulness') {
            color = AppColors.patientSecondary;
            icon = Icons.auto_stories_rounded;
          } else if (cat == 'Milestones') {
            color = const Color(0xFF6366F1);
            icon = Icons.insights_rounded;
          } else {
            color = AppColors.patientPrimary;
            icon = Icons.self_improvement_rounded;
          }

          String actionLabel = 'View Details';
          VoidCallback action = () {};

          if (actionType == 'consult_clinic' || cat == 'Clinician') {
            actionLabel = 'Consult Clinic';
            action = () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DoctorConsultationPage()),
              );
            };
          } else if (actionType == 'start_session' || cat == 'Therapy') {
            actionLabel = 'Start Session';
            action = () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TrackActivity(email: widget.email)),
              );
            };
          } else if (actionType == 'write_diary' || cat == 'Mindfulness') {
            actionLabel = 'Write Diary';
            action = () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DairyPage(email: widget.email)),
              );
            };
          } else if (actionType == 'view_analytics' || cat == 'Milestones') {
            actionLabel = 'View Analytics';
            action = () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Insights(email: widget.email)),
              );
            };
          }

          return {
            'id': item['id']?.toString() ?? '0',
            'category': cat,
            'title': item['title'] ?? 'Notice',
            'message': item['message'] ?? '',
            'time': createdAt.isNotEmpty ? createdAt.split(' ').first : 'Just now',
            'icon': icon,
            'color': color,
            'isRead': item['is_read'] == true,
            'priority': priority,
            'actionLabel': actionLabel,
            'action': action,
          };
        }).toList();

        if (mounted) {
          setState(() {
            _notifications = mapped;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAllAsRead() async {
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.history_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('All notifications moved to Read History.')),
          ],
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.patientPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    try {
      await http.post(
        Uri.parse(api.ip + '/mark_notification_read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": widget.email}),
      );
    } catch (_) {}
  }

  void _markSingleAsRead(Map<String, dynamic> item, {bool showFeedback = true}) async {
    setState(() {
      item['isRead'] = true;
    });

    if (showFeedback) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(child: Text('Notice archived to permanent Read History.')),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.patientPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    try {
      await http.post(
        Uri.parse(api.ip + '/mark_notification_read'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"id": int.tryParse(item['id'])}),
      );
    } catch (_) {}
  }

  int get _unreadCount => _notifications.where((n) => n['isRead'] == false).length;
  int get _readCount => _notifications.where((n) => n['isRead'] == true).length;

  List<Map<String, dynamic>> get _filteredNotifications {
    List<Map<String, dynamic>> list = _notifications;

    // 1. Filter by Read / Unread Status
    if (_selectedStatus == 'Unread') {
      list = list.where((n) => n['isRead'] == false).toList();
    } else if (_selectedStatus == 'Read') {
      list = list.where((n) => n['isRead'] == true).toList();
    }

    // 2. Filter by Category
    if (_selectedCategory != 'All') {
      list = list.where((n) => n['category'] == _selectedCategory).toList();
    }

    return list;
  }

  Widget _buildStatusTab({
    required String id,
    required String label,
    required int count,
    required IconData icon,
    required Color badgeColor,
  }) {
    final bool isSelected = _selectedStatus == id;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatus = id;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.patientPrimary : AppColors.textMuted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? badgeColor.withValues(alpha: 0.12)
                      : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? badgeColor : AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications & Alerts',
              style: TextStyle(
                fontSize: 19.0,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              _unreadCount > 0 ? '$_unreadCount unread • $_readCount in history' : 'All caught up • $_readCount in history',
              style: const TextStyle(
                fontSize: 12.0,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 16, color: AppColors.patientPrimary),
              label: const Text(
                'Mark read',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.patientPrimary),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.patientPrimary))
          : RefreshIndicator(
              onRefresh: fetchNotifications,
              color: AppColors.patientPrimary,
              child: SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Status Segregation Tabs (Unread vs Read History vs All)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: [
                            _buildStatusTab(
                              id: 'Unread',
                              label: 'Unread',
                              count: _unreadCount,
                              icon: Icons.mark_email_unread_rounded,
                              badgeColor: const Color(0xFFE11D48),
                            ),
                            _buildStatusTab(
                              id: 'Read',
                              label: 'Read History',
                              count: _readCount,
                              icon: Icons.history_rounded,
                              badgeColor: AppColors.patientPrimary,
                            ),
                            _buildStatusTab(
                              id: 'All',
                              label: 'All',
                              count: _notifications.length,
                              icon: Icons.all_inbox_rounded,
                              badgeColor: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // 2. Category Filter Pills
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('All'),
                            _buildFilterChip('Therapy'),
                            _buildFilterChip('Clinician'),
                            _buildFilterChip('Mindfulness'),
                            _buildFilterChip('Milestones'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3. Informational Banner for Read History
                      if (_selectedStatus == 'Read')
                        FadeIn(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.7)),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.inventory_2_outlined, color: Color(0xFF16A34A), size: 18),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Permanent History: All your completed session notices and clinical recommendations are archived here permanently.',
                                    style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D), fontWeight: FontWeight.w500, height: 1.35),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // 4. Notification Cards List
                      if (_filteredNotifications.isEmpty)
                        FadeInUp(
                          duration: const Duration(milliseconds: 350),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: AppColors.borderSubtle),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: (_selectedStatus == 'Read' ? AppColors.patientSecondary : AppColors.patientPrimary).withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _selectedStatus == 'Read' ? Icons.history_edu_rounded : Icons.notifications_paused_outlined,
                                    size: 38,
                                    color: _selectedStatus == 'Read' ? AppColors.patientSecondary : AppColors.patientPrimary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  _selectedStatus == 'Read'
                                      ? 'No Read History Yet'
                                      : (_selectedStatus == 'Unread' ? 'No Unread Notifications' : 'No Notifications'),
                                  style: const TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _selectedStatus == 'Read'
                                      ? 'Notices are permanently preserved here once you mark them as read.'
                                      : 'You are all caught up! All your previous notices are safely archived in Read History.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
                                ),
                                const SizedBox(height: 16),
                                if (_selectedStatus == 'Unread' && _readCount > 0)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.patientPrimary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      elevation: 0,
                                    ),
                                    icon: const Icon(Icons.history_rounded, size: 16),
                                    label: Text('View Read History ($_readCount)', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                    onPressed: () {
                                      setState(() {
                                        _selectedStatus = 'Read';
                                      });
                                    },
                                  )
                                else if (_selectedCategory != 'All')
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.patientPrimary,
                                      side: const BorderSide(color: AppColors.patientPrimary),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedCategory = 'All';
                                      });
                                    },
                                    child: const Text('Show All Categories'),
                                  ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredNotifications.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = _filteredNotifications[index];
                            final bool isRead = item['isRead'];
                            final Color color = item['color'];

                            return FadeInUp(
                              duration: const Duration(milliseconds: 350),
                              delay: Duration(milliseconds: index * 60),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isRead ? AppColors.borderSubtle : color.withValues(alpha: 0.35),
                                    width: isRead ? 1.0 : 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isRead ? 0.02 : 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () {
                                      if (!isRead) {
                                        _markSingleAsRead(item, showFeedback: false);
                                      }
                                      item['action']();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Icon(item['icon'], color: color, size: 22),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            item['title'],
                                                            style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                                                              color: AppColors.textPrimary,
                                                            ),
                                                          ),
                                                        ),
                                                        Row(
                                                          children: [
                                                            Text(
                                                              item['time'],
                                                              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                            ),
                                                            if (!isRead) ...[
                                                              const SizedBox(width: 6),
                                                              Container(
                                                                width: 7,
                                                                height: 7,
                                                                decoration: BoxDecoration(
                                                                  color: color,
                                                                  shape: BoxShape.circle,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      item['message'],
                                                      style: const TextStyle(
                                                        fontSize: 12.5,
                                                        color: AppColors.textSecondary,
                                                        height: 1.35,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 14),
                                          Wrap(
                                            alignment: WrapAlignment.spaceBetween,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: color.withValues(alpha: 0.08),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  item['category'].toUpperCase(),
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: color,
                                                    letterSpacing: 0.8,
                                                  ),
                                                ),
                                              ),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 6,
                                                crossAxisAlignment: WrapCrossAlignment.center,
                                                children: [
                                                  if (!isRead)
                                                    TextButton.icon(
                                                      style: TextButton.styleFrom(
                                                        foregroundColor: AppColors.textSecondary,
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                        minimumSize: const Size(0, 30),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(10),
                                                          side: const BorderSide(color: AppColors.borderSubtle),
                                                        ),
                                                      ),
                                                      icon: const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.patientPrimary),
                                                      label: const Text(
                                                        'Mark Read',
                                                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                                                      ),
                                                      onPressed: () => _markSingleAsRead(item),
                                                    )
                                                  else
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF1F5F9),
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: const [
                                                          Icon(Icons.done_all_rounded, size: 12, color: AppColors.textMuted),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            'In History',
                                                            style: TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  const SizedBox(width: 10),
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: color,
                                                      foregroundColor: Colors.white,
                                                      elevation: 0,
                                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                      minimumSize: const Size(0, 32),
                                                    ),
                                                    onPressed: () {
                                                      if (!isRead) {
                                                        _markSingleAsRead(item, showFeedback: false);
                                                      }
                                                      item['action']();
                                                    },
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          item['actionLabel'],
                                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                        ),
                                                        const SizedBox(width: 4),
                                                        const Icon(Icons.arrow_forward_rounded, size: 12),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

              const SizedBox(height: 28),

              // Notification Preferences Card
              FadeInUp(
                duration: const Duration(milliseconds: 500),
                delay: const Duration(milliseconds: 250),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Notification Preferences',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: _dailyTherapyReminders,
                            activeTrackColor: AppColors.patientPrimary,
                            onChanged: (val) {
                              setState(() {
                                _dailyTherapyReminders = val;
                              });
                            },
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.patientPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.alarm_rounded, color: AppColors.patientPrimary, size: 20),
                            ),
                            title: const Text('Daily Therapy Reminders', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                const Text('Remind me to complete daily video sessions', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _dailyTherapyReminders
                                        ? AppColors.patientPrimary.withValues(alpha: 0.12)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _dailyTherapyReminders ? '9:00 AM & 8:00 PM' : 'Muted',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _dailyTherapyReminders ? AppColors.patientPrimary : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1, indent: 60),
                          SwitchListTile(
                            value: _clinicianGuidanceAlerts,
                            activeTrackColor: AppColors.patientPrimary,
                            onChanged: (val) {
                              setState(() {
                                _clinicianGuidanceAlerts = val;
                              });
                            },
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.health_and_safety_outlined, color: Color(0xFFE11D48), size: 20),
                            ),
                            title: const Text('Clinical Feedback Alerts', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                const Text('Notify when your doctor reviews your assessments', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _clinicianGuidanceAlerts
                                        ? const Color(0xFFE11D48).withValues(alpha: 0.12)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _clinicianGuidanceAlerts ? 'Active' : 'Off',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: _clinicianGuidanceAlerts ? const Color(0xFFE11D48) : AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildFilterChip(String label) {
    final bool isSelected = _selectedCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.patientPrimary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.patientPrimary : AppColors.borderSubtle,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.patientPrimary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
