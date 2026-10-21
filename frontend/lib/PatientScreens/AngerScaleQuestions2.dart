import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:ira/theme/app_theme.dart';
import 'ScorePage2.dart';

class AngerQuestions2 extends StatefulWidget {
  final String email;
  const AngerQuestions2({Key? key, required this.email}) : super(key: key);

  @override
  State<AngerQuestions2> createState() => _AngerQuestions2State();
}

class _AngerQuestions2State extends State<AngerQuestions2> {
  int currentIndex = 0;
  int score = 0;

  void navigateToScorePage() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ScorePage2(Score: score, email: widget.email),
      ),
    );
  }

  final List<List<String>> questions = [
    ['Question 1', ' I do not feel angry', 'I feel angry', 'I am angry most of the time now.', "I am so angry  all the time that I can't stand it."],
    ['Question 2', 'I am not particularly angry about my future.', 'When I think about my future, I feel angry', ' I feel angry about what I have to look forward to.', 'I feel intensely angry about my future, since it cannot be improved.'],
    ['Question 3', 'It makes me angry that I feel like such a failure.', 'It makes me angry that I have failed more than the average person.', 'As I look back on my life, I feel angry about my failures', "I am so angry and hostile all the time that I can't stand it."],
    ['Question 4', 'I am not all that angry about things.', ' I am becoming more hostile about things than I used to be', 'I am pretty angry about things these days', 'I am angry and hostile about everything.'],
    ['Question 5', "I don't feel particularly hostile at others.", 'I feel hostile a good deal of the time.', 'I feel quite hostile most of the time.', 'I feel hostile all of the time.'],
    ['Question 6', "I don't feel that others are trying to annoy me.", 'At times I think people are trying to annoy me.', 'More people than usual are beginning to make me feel angry.', 'I feel that others are constantly and intentionally making me angry.'],
    ['Question 7', "I don't feel angry when I think about myself.", 'I feel more angry about myself these days than I used to', 'I feel angry about myself a good deal of the time.', 'When I think about myself, I feel intense anger.'],
    ['Question 8', "I don't have angry feelings about others having screwed up my life.", "It's beginning to make me angry that others are screwing up my life.", 'I feel angry that others prevent me from having a good life.', 'I am constantly angry because others have made my life totally miserable'],
    ['Question 9', "I don't feel angry enough to hurt someone.", 'Sometimes I am so angry that I feel like hurting others, but I would not really do it.', 'My anger is so intense that I sometimes feel like hurting others.', "I'm so angry that I would like to hurt someone."],
    ['Question 10', "I don't shout at people any more than usual.", 'I shout at others more now than I used to.', 'I shout at people all the time now.', "I shout at others so often that sometimes I just can't stop"],
    ['Question 11', 'Things are not more irritating to me now than usual.', 'I feel slightly more irritated now than usual.', 'I feel irritated a good deal of the time.', "I'm irritated all the time now."],
    ['Question 12', 'My anger does not interfere with my interest in other people', 'My anger sometimes interferes with my interest in others.', "I am becoming so angry that I don't want to be around others.", "I'm so angry that I can't stand being around people."],
    ['Question 13', "I don't have any persistent angry feelings that influence my ability to make decisions.", "My feelings of anger occasionally undermine my ability to make decisions.", "I am angry to the extent that it interferes with my making good decisions.", "I'm so angry that I can't make good decisions anymore"],
    ['Question 14', "I'm not so angry and hostile that others dislike me.", 'People sometimes dislike being around me since I become angry.', "More often than not, people stay away from me because I'm so hostile and angry.", "People don't like me anymore because I'm constantly angry all the time"],
    ['Question 15', 'My feelings of anger do not interfere with my work.', 'From time to time my feelings of anger interfere with my work.', 'I feel so angry that it interferes with my capacity to work.', 'My feelings of anger prevent me from doing any work at all.'],
    ['Question 16', 'My anger does not interfere with my sleep.', "Sometimes I don't sleep very well because I'm feeling angry.", "My anger is so great that I stay awake 1—2 hours later than usual.", "I am so intensely angry that I can't get much sleep during the night."],
    ['Question 17', ' My anger does not make me feel anymore tired than usual. ', ' My feelings of anger are beginning to tire me out.', 'y anger is intense enough that it makes me feel very tired. ', ' My feelings of anger leave me too tired to do anything.'],
    ['Question 18', 'My appetite does not suffer because of my feelings of anger. ', 'My feelings of anger are beginning to affect my appetite.', 'My feelings of anger leave me without much of an appetite. ', 'My anger is so intense that it has taken away my appetite.'],
    ['Question 19', "My feelings of anger don't interfere with my health.", 'My feelings of anger are beginning to interfere with my health.', 'My anger prevents me from devoting much time and attention to my health. ', " I'm so angry at everything these days that I pay no attention to my health and well-being."],
    ['Question 20', 'My ability to think clearly is unaffected by my feelings of anger. ', " Sometimes my feelings of anger prevent me from thinking in a clear-headed way", 'My anger makes it hard for me to think of anything else. ', "I'm so intensely angry and hostile that it completely interferes with my thinking."],
    ['Question 21', "I don't feel so angry that it interferes with my interest in sex. ", 'My feelings of anger leave me less interested in sex than I used to be. ', 'My current feelings of anger undermine my interest in sex. ', "I'm so angry about my life that I've completely lost interest in sex"],
  ];

  @override
  Widget build(BuildContext context) {
    final double progress = (currentIndex + 1) / questions.length;

    return Scaffold(
      backgroundColor: AppColors.patientBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Post-Therapy Anger Scale',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Progress Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${currentIndex + 1} of ${questions.length}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.positiveGreen,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}% completed',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.borderSubtle,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.positiveGreen),
                ),
              ),

              const SizedBox(height: 24),

              // Question Guidance
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.positiveGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.positiveGreen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.assignment_turned_in_outlined, color: AppColors.positiveGreen, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Select the option that reflects how you feel now after completing therapy:',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Options List
              if (currentIndex < questions.length)
                Expanded(
                  child: ListView.separated(
                    itemCount: questions[currentIndex].length - 1,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, optionIndex) {
                      final optionLabel = String.fromCharCode(65 + optionIndex);
                      final optionText = questions[currentIndex][optionIndex + 1].trim();

                      return FadeInUp(
                        duration: const Duration(milliseconds: 300),
                        delay: Duration(milliseconds: optionIndex * 60),
                        child: Container(
                          decoration: AppStyles.cardDecoration(
                            backgroundColor: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                setState(() {
                                  score += optionIndex;
                                  currentIndex++;
                                  if (currentIndex == questions.length) {
                                    navigateToScorePage();
                                  }
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: AppColors.patientBackground,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.borderSubtle),
                                      ),
                                      child: Center(
                                        child: Text(
                                          optionLabel,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.positiveGreen,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        optionText,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.textPrimary,
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      Icons.chevron_right_rounded,
                                      color: AppColors.textMuted,
                                      size: 20,
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
                ),
            ],
          ),
        ),
      ),
    );
  }
}