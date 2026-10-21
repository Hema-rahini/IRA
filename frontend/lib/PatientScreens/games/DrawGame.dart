import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class DrawGame extends StatefulWidget {
  const DrawGame({Key? key}) : super(key: key);

  @override
  State<DrawGame> createState() => _DrawGameState();
}

class DrawnLine {
  final List<Offset> path;
  final Color color;
  final double width;
  final bool isEraser;

  DrawnLine({
    required this.path,
    required this.color,
    required this.width,
    this.isEraser = false,
  });
}

class _DrawGameState extends State<DrawGame> {
  // Stroke history
  final List<DrawnLine> _lines = [];
  final List<DrawnLine> _undoneLines = [];
  DrawnLine? _currentLine;

  // Brush settings
  Color _selectedColor = const Color(0xFF2D3748);
  double _strokeWidth = 6.0;
  bool _isEraser = false;
  Color _canvasBackgroundColor = Colors.white;

  final List<Color> _colors = const [
    Color(0xFF2D3748), // Charcoal
    Color(0xFF5B8C7A), // Sage
    Color(0xFF3B82F6), // Ocean Blue
    Color(0xFF8E79B2), // Lavender
    Color(0xFFE56A55), // Coral
    Color(0xFFF59E0B), // Warm Amber
    Color(0xFF10B981), // Emerald
    Color(0xFFEC4899), // Rose Pink
    Color(0xFF9333EA), // Purple
  ];

  final List<double> _brushSizes = const [3.0, 7.0, 14.0, 24.0];

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _undoneLines.add(_lines.removeLast());
      });
    }
  }

  void _redo() {
    if (_undoneLines.isNotEmpty) {
      setState(() {
        _lines.add(_undoneLines.removeLast());
      });
    }
  }

  void _clearCanvas() {
    if (_lines.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Text('Reset Canvas', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
          ],
        ),
        content: const Text(
          'Do you want to clear your current scribbles and start with a fresh slate?',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _lines.clear();
                _undoneLines.clear();
                _currentLine = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Canvas cleared. Breathe out and start fresh!'),
                  backgroundColor: AppColors.patientPrimary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Clear', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _toggleCanvasTheme() {
    setState(() {
      if (_canvasBackgroundColor == Colors.white) {
        _canvasBackgroundColor = const Color(0xFF1E293B); // Dark slate
        if (_selectedColor == const Color(0xFF2D3748)) {
          _selectedColor = Colors.white;
        }
      } else {
        _canvasBackgroundColor = Colors.white;
        if (_selectedColor == Colors.white) {
          _selectedColor = const Color(0xFF2D3748);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkCanvas = _canvasBackgroundColor != Colors.white;

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
        title: const Column(
          children: [
            Text(
              'Scribble Therapy',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Express freely without judgment',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Theme Toggle
          IconButton(
            tooltip: isDarkCanvas ? 'Switch to Light Canvas' : 'Switch to Dark Canvas',
            icon: Icon(
              isDarkCanvas ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.patientPrimary,
              size: 22,
            ),
            onPressed: _toggleCanvasTheme,
          ),
          // Undo Button
          IconButton(
            tooltip: 'Undo',
            icon: Icon(
              Icons.undo_rounded,
              color: _lines.isNotEmpty ? AppColors.textPrimary : AppColors.divider,
              size: 22,
            ),
            onPressed: _lines.isNotEmpty ? _undo : null,
          ),
          // Redo Button
          IconButton(
            tooltip: 'Redo',
            icon: Icon(
              Icons.redo_rounded,
              color: _undoneLines.isNotEmpty ? AppColors.textPrimary : AppColors.divider,
              size: 22,
            ),
            onPressed: _undoneLines.isNotEmpty ? _redo : null,
          ),
          // Clear Canvas
          IconButton(
            tooltip: 'Clear Board',
            icon: Icon(
              Icons.delete_outline_rounded,
              color: _lines.isNotEmpty ? AppColors.error : AppColors.divider,
              size: 22,
            ),
            onPressed: _lines.isNotEmpty ? _clearCanvas : null,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Therapeutic prompt header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa_rounded, size: 14, color: AppColors.patientPrimary.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Release tension through raw gestures — no rules or expectations',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Drawing Canvas Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: _canvasBackgroundColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) {
                        setState(() {
                          final point = details.localPosition;
                          _lines.add(DrawnLine(
                            path: [point, Offset(point.dx + 0.1, point.dy + 0.1)],
                            color: _isEraser ? _canvasBackgroundColor : _selectedColor,
                            width: _isEraser ? _strokeWidth * 2.5 : _strokeWidth,
                            isEraser: _isEraser,
                          ));
                          _undoneLines.clear();
                        });
                      },
                      onPanStart: (details) {
                        setState(() {
                          _currentLine = DrawnLine(
                            path: [details.localPosition],
                            color: _isEraser ? _canvasBackgroundColor : _selectedColor,
                            width: _isEraser ? _strokeWidth * 2.5 : _strokeWidth,
                            isEraser: _isEraser,
                          );
                          _lines.add(_currentLine!);
                          _undoneLines.clear();
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _currentLine?.path.add(details.localPosition);
                        });
                      },
                      onPanEnd: (details) {
                        setState(() {
                          _currentLine = null;
                        });
                      },
                      child: CustomPaint(
                        painter: SketchPainter(_lines),
                        size: Size.infinite,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Floating Controls Bar
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.patientSurface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Brush / Eraser & Brush Size Selector & Stats
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.center,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(minWidth: constraints.maxWidth),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                      // Mode Selector (Brush vs Eraser)
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.patientBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            // Brush Tool
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isEraser = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: !_isEraser ? AppColors.patientPrimary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.brush_rounded,
                                      size: 16,
                                      color: !_isEraser ? Colors.white : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Pen',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: !_isEraser ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Eraser Tool
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isEraser = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isEraser ? const Color(0xFFE56A55) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.auto_fix_normal_rounded,
                                      size: 16,
                                      color: _isEraser ? Colors.white : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Eraser',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _isEraser ? Colors.white : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Stroke Width Size Pills
                      Row(
                        children: _brushSizes.map((size) {
                          final isSelected = _strokeWidth == size;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _strokeWidth = size;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.patientPrimary : AppColors.patientBackground,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.patientPrimary : AppColors.divider,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: size < 10 ? size + 2 : 12,
                                  height: size < 10 ? size + 2 : 12,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : AppColors.textSecondary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      // Stroke count badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.patientBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_lines.length} marks',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Row 2: Color Palette
                  SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _colors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final color = _colors[index];
                        final isSelected = !_isEraser && _selectedColor == color;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedColor = color;
                              _isEraser = false; // Selecting a color switches back to Pen mode
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: isSelected ? 40 : 34,
                            height: isSelected ? 40 : 34,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                            child: isSelected
                                ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SketchPainter extends CustomPainter {
  final List<DrawnLine> lines;

  SketchPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      if (line.path.isEmpty) continue;

      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..strokeWidth = line.width;

      if (line.path.length == 1) {
        // Draw discrete touch point / dot
        canvas.drawCircle(line.path.first, line.width / 2, paint..style = PaintingStyle.fill);
      } else {
        final path = Path();
        path.moveTo(line.path[0].dx, line.path[0].dy);

        // Render smooth continuous line path
        for (int i = 1; i < line.path.length; i++) {
          path.lineTo(line.path[i].dx, line.path[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) {
    return true;
  }
}
