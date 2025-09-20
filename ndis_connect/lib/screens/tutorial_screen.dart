import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tts_service.dart';
import '../widgets/accessibility_widgets.dart';
import '../widgets/error_boundary.dart';

class TutorialScreen extends StatefulWidget {
  static const route = '/tutorial';
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _index = 0;
  final steps = const [
    'Welcome to NDIS Connect. This short guide will help you get started.',
    'Use the Dashboard to see your budget, tasks, and appointments.',
    'Tap the emergency button for crisis contacts.',
    'Use Settings to adjust text size and contrast.',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  Future<void> _speak() async {
    await context.read<TtsService>().speak(steps[_index]);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      context: 'TutorialScreen',
      onRetry: () {
        // Retry functionality
      },
      child: Scaffold(
        appBar: AppBar(title: const AccessibleText('Tutorial')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AccessibleText(
                'Step ${_index + 1}/${steps.length}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              AccessibleText(steps[_index], style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton(
                    onPressed: _index > 0
                        ? () => setState(() {
                              _index--;
                              _speak();
                            })
                        : null,
                    child: const AccessibleText('Back'),
                  ),
                  FilledButton(
                    onPressed: _index < steps.length - 1
                        ? () => setState(() {
                              _index++;
                              _speak();
                            })
                        : () => Navigator.pop(context),
                    child: AccessibleText(_index < steps.length - 1 ? 'Next' : 'Finish'),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
