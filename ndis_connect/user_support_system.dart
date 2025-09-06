import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// User Support and Feedback Management System for NDIS Connect
///
/// This system handles user support requests, feedback collection,
/// and community management for the post-launch phase.
class UserSupportSystem {
  static final UserSupportSystem _instance = UserSupportSystem._internal();
  factory UserSupportSystem() => _instance;
  UserSupportSystem._internal();

  final List<SupportTicket> _tickets = [];
  final List<UserFeedback> _feedback = [];
  final List<CommunityPost> _communityPosts = [];
  final Map<String, SupportAgent> _agents = {};
  final StreamController<SupportEvent> _eventController = StreamController.broadcast();

  /// Initialize the support system
  Future<void> initialize() async {
    print('🎧 Initializing User Support System...');

    // Initialize support agents
    await _initializeSupportAgents();

    // Load existing tickets and feedback
    await _loadExistingData();

    // Start support monitoring
    await _startSupportMonitoring();

    print('✅ User Support System initialized');
  }

  /// Initialize support agents
  Future<void> _initializeSupportAgents() async {
    _agents['agent1'] = SupportAgent(
      id: 'agent1',
      name: 'Sarah Johnson',
      email: 'sarah@ndisconnect.com.au',
      role: 'Level 1 Support',
      specialties: ['general_support', 'accessibility', 'user_onboarding'],
      isAvailable: true,
    );

    _agents['agent2'] = SupportAgent(
      id: 'agent2',
      name: 'Michael Chen',
      email: 'michael@ndisconnect.com.au',
      role: 'Level 2 Technical Support',
      specialties: ['technical_issues', 'performance', 'integration'],
      isAvailable: true,
    );

    _agents['agent3'] = SupportAgent(
      id: 'agent3',
      name: 'Emma Wilson',
      email: 'emma@ndisconnect.com.au',
      role: 'Accessibility Specialist',
      specialties: ['accessibility', 'screen_reader', 'voice_navigation'],
      isAvailable: true,
    );

    _agents['agent4'] = SupportAgent(
      id: 'agent4',
      name: 'David Thompson',
      email: 'david@ndisconnect.com.au',
      role: 'Level 3 Development Support',
      specialties: ['critical_issues', 'security', 'development'],
      isAvailable: true,
    );
  }

  /// Load existing data
  Future<void> _loadExistingData() async {
    // In a real implementation, this would load from a database
    // For demo purposes, we'll create some sample data

    _tickets.addAll([
      SupportTicket(
        id: 'TICKET-001',
        userId: 'user123',
        subject: 'Unable to access budget tracking',
        description: 'I can see my budget but cannot access the detailed breakdown',
        category: 'technical_issue',
        priority: 'medium',
        status: 'open',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        assignedAgent: 'agent2',
      ),
      SupportTicket(
        id: 'TICKET-002',
        userId: 'user456',
        subject: 'Screen reader not working properly',
        description: 'The screen reader is not reading the task descriptions correctly',
        category: 'accessibility',
        priority: 'high',
        status: 'in_progress',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        assignedAgent: 'agent3',
      ),
    ]);

    _feedback.addAll([
      UserFeedback(
        id: 'FEEDBACK-001',
        userId: 'user789',
        type: 'feature_request',
        title: 'Add voice commands for task creation',
        description: 'It would be great to create tasks using voice commands',
        rating: 4,
        category: 'accessibility',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        status: 'under_review',
      ),
      UserFeedback(
        id: 'FEEDBACK-002',
        userId: 'user101',
        type: 'bug_report',
        title: 'Calendar sync issue',
        description: 'Calendar events are not syncing with my device calendar',
        rating: 2,
        category: 'integration',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        status: 'acknowledged',
      ),
    ]);
  }

  /// Start support monitoring
  Future<void> _startSupportMonitoring() async {
    // Monitor for new tickets, feedback, and community posts
    Timer.periodic(const Duration(minutes: 5), (_) async {
      await _processNewTickets();
      await _processNewFeedback();
      await _updateTicketStatuses();
      await _generateSupportReport();
    });
  }

  /// Create a new support ticket
  Future<SupportTicket> createTicket({
    required String userId,
    required String subject,
    required String description,
    required String category,
    String priority = 'medium',
  }) async {
    final ticket = SupportTicket(
      id: 'TICKET-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      subject: subject,
      description: description,
      category: category,
      priority: priority,
      status: 'open',
      createdAt: DateTime.now(),
      assignedAgent: _assignAgent(category, priority),
    );

    _tickets.add(ticket);

    _logEvent(SupportEvent(
      type: 'ticket_created',
      message: 'New support ticket created: ${ticket.id}',
      timestamp: DateTime.now(),
      severity: 'info',
      data: {'ticket_id': ticket.id, 'category': category, 'priority': priority},
    ));

    // Notify assigned agent
    await _notifyAgent(ticket);

    print('🎫 New support ticket created: ${ticket.id}');
    return ticket;
  }

  /// Submit user feedback
  Future<UserFeedback> submitFeedback({
    required String userId,
    required String type,
    required String title,
    required String description,
    required int rating,
    required String category,
  }) async {
    final feedback = UserFeedback(
      id: 'FEEDBACK-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      type: type,
      title: title,
      description: description,
      rating: rating,
      category: category,
      createdAt: DateTime.now(),
      status: 'new',
    );

    _feedback.add(feedback);

    _logEvent(SupportEvent(
      type: 'feedback_submitted',
      message: 'New feedback submitted: ${feedback.id}',
      timestamp: DateTime.now(),
      severity: 'info',
      data: {'feedback_id': feedback.id, 'type': type, 'rating': rating},
    ));

    // Auto-categorize and prioritize feedback
    await _processFeedback(feedback);

    print('💬 New feedback submitted: ${feedback.id}');
    return feedback;
  }

  /// Process feedback for categorization
  Future<void> _processFeedback(UserFeedback feedback) async {
    // Auto-categorize feedback based on description content
    if (feedback.description.toLowerCase().contains('bug') ||
        feedback.description.toLowerCase().contains('error')) {
      feedback.category = 'bug';
    } else if (feedback.description.toLowerCase().contains('feature') ||
        feedback.description.toLowerCase().contains('request')) {
      feedback.category = 'feature_request';
    } else if (feedback.description.toLowerCase().contains('complaint') ||
        feedback.description.toLowerCase().contains('issue')) {
      feedback.category = 'complaint';
    } else {
      feedback.category = 'general';
    }
  }

  /// Create a community post
  Future<CommunityPost> createCommunityPost({
    required String userId,
    required String title,
    required String content,
    required String category,
  }) async {
    final post = CommunityPost(
      id: 'POST-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      title: title,
      content: content,
      category: category,
      createdAt: DateTime.now(),
      status: 'published',
      likes: 0,
      replies: 0,
    );

    _communityPosts.add(post);

    _logEvent(SupportEvent(
      type: 'community_post_created',
      message: 'New community post: ${post.id}',
      timestamp: DateTime.now(),
      severity: 'info',
      data: {'post_id': post.id, 'category': category},
    ));

    print('📝 New community post: ${post.id}');
    return post;
  }

  /// Assign agent to ticket
  String _assignAgent(String category, String priority) {
    // Find best available agent based on category and priority
    for (final agent in _agents.values) {
      if (!agent.isAvailable) continue;

      if (agent.specialties.contains(category)) {
        return agent.id;
      }
    }

    // Fallback to first available agent
    for (final agent in _agents.values) {
      if (agent.isAvailable) {
        return agent.id;
      }
    }

    return 'agent1'; // Default fallback
  }

  /// Notify assigned agent
  Future<void> _notifyAgent(SupportTicket ticket) async {
    final agent = _agents[ticket.assignedAgent];
    if (agent == null) return;

    final notification = {
      'type': 'ticket_assigned',
      'ticket_id': ticket.id,
      'subject': ticket.subject,
      'priority': ticket.priority,
      'category': ticket.category,
      'agent_name': agent.name,
      'agent_email': agent.email,
    };

    // In a real implementation, this would send email/SMS notification
    print('📧 Notifying agent ${agent.name}: New ticket ${ticket.id} assigned');
  }

  /// Process new tickets
  Future<void> _processNewTickets() async {
    final newTickets = _tickets.where((t) => t.status == 'open').toList();

    for (final ticket in newTickets) {
      // Check if ticket needs escalation
      if (_shouldEscalateTicket(ticket)) {
        await _escalateTicket(ticket);
      }

      // Update ticket status based on agent response
      if (ticket.assignedAgent != null) {
        ticket.status = 'in_progress';
      }
    }
  }

  /// Process new feedback
  Future<void> _processNewFeedback() async {
    final newFeedback = _feedback.where((f) => f.status == 'new').toList();

    for (final feedback in newFeedback) {
      // Auto-categorize feedback
      await _categorizeFeedback(feedback);

      // Check if feedback needs immediate attention
      if (feedback.rating <= 2) {
        await _prioritizeFeedback(feedback);
      }
    }
  }

  /// Update ticket statuses
  Future<void> _updateTicketStatuses() async {
    for (final ticket in _tickets) {
      if (ticket.status == 'in_progress') {
        // Check if ticket has been resolved
        if (_isTicketResolved(ticket)) {
          ticket.status = 'resolved';
          ticket.resolvedAt = DateTime.now();
        }
      }
    }
  }

  /// Check if ticket should be escalated
  bool _shouldEscalateTicket(SupportTicket ticket) {
    final age = DateTime.now().difference(ticket.createdAt);

    // Escalate based on priority and age
    switch (ticket.priority) {
      case 'critical':
        return age.inMinutes > 15;
      case 'high':
        return age.inHours > 2;
      case 'medium':
        return age.inHours > 8;
      case 'low':
        return age.inDays > 1;
      default:
        return false;
    }
  }

  /// Escalate ticket
  Future<void> _escalateTicket(SupportTicket ticket) async {
    // Find higher level agent
    String? escalatedAgent;

    if (ticket.assignedAgent == 'agent1') {
      escalatedAgent = 'agent2';
    } else if (ticket.assignedAgent == 'agent2') {
      escalatedAgent = 'agent4';
    } else if (ticket.assignedAgent == 'agent3') {
      escalatedAgent = 'agent4';
    }

    if (escalatedAgent != null) {
      ticket.assignedAgent = escalatedAgent;
      ticket.escalatedAt = DateTime.now();

      _logEvent(SupportEvent(
        type: 'ticket_escalated',
        message: 'Ticket ${ticket.id} escalated to $escalatedAgent',
        timestamp: DateTime.now(),
        severity: 'warning',
        data: {'ticket_id': ticket.id, 'escalated_to': escalatedAgent},
      ));

      print('⬆️ Ticket ${ticket.id} escalated to $escalatedAgent');
    }
  }

  /// Categorize feedback
  Future<void> _categorizeFeedback(UserFeedback feedback) async {
    // Simple categorization based on keywords
    final content = '${feedback.title} ${feedback.description}'.toLowerCase();

    if (content.contains('bug') || content.contains('error') || content.contains('issue')) {
      feedback.type = 'bug_report';
    } else if (content.contains('feature') ||
        content.contains('request') ||
        content.contains('suggest')) {
      feedback.type = 'feature_request';
    } else if (content.contains('accessibility') ||
        content.contains('screen reader') ||
        content.contains('voice')) {
      feedback.category = 'accessibility';
    }

    feedback.status = 'categorized';
  }

  /// Prioritize feedback
  Future<void> _prioritizeFeedback(UserFeedback feedback) async {
    feedback.status = 'high_priority';

    _logEvent(SupportEvent(
      type: 'feedback_prioritized',
      message: 'Feedback ${feedback.id} marked as high priority',
      timestamp: DateTime.now(),
      severity: 'warning',
      data: {'feedback_id': feedback.id, 'rating': feedback.rating},
    ));

    print('🔥 Feedback ${feedback.id} marked as high priority (rating: ${feedback.rating})');
  }

  /// Check if ticket is resolved
  bool _isTicketResolved(SupportTicket ticket) {
    // In a real implementation, this would check agent responses and user confirmation
    // For demo purposes, simulate resolution after some time
    final age = DateTime.now().difference(ticket.createdAt);
    return age.inHours > 1 && ticket.assignedAgent != null;
  }

  /// Generate support report
  Future<void> _generateSupportReport() async {
    final report = {
      'timestamp': DateTime.now().toIso8601String(),
      'tickets': {
        'total': _tickets.length,
        'open': _tickets.where((t) => t.status == 'open').length,
        'in_progress': _tickets.where((t) => t.status == 'in_progress').length,
        'resolved': _tickets.where((t) => t.status == 'resolved').length,
        'by_priority': _getTicketsByPriority(),
        'by_category': _getTicketsByCategory(),
      },
      'feedback': {
        'total': _feedback.length,
        'new': _feedback.where((f) => f.status == 'new').length,
        'under_review': _feedback.where((f) => f.status == 'under_review').length,
        'acknowledged': _feedback.where((f) => f.status == 'acknowledged').length,
        'average_rating': _getAverageRating(),
        'by_type': _getFeedbackByType(),
      },
      'community': {
        'total_posts': _communityPosts.length,
        'total_likes': _communityPosts.fold(0, (sum, post) => sum + post.likes),
        'total_replies': _communityPosts.fold(0, (sum, post) => sum + post.replies),
      },
      'agents': {
        'total': _agents.length,
        'available': _agents.values.where((a) => a.isAvailable).length,
        'workload': _getAgentWorkload(),
      },
    };

    // Save report
    final reportFile = File('user_support_report_${DateTime.now().millisecondsSinceEpoch}.json');
    await reportFile.writeAsString(jsonEncode(report));

    // Print summary every 10 minutes
    if (DateTime.now().minute % 10 == 0) {
      _printSupportSummary(report);
    }
  }

  /// Get tickets by priority
  Map<String, int> _getTicketsByPriority() {
    final priorities = <String, int>{};
    for (final ticket in _tickets) {
      priorities[ticket.priority] = (priorities[ticket.priority] ?? 0) + 1;
    }
    return priorities;
  }

  /// Get tickets by category
  Map<String, int> _getTicketsByCategory() {
    final categories = <String, int>{};
    for (final ticket in _tickets) {
      categories[ticket.category] = (categories[ticket.category] ?? 0) + 1;
    }
    return categories;
  }

  /// Get average rating
  double _getAverageRating() {
    if (_feedback.isEmpty) return 0.0;
    final totalRating = _feedback.fold(0, (sum, f) => sum + f.rating);
    return totalRating / _feedback.length;
  }

  /// Get feedback by type
  Map<String, int> _getFeedbackByType() {
    final types = <String, int>{};
    for (final feedback in _feedback) {
      types[feedback.type] = (types[feedback.type] ?? 0) + 1;
    }
    return types;
  }

  /// Get agent workload
  Map<String, int> _getAgentWorkload() {
    final workload = <String, int>{};
    for (final agent in _agents.values) {
      final agentTickets = _tickets.where((t) => t.assignedAgent == agent.id).length;
      workload[agent.name] = agentTickets;
    }
    return workload;
  }

  /// Print support summary
  void _printSupportSummary(Map<String, dynamic> report) {
    print('\n🎧 User Support Summary');
    print('=======================');
    print(
        'Tickets: ${report['tickets']['total']} (${report['tickets']['open']} open, ${report['tickets']['in_progress']} in progress)');
    print(
        'Feedback: ${report['feedback']['total']} (avg rating: ${report['feedback']['average_rating'].toStringAsFixed(1)})');
    print(
        'Community: ${report['community']['total_posts']} posts, ${report['community']['total_likes']} likes');
    print('Agents: ${report['agents']['available']}/${report['agents']['total']} available');
    print('');
  }

  /// Log support event
  void _logEvent(SupportEvent event) {
    _eventController.add(event);

    final logMessage =
        '[${event.timestamp.toIso8601String()}] [${event.severity.toUpperCase()}] ${event.type}: ${event.message}';
    print(logMessage);
  }

  /// Get all tickets
  List<SupportTicket> get tickets => List.unmodifiable(_tickets);

  /// Get all feedback
  List<UserFeedback> get feedback => List.unmodifiable(_feedback);

  /// Get all community posts
  List<CommunityPost> get communityPosts => List.unmodifiable(_communityPosts);

  /// Get all agents
  List<SupportAgent> get agents => List.unmodifiable(_agents.values);

  /// Get event stream
  Stream<SupportEvent> get eventStream => _eventController.stream;
}

/// Support Ticket class
class SupportTicket {
  final String id;
  final String userId;
  final String subject;
  final String description;
  final String category;
  final String priority;
  String status;
  final DateTime createdAt;
  String? assignedAgent;
  DateTime? escalatedAt;
  DateTime? resolvedAt;

  SupportTicket({
    required this.id,
    required this.userId,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.assignedAgent,
    this.escalatedAt,
    this.resolvedAt,
  });
}

/// User Feedback class
class UserFeedback {
  final String id;
  final String userId;
  String type;
  final String title;
  final String description;
  final int rating;
  String category;
  final DateTime createdAt;
  String status;

  UserFeedback({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.rating,
    required this.category,
    required this.createdAt,
    required this.status,
  });
}

/// Community Post class
class CommunityPost {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final String status;
  int likes;
  int replies;

  CommunityPost({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    required this.status,
    required this.likes,
    required this.replies,
  });
}

/// Support Agent class
class SupportAgent {
  final String id;
  final String name;
  final String email;
  final String role;
  final List<String> specialties;
  bool isAvailable;

  SupportAgent({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.specialties,
    required this.isAvailable,
  });
}

/// Support Event class
class SupportEvent {
  final String type;
  final String message;
  final DateTime timestamp;
  final String severity;
  final Map<String, dynamic>? data;

  SupportEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    required this.severity,
    this.data,
  });
}

/// Main function for testing the support system
void main() async {
  final supportSystem = UserSupportSystem();

  // Initialize the system
  await supportSystem.initialize();

  // Listen to events
  supportSystem.eventStream.listen((event) {
    print('📡 Support Event: ${event.type} - ${event.message}');
  });

  // Create some test tickets and feedback
  await supportSystem.createTicket(
    userId: 'test_user_1',
    subject: 'App crashes on startup',
    description: 'The app crashes immediately when I try to open it',
    category: 'technical_issue',
    priority: 'critical',
  );

  await supportSystem.submitFeedback(
    userId: 'test_user_2',
    type: 'feature_request',
    title: 'Add dark mode support',
    description: 'It would be great to have a dark mode option',
    rating: 5,
    category: 'ui_ux',
  );

  await supportSystem.createCommunityPost(
    userId: 'test_user_3',
    title: 'Tips for using voice navigation',
    content: 'Here are some helpful tips for using the voice navigation feature...',
    category: 'tips_and_tricks',
  );

  print('🎧 User Support System running...');
  print('Press Ctrl+C to stop');

  // Keep running for demonstration
  await Future.delayed(const Duration(minutes: 1));

  print('✅ Support system demo completed');
}
