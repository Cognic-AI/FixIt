import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  int currentStep = 0;
  List<String> likedOptions = [];
  List<String> improvementOptions = [];
  String rating = '';
  String comments = '';

  final List<String> likedChoices = [
    'FAST TO USE',
    'COMPLETE',
    'EASY TO NAVIGATE',
    'GREAT DESIGN',
    'HELPFUL FEATURES',
    'RELIABLE'
  ];

  final List<String> improvementChoices = [
    'GOOD BUT NEED MORE COMPONENTS',
    'SLOW LOADING',
    'CONFUSING NAVIGATION',
    'MISSING FEATURES',
    'POOR MOBILE EXPERIENCE',
    'NEEDS BETTER SEARCH'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
      ),
      body: Stepper(
        currentStep: currentStep,
        onStepContinue: () {
          if (currentStep < 2) {
            setState(() {
              currentStep++;
            });
          } else {
            // Submit feedback
          }
        },
        onStepCancel: () {
          if (currentStep > 0) {
            setState(() {
              currentStep--;
            });
          }
        },
        steps: [
          Step(
            title: const Text('What did you like?'),
            content: Column(
              children: likedChoices.map((choice) {
                return CheckboxListTile(
                  title: Text(choice),
                  value: likedOptions.contains(choice),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        likedOptions.add(choice);
                      } else {
                        likedOptions.remove(choice);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Step(
            title: const Text('What can be improved?'),
            content: Column(
              children: improvementChoices.map((choice) {
                return CheckboxListTile(
                  title: Text(choice),
                  value: improvementOptions.contains(choice),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        improvementOptions.add(choice);
                      } else {
                        improvementOptions.remove(choice);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Step(
            title: const Text('Additional Comments'),
            content: TextField(
              onChanged: (value) {
                setState(() {
                  comments = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Enter your comments here',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
