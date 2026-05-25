import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../models.dart';
import '../services/messages_service.dart';

class AdminMessagesScreen extends StatefulWidget {
  const AdminMessagesScreen({super.key});

  @override
  State<AdminMessagesScreen> createState() => _AdminMessagesScreenState();
}

class _AdminMessagesScreenState extends State<AdminMessagesScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  String? _selectedCategory;
  final List<String> _categories = ['All', 'Waitlist', 'Payment', 'General'];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    final cat = _selectedCategory == 'All' ? null : _selectedCategory;
    _messages = await MessagesService().getAllMessages(category: cat);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Communications')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((cat) {
                  final isSelected = (_selectedCategory ?? 'All') == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppTheme.primary.withOpacity(0.2),
                      backgroundColor: AppTheme.surface,
                      labelStyle: TextStyle(color: isSelected ? AppTheme.primary : Colors.white),
                      onSelected: (selected) {
                        setState(() => _selectedCategory = cat);
                        _loadMessages();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _messages.isEmpty
                    ? const Center(child: Text('No messages found', style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          return Card(
                            color: msg.isRead ? AppTheme.surface : AppTheme.surface.withOpacity(0.8),
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: msg.isRead ? Colors.transparent : AppTheme.primary, width: 1),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(msg.subject ?? 'No Subject', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(msg.content ?? '', style: TextStyle(color: AppTheme.textMuted)),
                                  const SizedBox(height: 8),
                                  Text(DateFormat('MMM d, HH:mm').format(msg.createdAt), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                ],
                              ),
                              trailing: msg.isRead 
                                  ? const Icon(Icons.mark_email_read, color: Colors.white38)
                                  : IconButton(
                                      icon: const Icon(Icons.mark_email_unread, color: AppTheme.primary),
                                      onPressed: () async {
                                        await MessagesService().markAsRead(msg.id);
                                        _loadMessages();
                                      },
                                    ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
