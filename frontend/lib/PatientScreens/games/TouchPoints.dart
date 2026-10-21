import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TouchPoints extends StatefulWidget {
  const TouchPoints({Key? key}) : super(key: key);

  @override
  State<TouchPoints> createState() => _TouchPointsState();
}

class _TouchPointsState extends State<TouchPoints> {
  List<TapPoint> tapPoints = [];
  Timer? tapPointCreator;
  int totalTaps = 0;
  int accurateTaps = 0;

  // Tap Limit and Thresholds
  static const int minTaps = 5;
  int tapLimit = 15;
  final List<int> availableLimits = [10, 15, 20];
  bool _isCompleted = false;
  Size _playfieldSize = const Size(320, 420);

  @override
  void initState() {
    super.initState();
    startCreatingTapPoints();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showRulesDialog(context);
    });
  }

  @override
  void dispose() {
    tapPointCreator?.cancel();
    super.dispose();
  }

  void startCreatingTapPoints() {
    tapPointCreator?.cancel();
    tapPointCreator = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted || _isCompleted) {
        timer.cancel();
        return;
      }
      if (tapPoints.length < 20) {
        setState(() {
          final maxX = (_playfieldSize.width - 60).clamp(40.0, 360.0);
          final maxY = (_playfieldSize.height - 60).clamp(40.0, 520.0);
          final randomX = 30.0 + Random().nextDouble() * (maxX - 30.0);
          final randomY = 30.0 + Random().nextDouble() * (maxY - 30.0);

          final palette = [
            const Color(0xFF5B8C7A),
            const Color(0xFF7FA898),
            const Color(0xFF4A90E2),
            const Color(0xFF8E79B2),
            const Color(0xFFE56A55),
            const Color(0xFFF59E0B),
          ];
          final randomColor = palette[Random().nextInt(palette.length)];
          final randomSize = Random().nextDouble() * 26 + 28; // 28 to 54
          tapPoints.add(TapPoint(randomX, randomY, randomColor, randomSize));
        });
      }
    });
  }

  void onTapDown(Offset tapPosition) {
    if (_isCompleted) return;

    setState(() {
      totalTaps++;
      tapPoints.removeWhere((tapPoint) {
        final distance = sqrt(pow(tapPosition.dx - tapPoint.x, 2) +
            pow(tapPosition.dy - tapPoint.y, 2));
        if (distance < tapPoint.size / 2) {
          accurateTaps++;
          return true;
        }
        return false;
      });
    });

    // Check if target tap limit reached -> Automatically move to submit option
    if (totalTaps >= tapLimit) {
      _triggerAutoSubmit();
    }
  }

  void _triggerAutoSubmit() {
    _isCompleted = true;
    tapPointCreator?.cancel();

    // Subtle delay for the last tap visual to register
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) {
        _showSubmitCompletionDialog();
      }
    });
  }

  void _handleStopPressed() {
    if (_isCompleted) return;

    if (totalTaps < minTaps) {
      // Incomplete session warning
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.patientPrimary, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text('Minimum Taps Needed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
              ),
            ],
          ),
          content: Text(
            'A minimum of $minTaps taps is required to evaluate focus and submit your score.\n\nYou have completed $totalTaps tap${totalTaps == 1 ? '' : 's'}. Would you like to keep practicing or exit?',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(); // Exit game
              },
              child: const Text('Exit Game', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.patientPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.of(ctx).pop(), // Resume game
              child: const Text('Keep Practicing', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      // Met minimum taps: Stop immediately and show submit option
      _isCompleted = true;
      tapPointCreator?.cancel();
      _showSubmitCompletionDialog();
    }
  }

  void _restartGame() {
    setState(() {
      _isCompleted = false;
      tapPoints.clear();
      totalTaps = 0;
      accurateTaps = 0;
      startCreatingTapPoints();
    });
  }

  double calculateAccuracy() {
    if (totalTaps == 0) return 0;
    return (accurateTaps / totalTaps) * 100;
  }

  void _showSubmitCompletionDialog() {
    final accuracy = calculateAccuracy();
    final misses = (totalTaps - accurateTaps).clamp(0, totalTaps);

    String performanceTitle;
    String performanceSubtitle;
    Color performanceColor;

    if (accuracy >= 80) {
      performanceTitle = 'Exceptional Focus! 🎯';
      performanceSubtitle = 'Remarkable precision and mindful hand-eye coordination.';
      performanceColor = const Color(0xFF2E7D32);
    } else if (accuracy >= 60) {
      performanceTitle = 'Great Mindfulness! 🌿';
      performanceSubtitle = 'Calm control and steady attentiveness demonstrated.';
      performanceColor = AppColors.patientPrimary;
    } else if (accuracy >= 40) {
      performanceTitle = 'Good Concentration 💡';
      performanceSubtitle = 'Consistent effort in grounding your awareness.';
      performanceColor = const Color(0xFFE67E22);
    } else {
      performanceTitle = 'Mindful Effort 🌱';
      performanceSubtitle = 'Focus improves with every session. Great job showing up!';
      performanceColor = const Color(0xFF5B8C7A);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 10,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                // Top Celebration Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        performanceColor.withValues(alpha: 0.15),
                        performanceColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    accuracy >= 70 ? Icons.emoji_events_rounded : Icons.track_changes_rounded,
                    color: performanceColor,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 14),

                // Performance Heading
                Text(
                  performanceTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  performanceSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                // Stats Dashboard Grid
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.patientBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: Column(
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDialogStatCard(
                              label: 'Accuracy',
                              value: '${accuracy.toStringAsFixed(0)}%',
                              color: performanceColor,
                            ),
                            Container(height: 36, width: 1, color: AppColors.divider),
                            _buildDialogStatCard(
                              label: 'Hits',
                              value: '$accurateTaps',
                              color: AppColors.patientPrimary,
                            ),
                            Container(height: 36, width: 1, color: AppColors.divider),
                            _buildDialogStatCard(
                              label: 'Misses',
                              value: '$misses',
                              color: const Color(0xFFE56A55),
                            ),
                            Container(height: 36, width: 1, color: AppColors.divider),
                            _buildDialogStatCard(
                              label: 'Total Taps',
                              value: '$totalTaps',
                              color: AppColors.textPrimary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Therapeutic feedback note
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.patientPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.spa_rounded, color: AppColors.patientPrimary, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Grounding visual focus lowers emotional tension and impulse reactivity.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Submit & Done Primary Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'Submit & Finish',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      // Show confirmation feedback to the user
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: AppColors.patientPrimary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Focus session submitted with ${accuracy.toStringAsFixed(0)}% accuracy!',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      Navigator.of(context).pop(); // Exit back to games menu
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Play Again Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                    label: const Text(
                      'Play Again',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _restartGame();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildDialogStatCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  void showRulesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.patientPrimary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.touch_app_rounded,
                    color: AppColors.patientPrimary,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Focus & Tap Exercise',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '1. Mindfully tap floating bubbles as they appear.\n2. Tap limit is set to $tapLimit taps.\n3. Game will automatically submit when you reach the $tapLimit taps limit.\n4. You can also press "Stop" after $minTaps taps anytime to finish early.',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.patientPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Start Exercise', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final accuracy = calculateAccuracy();
    final progress = (totalTaps / tapLimit).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Touch Points Focus',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Rules',
            icon: const Icon(Icons.help_outline_rounded, color: AppColors.textSecondary),
            onPressed: () => showRulesDialog(context),
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh_rounded, color: AppColors.patientPrimary),
            onPressed: _restartGame,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Live Stats & Tap Limit Progress Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.patientSurface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Stats Metrics Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem('Hits', '$accurateTaps', AppColors.patientPrimary),
                        Container(height: 28, width: 1, color: AppColors.divider),
                        _buildStatItem('Taps', '$totalTaps / $tapLimit', AppColors.textPrimary),
                        Container(height: 28, width: 1, color: AppColors.divider),
                        _buildStatItem('Accuracy', '${accuracy.toStringAsFixed(0)}%', AppColors.patientAccent),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Progress Bar to Tap Limit
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppColors.divider.withValues(alpha: 0.4),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalTaps >= tapLimit ? AppColors.success : AppColors.patientPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Progress & Limit Description Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          totalTaps >= tapLimit
                              ? 'Goal reached! Submitting...'
                              : '${tapLimit - totalTaps} tap${(tapLimit - totalTaps) == 1 ? '' : 's'} to auto-submit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: totalTaps >= tapLimit ? AppColors.success : AppColors.textSecondary,
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              'Target: ',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                            // Quick Limit selector chips
                            ...availableLimits.map((limit) {
                              final isSelected = tapLimit == limit;
                              return GestureDetector(
                                onTap: () {
                                  if (totalTaps == 0) {
                                    setState(() {
                                      tapLimit = limit;
                                    });
                                  } else {
                                    // Confirm limit change
                                    setState(() {
                                      tapLimit = limit;
                                      if (totalTaps >= tapLimit) {
                                        _triggerAutoSubmit();
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.patientPrimary
                                        : AppColors.patientBackground,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? AppColors.patientPrimary : AppColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    '$limit',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Game Playfield Canvas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 80), // bottom space for floating buttons
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        _playfieldSize = Size(constraints.maxWidth, constraints.maxHeight);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (details) {
                            onTapDown(details.localPosition);
                          },
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: TapPointPainter(tapPoints),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Dual Control Floating Actions: Restart & Stop
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            // Restart Button
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _restartGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.patientPrimary,
                    elevation: 3,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                    side: const BorderSide(color: AppColors.divider, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Restart',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Stop Button (Validates minimum taps, or directly submits)
            Expanded(
              child: SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _handleStopPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE56A55),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFFE56A55).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.stop_circle_rounded, size: 20),
                  label: const Text(
                    'Stop',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class TapPoint {
  final double x;
  final double y;
  final Color color;
  final double size;

  TapPoint(this.x, this.y, this.color, this.size);
}

class TapPointPainter extends CustomPainter {
  final List<TapPoint> tapPoints;

  TapPointPainter(this.tapPoints);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint glowPaint = Paint()..style = PaintingStyle.fill;

    for (final tapPoint in tapPoints) {
      // Gentle subtle outer glow
      glowPaint.color = tapPoint.color.withValues(alpha: 0.22);
      canvas.drawCircle(
        Offset(tapPoint.x, tapPoint.y),
        (tapPoint.size / 2) + 5,
        glowPaint,
      );

      // Core circle
      paint.color = tapPoint.color;
      canvas.drawCircle(
        Offset(tapPoint.x, tapPoint.y),
        tapPoint.size / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
