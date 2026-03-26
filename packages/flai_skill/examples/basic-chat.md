# Basic Chat Setup

A complete example of setting up a minimal AI chat application with FlAI.

## Step 1: Install Components

```bash
dart pub global activate flai_cli
flai init
flai add chat_screen openai_provider
```

This installs the core theme system, data models, the full chat screen (which includes message_bubble, input_bar, streaming_text, and typing_indicator), and the OpenAI provider.

## Step 2: main.dart

```dart
import 'package:flutter/material.dart';
import 'flai/flai.dart';
import 'flai/components/chat_screen/chat_screen.dart';
import 'flai/components/chat_screen/chat_screen_controller.dart';
import 'flai/providers/openai_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FlaiTheme(
      data: FlaiThemeData.dark(),
      child: MaterialApp(
        title: 'AI Chat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF09090B),
        ),
        home: const ChatPage(),
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late final ChatScreenController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatScreenController(
      provider: OpenAiProvider(
        apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
        model: 'gpt-4o',
      ),
      systemPrompt: 'You are a helpful assistant. Keep responses concise.',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlaiChatScreen(
        controller: _controller,
        title: 'AI Assistant',
        subtitle: 'GPT-4o',
        inputPlaceholder: 'Ask me anything...',
      ),
    );
  }
}
```

## Step 3: Run

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
```

## What You Get

- Full chat screen with header showing title and subtitle
- Message bubbles aligned right (user) and left (assistant)
- Animated typing indicator while waiting for the first token
- Streaming text with blinking cursor as tokens arrive
- Auto-scroll to the latest message
- Input bar with Enter-to-send on desktop, multi-line support
- Error display with retry button if the API call fails
- Timestamps on each message

## Extending the Basic Setup

### Add a Cancel Button

```dart
FlaiChatScreen(
  controller: _controller,
  title: 'AI Assistant',
  actions: [
    ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (!_controller.isStreaming) return const SizedBox.shrink();
        return IconButton(
          icon: const Icon(Icons.stop_circle_outlined),
          onPressed: _controller.cancel,
        );
      },
    ),
  ],
)
```

### Add Attachment Support

```dart
FlaiChatScreen(
  controller: _controller,
  title: 'AI Assistant',
  onAttachmentTap: () async {
    // Use image_picker or file_picker to select a file
    // Then send it as an attachment:
    // _controller.sendMessage('Describe this image', attachments: [...]);
  },
)
```

### Add Long-Press Actions

```dart
FlaiChatScreen(
  controller: _controller,
  title: 'AI Assistant',
  onLongPress: (message) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: message.content));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  },
)
```

### Custom Empty State

```dart
FlaiChatScreen(
  controller: _controller,
  title: 'AI Assistant',
  emptyState: Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 48, color: Colors.amber),
        const SizedBox(height: 16),
        Text(
          'How can I help you today?',
          style: FlaiTheme.of(context).typography.bodyLarge(
            color: FlaiTheme.of(context).colors.mutedForeground,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 8,
          children: [
            _SuggestionChip('Explain quantum computing'),
            _SuggestionChip('Write a Flutter widget'),
            _SuggestionChip('Plan a weekend trip'),
          ],
        ),
      ],
    ),
  ),
)
```

## Using Anthropic Instead

Replace the provider setup:

```dart
import 'flai/providers/anthropic_provider.dart';

_controller = ChatScreenController(
  provider: AnthropicProvider(
    apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'),
    model: 'claude-sonnet-4-20250514',
    thinkingBudgetTokens: 8192,  // enables extended thinking
  ),
  systemPrompt: 'You are a helpful assistant.',
);
```

Run with the Anthropic key:

```bash
flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-your-key-here
```
