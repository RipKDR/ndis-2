// Placeholder for NDIA/NDIS data integrations.
// Real endpoints would require NDIA-approved access and compliance.
import 'dart:async';

class NdisApiService {
  Future<Map<String, dynamic>> fetchPlanSummary(String uid) async {
    // TODO(dev): Replace with real secure API calls via Cloud Functions
    return Future.value({
      'budgets': {
        'core': 12000,
        'capacity': 8000,
        'capital': 5000,
      },
      'spent': {
        'core': 3500,
        'capacity': 900,
        'capital': 0,
      },
      'goals': [
        {'title': 'Community access', 'progress': 0.4},
        {'title': 'Physio sessions', 'progress': 0.2},
      ]
    });
  }
}
