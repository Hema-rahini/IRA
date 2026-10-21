import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';
import 'DrawGame.dart';
import 'TouchPoints.dart';

class Fruit extends FlameGame {}

class GameScreenHome extends StatefulWidget {
  final String email;
  const GameScreenHome({Key? key, required this.email}) : super(key: key);

  @override
  State<GameScreenHome> createState() => _GameScreenHomeState();
}

class _GameScreenHomeState extends State<GameScreenHome> {
  final Uri _fruitNinjaUrl =
      Uri.parse('https://babakcode.github.io/flutter_fruit_ninja/');
  final Uri _bubbleSortUrl =
      Uri.parse('https://games-site.github.io/projects/ball-sort-puzzle/index.html');
  final Uri _crushGlassUrl =
      Uri.parse('https://www.friv.com/z/games/breaktheglass/game.html');

  Future<void> _launchExternalUrl(Uri url, String gameName) async {
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $gameName. Please try again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to launch $gameName.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  final List<Map<String, dynamic>> _gameList = [
    {
      'title': 'Scribble Art Therapy',
      'subtitle': 'Freeform canvas to express your feelings and de-stress with colors',
      'tag': 'Creative Canvas',
      'icon': Icons.brush_rounded,
      'gradient': [Color(0xFF5B8C7A), Color(0xFF7FA898)],
    },
    {
      'title': 'Bubble Sort Puzzle',
      'subtitle': 'Calming color organization puzzle to quiet a racing mind',
      'tag': 'Logic & Focus',
      'icon': Icons.bubble_chart_rounded,
      'gradient': [Color(0xFF4A90E2), Color(0xFF67B26F)],
    },
    {
      'title': 'Touch Points Reflex',
      'subtitle': 'Sensory tap coordination game to train mindful focus & reflexes',
      'tag': 'Reflex & Focus',
      'icon': Icons.touch_app_rounded,
      'gradient': [Color(0xFF8E79B2), Color(0xFFA899CC)],
    },
    {
      'title': 'Fruit Ninja Slice',
      'subtitle': 'Fast-paced action to channel energy and divert frustration',
      'tag': 'Active Distraction',
      'icon': Icons.sports_kabaddi_rounded,
      'gradient': [Color(0xFFE67E22), Color(0xFFF39C12)],
    },
    {
      'title': 'Crush Glass Release',
      'subtitle': 'Instant tactile tension release through satisfying shattering',
      'tag': 'Tension Relief',
      'icon': Icons.auto_awesome_rounded,
      'gradient': [Color(0xFFC0392B), Color(0xFFE74C3C)],
    },
  ];

  void _navigateToGame(int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DrawGame()),
        );
        break;
      case 1:
        _launchExternalUrl(_bubbleSortUrl, 'Bubble Sort');
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TouchPoints()),
        );
        break;
      case 3:
        _launchExternalUrl(_fruitNinjaUrl, 'Fruit Ninja');
        break;
      case 4:
        _launchExternalUrl(_crushGlassUrl, 'Crush Glass');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Therapeutic Games',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // Intro banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.patientPrimary.withOpacity(0.12),
                    AppColors.patientSecondary.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.patientPrimary.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.patientPrimary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.videogame_asset_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mindful Stress Relief',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Engage in calming exercises and focused activities designed to regulate intense emotions.',
                          style: TextStyle(
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
            ),

            const SizedBox(height: 20),

            // Game Cards List
            ...List.generate(_gameList.length, (index) {
              final game = _gameList[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _navigateToGame(index),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.patientSurface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Gradient icon box
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: game['gradient'] as List<Color>,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: (game['gradient'] as List<Color>)[0].withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              game['icon'] as IconData,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        game['title'] as String,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: (game['gradient'] as List<Color>)[0].withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        game['tag'] as String,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: (game['gradient'] as List<Color>)[0],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  game['subtitle'] as String,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
