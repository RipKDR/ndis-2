import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../services/chatbot_service.dart';
import '../services/error_handling_service.dart';
import '../widgets/accessibility_widgets.dart';
import '../widgets/error_boundary.dart';

class ChatbotScreen extends StatefulWidget {
  static const route = '/chatbot';
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatbotService _chatbotService = ChatbotService();
  String? _currentSessionId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    _currentSessionId = await _chatbotService.createNewSession();
    setState(() {});
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    _messageController.clear();
    setState(() => _isLoading = true);

    try {
      await _chatbotService.sendMessage(message, sessionId: _currentSessionId);
      _scrollToBottom();
    } catch (e) {
      context.read<ErrorHandlingService>().handleError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: AccessibleText('Failed to send message: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // AppLocalizations not currently used in this screen; remove unused local to satisfy lints.

    return ErrorBoundary(
      context: 'ChatbotScreen',
      onRetry: () {
        // Retry functionality
      },
      child: Scaffold(
        appBar: AppBar(
          title: const AccessibleText('NDIS Assistant'),
          actions: [
            AccessibleIconButton(
              onPressed: _showQuickActions,
              icon: Icons.help_outline,
              tooltip: 'Quick Actions',
            ),
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'new_session', child: AccessibleText('New Chat')),
                const PopupMenuItem(value: 'clear_history', child: AccessibleText('Clear History')),
                const PopupMenuItem(value: 'sessions', child: AccessibleText('Chat History')),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: _getChatStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          AccessibleText('Error loading chat: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => setState(() {}),
                            child: const AccessibleText('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _buildWelcomeMessage();
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final message = snapshot.data![index];
                      return _buildMessageBubble(message);
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.smart_toy, size: 64, color: Colors.blue),
          const SizedBox(height: 16),
          AccessibleText(
            'Welcome to NDIS Assistant',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          AccessibleText(
            'I can help you with tasks, services, budget information, and more.',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildQuickActionsGrid(),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    final quickActions = _chatbotService.getQuickActions();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickActions.map((action) {
        return ActionChip(
          label: AccessibleText(action['title'] as String),
          onPressed: () => _sendQuickMessage(action['message'] as String),
        );
      }).toList(),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.type == ChatMessageType.user;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccessibleText(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AccessibleText(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: _isLoading ? null : _sendMessage,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Stream<List<ChatMessage>> _getChatStream() async* {
    while (true) {
      final history = await _chatbotService.getChatHistory(
        sessionId: _currentSessionId,
        limit: 50,
      );
      yield history;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _sendQuickMessage(String message) {
    _messageController.text = message;
    _sendMessage();
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccessibleText(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ..._chatbotService.getQuickActions().map((action) {
              return ListTile(
                leading: Icon(_getActionIcon(action['intent'] as ChatbotIntent)),
                title: AccessibleText(action['title'] as String),
                onTap: () {
                  Navigator.pop(context);
                  _sendQuickMessage(action['message'] as String);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getActionIcon(ChatbotIntent intent) {
    switch (intent) {
      case ChatbotIntent.task_management:
        return Icons.check_circle;
      case ChatbotIntent.service_finder:
        return Icons.map;
      case ChatbotIntent.budget_info:
        return Icons.pie_chart;
      case ChatbotIntent.appointment_booking:
        return Icons.calendar_today;
      case ChatbotIntent.emergency:
        return Icons.emergency;
      default:
        return Icons.help;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_session':
        _initializeChat();
        break;
      case 'clear_history':
        _clearChatHistory();
        break;
      case 'sessions':
        _showSessions();
        break;
    }
  }

  Future<void> _clearChatHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const AccessibleText('Clear Chat History'),
        content: const AccessibleText('Are you sure you want to clear all chat history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AccessibleText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const AccessibleText('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatbotService.clearChatHistory(sessionId: _currentSessionId);
      setState(() {});
    }
  }

  void _showSessions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccessibleText(
              'Chat History',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _chatbotService.getSessions(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final sessions = snapshot.data!;
                  if (sessions.isEmpty) {
                    return const Center(child: AccessibleText('No chat history found'));
                  }

                  return ListView.builder(
                    itemCount: sessions.length,
                    itemBuilder: (context, index) {
                      final session = sessions[index];
                      return ListTile(
                        title: AccessibleText('Chat ${index + 1}'),
                        subtitle: AccessibleText(_formatTime(DateTime.parse(session['createdAt']))),
                        trailing: AccessibleIconButton(
                          icon: Icons.delete,
                          onPressed: () => _deleteSession(session['id'] as String),
                          tooltip: 'Delete Session',
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _currentSessionId = session['id'] as String;
                          setState(() {});
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSession(String sessionId) async {
    await _chatbotService.deleteSession(sessionId);
    if (_currentSessionId == sessionId) {
      _initializeChat();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
