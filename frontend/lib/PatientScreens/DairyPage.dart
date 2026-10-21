import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:ira/theme/app_theme.dart';
import '../urls.dart';

class DairyPage extends StatefulWidget {
  final String email;
  const DairyPage({Key? key, required this.email}) : super(key: key);

  @override
  State<DairyPage> createState() => _DairyPageState();
}

class _DairyPageState extends State<DairyPage> {
  final TextEditingController _textEditingController = TextEditingController();
  bool _showShareButton = false;
  bool _isSharing = false;
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _pastThoughts = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    fetchPastThoughts();
  }

  Future<void> fetchPastThoughts() async {
    try {
      final response = await http.get(Uri.parse(api.ip + '/fetch_thoughts'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);

        // Filter thoughts belonging to the current user
        final userThoughts = data
            .where((item) =>
                item['Email_ID']?.toString().toLowerCase().trim() ==
                widget.email.toLowerCase().trim())
            .map((item) => Map<String, dynamic>.from(item))
            .toList();

        // Sort chronological descending (newest first)
        userThoughts.sort((a, b) {
          final timeA = a['received_time']?.toString() ?? '';
          final timeB = b['received_time']?.toString() ?? '';
          return timeB.compareTo(timeA);
        });

        if (mounted) {
          setState(() {
            _pastThoughts = userThoughts;
            _isLoadingHistory = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingHistory = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching thoughts history: $e');
      if (mounted) {
        setState(() {
          _isLoadingHistory = false;
        });
      }
    }
  }

  void shareThoughts() async {
    final text = _textEditingController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSharing = true;
    });

    try {
      final response = await http.post(
        Uri.parse(api.ip + '/insert_thoughts'),
        headers: {
          'content-type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          "Email_ID": widget.email,
          "thoughts": text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Optimistically insert to past history immediately
        final newEntry = {
          "Email_ID": widget.email,
          "thoughts": text,
          "Output": "POSITIVE",
          "received_time": DateTime.now().toIso8601String(),
        };

        setState(() {
          _pastThoughts.insert(0, newEntry);
          _textEditingController.clear();
          _showShareButton = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text('Your reflection was saved to your journal!')),
              ],
            ),
            backgroundColor: AppColors.positiveGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
          ),
        );

        // Re-sync with server
        fetchPastThoughts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share thoughts (${response.statusCode})'),
            backgroundColor: AppColors.negativeRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: $e'),
          backgroundColor: AppColors.negativeRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSharing = false;
        });
      }
    }
  }

  void _showNoteDetailModal(Map<String, dynamic> thought) {
    final content = thought['thoughts']?.toString() ?? '';
    final isNegative = thought['Output'] == 'NEGATIVE';
    final accentColor = isNegative ? const Color(0xFFE56A55) : AppColors.patientPrimary;
    String dateStr = 'Unknown Date';
    String timeStr = '';

    try {
      if (thought['received_time'] != null) {
        final dt = DateTime.parse(thought['received_time'].toString()).toLocal();
        dateStr = DateFormat('EEEE, MMMM d, y').format(dt);
        timeStr = DateFormat('hh:mm a').format(dt);
      }
    } catch (_) {
      dateStr = thought['received_time']?.toString() ?? '';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.auto_stories_rounded, color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (timeStr.isNotEmpty)
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isNegative ? 'Expressive' : 'Reflective',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.patientBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: SelectableText(
                content,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.55,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textPrimary,
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close Note', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Emotional Journal',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Express your feelings freely',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh History',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.patientPrimary),
            onPressed: () {
              setState(() => _isLoadingHistory = true);
              fetchPastThoughts();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchPastThoughts,
          color: AppColors.patientPrimary,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
            children: [
              // 1. Horizontal Date Picker Bar
              SizedBox(
                height: 68,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 14,
                  itemBuilder: (context, index) {
                    final date = DateTime.now().subtract(const Duration(days: 3)).add(Duration(days: index));
                    final dayName = DateFormat('E').format(date);
                    final dayNum = DateFormat('dd').format(date);
                    final isSelected = DateUtils.isSameDay(date, _selectedDate);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = date;
                        });
                      },
                      child: Container(
                        width: 54,
                        margin: const EdgeInsets.only(right: 10, top: 2, bottom: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.patientPrimary : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.patientPrimary : AppColors.borderSubtle,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.patientPrimary.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ]
                              : AppStyles.cardShadow,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              dayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              dayNum,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 2. Today's Reflection Composer Card
              Container(
                padding: const EdgeInsets.all(18.0),
                decoration: AppStyles.cardDecoration(
                  backgroundColor: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.edit_note_rounded, color: AppColors.patientPrimary, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Today's Reflection",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Write down situations that upset you, bodily sensations, or calming thoughts.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 20, color: AppColors.borderSubtle),
                    TextField(
                      controller: _textEditingController,
                      minLines: 4,
                      maxLines: 7,
                      textAlignVertical: TextAlignVertical.top,
                      onChanged: (text) {
                        setState(() {
                          _showShareButton = text.trim().isNotEmpty;
                        });
                      },
                      style: const TextStyle(
                        fontSize: 14.5,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Share your thoughts, what triggered your anger, or how you overcame it...',
                        hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    if (_showShareButton) ...[
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton.icon(
                          icon: _isSharing
                              ? const SizedBox.shrink()
                              : const Icon(Icons.send_rounded, size: 17),
                          label: _isSharing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Save to Journal & Share',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.patientPrimary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _isSharing ? null : shareThoughts,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Past History Notes Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: const [
                        Icon(Icons.history_rounded, color: AppColors.patientPrimary, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Past Reflections & History',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.patientPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_pastThoughts.length} ${_pastThoughts.length == 1 ? 'entry' : 'entries'}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.patientPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 4. Past History Notes List
              if (_isLoadingHistory)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: CircularProgressIndicator(color: AppColors.patientPrimary),
                  ),
                )
              else if (_pastThoughts.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.patientPrimary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_stories_outlined,
                          color: AppColors.patientPrimary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No past reflections yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Write down and save your first thought above to start building your emotional history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _pastThoughts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final thought = _pastThoughts[index];
                    final content = thought['thoughts']?.toString() ?? '';
                    final isNegative = thought['Output'] == 'NEGATIVE';
                    final accentColor = isNegative ? const Color(0xFFE56A55) : AppColors.patientPrimary;
                    String formattedDate = '';
                    String formattedTime = '';

                    try {
                      if (thought['received_time'] != null) {
                        final dt = DateTime.parse(thought['received_time'].toString()).toLocal();
                        formattedDate = DateFormat('MMM d, y').format(dt);
                        formattedTime = DateFormat('hh:mm a').format(dt);
                      }
                    } catch (_) {
                      formattedDate = thought['received_time']?.toString() ?? '';
                    }

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showNoteDetailModal(thought),
                        borderRadius: BorderRadius.circular(18),
                        child: Container(
                          decoration: AppStyles.cardDecoration(
                            backgroundColor: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Left Sentiment Accent Bar
                                  Container(
                                    width: 5,
                                    color: accentColor,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Date, Time & Tag Header
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today_rounded,
                                                      size: 13,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Expanded(
                                                      child: Text(
                                                        '$formattedDate ${formattedTime.isNotEmpty ? '• ' + formattedTime : ''}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          color: AppColors.textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: accentColor.withValues(alpha: 0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isNegative ? 'Expressive' : 'Reflective',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: accentColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),

                                          // Thought Content preview
                                          Text(
                                            content,
                                            maxLines: 3,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: AppColors.textPrimary,
                                              height: 1.45,
                                            ),
                                          ),
                                          const SizedBox(height: 8),

                                          // Read Full Note hint
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              Text(
                                                'View note',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.patientPrimary,
                                                ),
                                              ),
                                              const SizedBox(width: 2),
                                              const Icon(
                                                Icons.chevron_right_rounded,
                                                size: 14,
                                                color: AppColors.patientPrimary,
                                              ),
                                            ],
                                          ),
                                        ],
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
                ),

              // 5. Generous bottom clearance padding for floating navigation dock
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }
}
