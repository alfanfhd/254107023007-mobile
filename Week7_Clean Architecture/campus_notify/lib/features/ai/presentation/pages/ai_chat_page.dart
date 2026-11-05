import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_providers.dart';
import '../../domain/entities/chat_message.dart';

class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = TextEditingControllerScroll();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _handleSend() async {
    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    await ref.read(chatMessagesProvider.notifier).sendUserMessage(text);
    _scrollToBottom();
  }

  void _showApiKeyDialog(BuildContext context) {
    final keyController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: Color(0xFF4A00E0)),
              SizedBox(width: 8),
              Text('Atur Gemini API Key'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kunci disimpan aman di Secure Storage dan tidak akan bocor ke kode sumber.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('api_key_input_field'),
                controller: keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Google Gemini API Key',
                  hintText: 'AIzaSy...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              key: const Key('save_api_key_button'),
              onPressed: () async {
                final key = keyController.text.trim();
                if (key.isNotEmpty) {
                  await ref.read(aiRepositoryProvider).saveApiKey(key);
                  if (ctx.mounted) {
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API Key berhasil disimpan dengan aman.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(aiLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asisten Cerdas AI', style: TextStyle(fontSize: 18)),
            Text(
              'Terhubung dengan Gemini API',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('open_api_key_dialog_button'),
            tooltip: 'Atur Kunci API',
            icon: const Icon(Icons.key_rounded),
            onPressed: () => _showApiKeyDialog(context),
          ),
          IconButton(
            tooltip: 'Hapus Riwayat Chat',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(chatMessagesProvider.notifier).clearChat(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildPrivacyNotice(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == messages.length && isLoading) {
                  return _buildLoadingBubble();
                }
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          _buildQuickSuggestions(),
          _buildInputBar(isLoading),
        ],
      ),
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      width: double.infinity,
      color: Colors.amber.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, size: 16, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Privasi Terjaga: Kunci disimpan di Secure Storage & NIK disaring otomatis.',
              style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 10),
            Text(
              'AI sedang menyusun jawaban...',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.sender == MessageSender.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF4A00E0)
              : (msg.isError ? Colors.red.shade50 : Colors.grey.shade100),
          border: msg.isError ? Border.all(color: Colors.red.shade200) : null,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    msg.isError
                        ? Icons.warning_amber_rounded
                        : Icons.smart_toy_rounded,
                    size: 14,
                    color: msg.isError ? Colors.red : const Color(0xFF4A00E0),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    msg.isError ? 'Fallback AI' : 'Campus Bot',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: msg.isError ? Colors.red : const Color(0xFF4A00E0),
                    ),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 4),
            Text(
              msg.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (msg.isError ? Colors.red.shade900 : Colors.black87),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _buildChip('Jadwal Kuliah'),
          _buildChip('Ujian Tengah Semester'),
          _buildChip('Batas KRS'),
          _buildChip('Info Ruangan'),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          _textController.text = label;
          _handleSend();
        },
      ),
    );
  }

  Widget _buildInputBar(bool isLoading) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('chat_input_field'),
                controller: _textController,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _handleSend(),
                decoration: InputDecoration(
                  hintText: 'Tanyakan sesuatu ke asisten AI...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const Key('send_message_button'),
              icon: const Icon(Icons.send_rounded, color: Color(0xFF4A00E0)),
              onPressed: isLoading ? null : _handleSend,
            ),
          ],
        ),
      ),
    );
  }
}

class TextEditingControllerScroll extends ScrollController {}
