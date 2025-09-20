import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/feedback_service.dart';
import '../widgets/accessibility_widgets.dart';
import '../widgets/error_boundary.dart';

class FeedbackScreen extends StatefulWidget {
  static const route = '/feedback';
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _ctrl = TextEditingController();
  int? _rating;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context)!;
    return ErrorBoundary(
      context: 'FeedbackScreen',
      onRetry: () {
        // Retry functionality
      },
      child: Scaffold(
        appBar: AppBar(title: AccessibleText(s.feedback)),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _ctrl,
                minLines: 3,
                maxLines: 6,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(), hintText: 'How can we improve NDIS Connect?'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                  initialValue: _rating,
                  items: List.generate(5, (i) => i + 1)
                      .map((e) => DropdownMenuItem(value: e, child: AccessibleText('Rating: $e')))
                      .toList(),
                  onChanged: (v) => setState(() => _rating = v),
                  decoration: const InputDecoration(labelText: 'Rating (1-5)')),
              const Spacer(),
              FilledButton.icon(
                icon: const Icon(Icons.send),
                label: AccessibleText(s.feedback),
                onPressed: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anon';
                  await FeedbackService().submitFeedback(uid, _ctrl.text, rating: _rating);
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
