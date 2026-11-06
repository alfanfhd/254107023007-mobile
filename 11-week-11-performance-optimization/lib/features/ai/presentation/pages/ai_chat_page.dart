import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ai_providers.dart';
import '../../domain/entities/chat_message.dart';

/// Chat AI dengan pemisahan subtree:
/// - [_ChatMessageList] hanya rebuild saat daftar pesan/loading berubah;
/// - [_ChatComposer] hanya rebuild saat status loading berubah;
/// - halaman induk tidak `watch` state chat sehingga tidak ikut rebuild.
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    if (ref.read(aiLoadingProvider)) return;

    final text = _textController.text;
    if (text.trim().isEmpty) return;

    _textController.clear();
    await ref.read(chatMessagesProvider.notifier).sendUserMessage(text);
    _scrollToBottom();
  }

  void _sendSuggestion(String label) {
    _textController.text = label;
    _handleSend();
  }

  Future<void> _showApiKeyDialog(BuildContext context) async {
    final key = await showDialog<String>(
      context: context,
      builder: (ctx) => const _ApiKeyDialog(),
    );
    if (key == null || key.isEmpty || !context.mounted) return;

    await ref.read(aiRepositoryProvider).saveApiKey(key);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API Key berhasil disimpan dengan aman.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          const _PrivacyNotice(),
          Expanded(
            child: _ChatMessageList(scrollController: _scrollController),
          ),
          _QuickSuggestions(onSelected: _sendSuggestion),
          _ChatComposer(controller: _textController, onSend: _handleSend),
        ],
      ),
    );
  }
}

class _ApiKeyDialog extends StatefulWidget {
  const _ApiKeyDialog();

  @override
  State<_ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<_ApiKeyDialog> {
  // Controller dimiliki oleh State dialog agar ikut siklus hidup route dialog.
  // Dispose setelah showDialog selesai terlalu dini karena TextField masih
  // bisa dibangun ulang saat animasi pop berjalan.
  final TextEditingController _keyController = TextEditingController();

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  void _save() {
    final key = _keyController.text.trim();
    if (key.isEmpty) return;
    Navigator.of(context).pop(key);
  }

  @override
  Widget build(BuildContext context) {
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
            controller: _keyController,
            obscureText: true,
            onSubmitted: (_) => _save(),
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
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          key: const Key('save_api_key_button'),
          onPressed: _save,
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
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
}

class _ChatMessageList extends ConsumerWidget {
  const _ChatMessageList({required this.scrollController});

  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesProvider);
    final isLoading = ref.watch(aiLoadingProvider);

    return ListView.builder(
      key: const Key('chat_message_list'),
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      addAutomaticKeepAlives: false,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: messages.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == messages.length && isLoading) {
          return const _LoadingBubble();
        }
        return _MessageBubble(message: messages[index]);
      },
    );
  }
}

class _LoadingBubble extends StatelessWidget {
  const _LoadingBubble();

  @override
  Widget build(BuildContext context) {
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
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == MessageSender.user;
    // MediaQuery.sizeOf hanya rebuild saat ukuran layar berubah, berbeda
    // dengan MediaQuery.of yang ikut rebuild untuk perubahan lain.
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF4A00E0)
              : (message.isError ? Colors.red.shade50 : Colors.grey.shade100),
          border: message.isError
              ? Border.all(color: Colors.red.shade200)
              : null,
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
            if (!isUser) _SenderLabel(isError: message.isError),
            if (!isUser) const SizedBox(height: 4),
            Text(
              message.text,
              style: TextStyle(
                color: isUser
                    ? Colors.white
                    : (message.isError ? Colors.red.shade900 : Colors.black87),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SenderLabel extends StatelessWidget {
  const _SenderLabel({required this.isError});

  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : const Color(0xFF4A00E0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isError ? Icons.warning_amber_rounded : Icons.smart_toy_rounded,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          isError ? 'Fallback AI' : 'Campus Bot',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _QuickSuggestions extends StatelessWidget {
  const _QuickSuggestions({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          _SuggestionChip(label: 'Jadwal Kuliah', onSelected: onSelected),
          _SuggestionChip(
            label: 'Ujian Tengah Semester',
            onSelected: onSelected,
          ),
          _SuggestionChip(label: 'Batas KRS', onSelected: onSelected),
          _SuggestionChip(label: 'Info Ruangan', onSelected: onSelected),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onSelected});

  final String label;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: () => onSelected(label),
      ),
    );
  }
}

class _ChatComposer extends ConsumerWidget {
  const _ChatComposer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Hanya subtree ini yang rebuild ketika status loading berubah.
    final isLoading = ref.watch(aiLoadingProvider.select((loading) => loading));

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
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
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
              onPressed: isLoading ? null : onSend,
            ),
          ],
        ),
      ),
    );
  }
}
