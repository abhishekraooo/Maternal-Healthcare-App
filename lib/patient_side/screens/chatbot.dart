import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:maternalhealthcare/patient_side/provider/patient_provider.dart';

class MedicalChatbotPage extends StatefulWidget {
  const MedicalChatbotPage({super.key});

  @override
  State<MedicalChatbotPage> createState() => _MedicalChatbotPageState();
}

class _MedicalChatbotPageState extends State<MedicalChatbotPage> {
  final String _apiKey = dotenv.env['GEMINI_API_KEY']!;
  final String _apiUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCachedChat();
  }

  void _loadCachedChat() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PatientDataProvider>(context, listen: false);
      if (provider.cachedChatHistory.isNotEmpty) {
        setState(() {
          // Deep copy to avoid direct state mutation issues
          _messages = List<Map<String, dynamic>>.from(
            provider.cachedChatHistory,
          );
        });
        _scrollToBottom();
      } else {
        // Initial greeting if no history exists
        _addMessage(
          "Hello! I am your maternal healthcare assistant. You can ask me about pregnancy symptoms, infant care, diet, or general wellness. How can I support you today?",
          false,
        );
      }
    });
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add({'text': text, 'isUser': isUser});
    });

    if (mounted) {
      Provider.of<PatientDataProvider>(
        context,
        listen: false,
      ).saveChatHistory(_messages);
    }
    _scrollToBottom();
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

  Future<void> _sendMessage() async {
    final String userMessage = _controller.text.trim();
    if (userMessage.isEmpty) return;

    _controller.clear();
    _addMessage(userMessage, true);

    setState(() {
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "systemInstruction": {
            "parts": [
              {
                "text":
                    "You are MediBot, a highly compassionate and knowledgeable maternal healthcare AI assistant. "
                    "Your expertise is strictly focused on pregnancy, postpartum care, fetal development, and infant wellness. "
                    "Respond in plain, highly readable text (avoid complex markdown like asterisks or hash symbols). "
                    "Keep responses concise (100-150 words), structured with clear line breaks, and provide practical, safe remedies. "
                    "IMPORTANT: You MUST end every single response with this exact disclaimer on a new line: "
                    "\n\nDisclaimer: I am an AI assistant and not a medical professional. Please consult a qualified healthcare provider for medical advice.",
              },
            ],
          },
          "contents": _buildConversationHistory(),
          "generationConfig": {
            "temperature":
                0.2, // Slightly creative but highly grounded in medical fact
          },
        }),
      );

      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        final botResponse =
            decodedResponse['candidates'][0]['content']['parts'][0]['text'];
        _addMessage(botResponse.trim(), false);
      } else {
        _addMessage(
          "System Error: Unable to connect to medical database at this time.",
          false,
        );
      }
    } catch (e) {
      _addMessage(
        "Network Error: Please check your connection and try again.",
        false,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  // Maps the local chat history into the exact format Gemini requires to maintain context
  List<Map<String, dynamic>> _buildConversationHistory() {
    List<Map<String, dynamic>> history = [];
    for (var msg in _messages) {
      // Skip the initial hardcoded greeting so it doesn't confuse the AI
      if (msg['text'].startsWith('Hello! I am your maternal')) continue;

      history.add({
        "role": msg['isUser'] ? "user" : "model",
        "parts": [
          {"text": msg['text']},
        ],
      });
    }
    return history;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.health_and_safety, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text("Ask AI", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear Chat',
            onPressed: () {
              setState(() {
                _messages.clear();
              });
              Provider.of<PatientDataProvider>(
                context,
                listen: false,
              ).clearChatHistory();
              _loadCachedChat(); // Reloads the initial greeting
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(
                      theme,
                      message['text'],
                      message['isUser'],
                    );
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'AI is typing...',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              _buildInputArea(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: isUser ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(
              isUser ? 20 : 4,
            ), // Sharp corner acting as a speech tail
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          border:
              isUser
                  ? null
                  : Border.all(
                    color: theme.colorScheme.secondary.withOpacity(0.5),
                  ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SelectableText(
          text,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isUser ? theme.colorScheme.surface : Colors.black87,
            height: 1.4,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    return Container(
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 12.0,
        bottom: 12.0 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 10,
            color: theme.colorScheme.secondary.withOpacity(0.2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: "Ask a medical question...",
                hintStyle: TextStyle(color: Colors.black38),
                filled: true,
                fillColor: theme.colorScheme.secondary.withOpacity(0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
              onSubmitted: (_) => _isLoading ? null : _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.send_rounded, color: theme.colorScheme.surface),
              onPressed: _isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
