---
name: flai
description: Install and use FlAI AI chat components in Flutter projects. Guides component selection, installation, theming, and provider setup.
---

# FlAI -- AI Chat Components for Flutter

FlAI is a shadcn/ui-style component library for Flutter that gives you production-ready AI chat UI as source code you own. Components are distributed via a Mason-powered CLI -- you install exactly what you need, and the code lives in your project.

Docs: https://getflai.dev

## When to Use This Skill

- User wants to add AI chat UI to a Flutter app
- User asks about FlAI components (message bubbles, input bars, streaming text, etc.)
- User needs help with FlAI theming (colors, typography, spacing, radius, icons)
- User wants to connect to OpenAI or Anthropic APIs
- User asks about building a chat screen, conversation list, or model selector

## Installation

### Prerequisites

- Flutter 3.22+ with Dart 3.4+
- An existing Flutter project

### Install the CLI

```bash
dart pub global activate flai_cli
```

### Initialize FlAI in Your Project

```bash
flai init
```

This runs the `flai_init` brick, generating the core foundation into your `lib/` directory:

- `core/theme/` -- FlaiTheme, FlaiColors, FlaiTypography, FlaiRadius, FlaiSpacing, FlaiIconData
- `core/models/` -- Message, Conversation, ChatEvent (sealed class), ChatRequest
- `providers/ai_provider.dart` -- Abstract AiProvider interface
- `flai.dart` -- Barrel export file

### Add Components

```bash
flai add chat_screen
flai add message_bubble
flai add input_bar
flai add openai_provider
```

You can add multiple components at once:

```bash
flai add chat_screen message_bubble input_bar streaming_text typing_indicator
```

## Available Components

### Chat Essentials

| Component | Command | Description |
|---|---|---|
| `chat_screen` | `flai add chat_screen` | Full chat screen with header, message list, and input bar. Depends on: message_bubble, input_bar, streaming_text, typing_indicator |
| `message_bubble` | `flai add message_bubble` | Message bubble with user/assistant styling, thinking blocks, tool call chips, citations, streaming cursor, and error retry |
| `input_bar` | `flai add input_bar` | Text input with send button, attachment support, Enter-to-send on desktop, multi-line growth |
| `streaming_text` | `flai add streaming_text` | Token-by-token text rendering with blinking cursor. Two modes: stream-driven or text-driven |
| `typing_indicator` | `flai add typing_indicator` | Animated three-dot bouncing indicator styled as an assistant bubble |

### AI Widgets

| Component | Command | Description |
|---|---|---|
| `tool_call_card` | `flai add tool_call_card` | Function/tool call display card with status and arguments |
| `code_block` | `flai add code_block` | Syntax-highlighted code display with copy-to-clipboard |
| `thinking_indicator` | `flai add thinking_indicator` | AI reasoning/thinking panel (collapsible) |
| `citation_card` | `flai add citation_card` | Source attribution card with title, URL, and snippet |
| `image_preview` | `flai add image_preview` | Image thumbnail with tap-to-zoom |

### Conversation Management

| Component | Command | Description |
|---|---|---|
| `conversation_list` | `flai add conversation_list` | Conversation history list with search and selection |
| `model_selector` | `flai add model_selector` | AI model picker dropdown |
| `token_usage` | `flai add token_usage` | Token count display (input/output/cache) |

### AI Providers

| Provider | Command | Description |
|---|---|---|
| `openai_provider` | `flai add openai_provider` | OpenAI Chat Completions API with streaming, tool use, and vision. Uses raw HTTP (package:http) |
| `anthropic_provider` | `flai add anthropic_provider` | Anthropic Messages API with streaming, tool use, extended thinking, and vision. Uses raw HTTP (package:http) |

## Quick Start -- Complete Chat App

Here is the minimal code to get a working AI chat screen:

### 1. Install and add components

```bash
dart pub global activate flai_cli
flai init
flai add chat_screen openai_provider
```

### 2. Set up the app

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
        theme: ThemeData.dark(),
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
      systemPrompt: 'You are a helpful assistant.',
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
      ),
    );
  }
}
```

### 3. Run with your API key

```bash
flutter run --dart-define=OPENAI_API_KEY=sk-your-key-here
```

## Theming

FlAI uses an InheritedWidget-based theme system with semantic color tokens modeled after shadcn/ui.

### FlaiThemeData

`FlaiThemeData` composes five sub-systems:

| Field | Type | Description |
|---|---|---|
| `colors` | `FlaiColors` | Semantic color tokens (background, foreground, primary, muted, userBubble, etc.) |
| `icons` | `FlaiIconData` | Semantic icon set (20 icon fields). Defaults to `FlaiIconData.material()` |
| `typography` | `FlaiTypography` | Font families and size scale |
| `radius` | `FlaiRadius` | Border radius tokens |
| `spacing` | `FlaiSpacing` | Spacing tokens |

### Built-in Presets

| Preset | Factory | Icons | Description |
|---|---|---|---|
| Zinc Light | `FlaiThemeData.light()` | `FlaiIconData.material()` | Clean light theme with zinc neutrals |
| Zinc Dark | `FlaiThemeData.dark()` | `FlaiIconData.material()` | Dark theme with zinc neutrals |
| iOS | `FlaiThemeData.ios()` | `FlaiIconData.cupertino()` | Apple Messages-inspired blue bubbles, iOS system colors, larger radii, Cupertino icons |
| Premium | `FlaiThemeData.premium()` | `FlaiIconData.sharp()` | Linear-inspired dark theme with indigo accents, sharp Material icons |

### FlaiIconData

Semantic icon set with 20 fields. Components access icons via `FlaiTheme.of(context).icons` instead of hardcoding `Icons.*` or `CupertinoIcons.*`.

**Presets:**

- `FlaiIconData.material()` -- Material Design rounded icons (default for light/dark)
- `FlaiIconData.cupertino()` -- Apple SF Symbols style (used by ios() preset)
- `FlaiIconData.sharp()` -- Material Design sharp icons (used by premium() preset)

**Icon fields:** toolCall, thinking, citation, image, brokenImage, code, copy, check, close, send, attach, search, delete, add, expand, collapse, chat, model, refresh, error

```dart
// Override specific icons on a preset
final customTheme = FlaiThemeData.dark().copyWith(
  icons: FlaiIconData.material().copyWith(
    send: Icons.arrow_upward_rounded,
    chat: Icons.forum_rounded,
  ),
);
```

### Applying a Theme

Wrap your app (or a subtree) with `FlaiTheme`:

```dart
FlaiTheme(
  data: FlaiThemeData.dark(),
  child: MaterialApp(
    home: ChatPage(),
  ),
)
```

All FlAI widgets read their styling via `FlaiTheme.of(context)`.

### Custom Theme

Create a fully custom theme by constructing `FlaiThemeData` directly:

```dart
final myTheme = FlaiThemeData(
  colors: FlaiColors(
    background: Color(0xFF0F172A),
    foreground: Color(0xFFF8FAFC),
    card: Color(0xFF1E293B),
    cardForeground: Color(0xFFF8FAFC),
    popover: Color(0xFF1E293B),
    popoverForeground: Color(0xFFF8FAFC),
    primary: Color(0xFF3B82F6),
    primaryForeground: Color(0xFFFFFFFF),
    secondary: Color(0xFF334155),
    secondaryForeground: Color(0xFFF8FAFC),
    muted: Color(0xFF334155),
    mutedForeground: Color(0xFF94A3B8),
    accent: Color(0xFF3B82F6),
    accentForeground: Color(0xFFFFFFFF),
    destructive: Color(0xFFEF4444),
    destructiveForeground: Color(0xFFFFFFFF),
    border: Color(0xFF334155),
    input: Color(0xFF334155),
    ring: Color(0xFF3B82F6),
    userBubble: Color(0xFF3B82F6),
    userBubbleForeground: Color(0xFFFFFFFF),
    assistantBubble: Color(0xFF1E293B),
    assistantBubbleForeground: Color(0xFFF8FAFC),
  ),
  icons: FlaiIconData.material(),  // or .cupertino(), .sharp(), or custom
  typography: FlaiTypography(
    fontFamily: 'Inter',
    monoFontFamily: 'Fira Code',
    base: 15.0,
  ),
  radius: FlaiRadius(sm: 6, md: 10, lg: 16, xl: 20, full: 9999),
  spacing: FlaiSpacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48),
);
```

### Modifying a Preset

Use `copyWith` to tweak an existing preset:

```dart
final customDark = FlaiThemeData.dark().copyWith(
  colors: FlaiColors.dark().copyWith(
    primary: Color(0xFF10B981),        // emerald accent
    userBubble: Color(0xFF10B981),
    userBubbleForeground: Color(0xFFFFFFFF),
  ),
  icons: FlaiIconData.cupertino(),     // swap to Cupertino icons
  typography: FlaiTypography(fontFamily: 'Inter'),
);
```

### Theme Token Reference

**Colors:** background, foreground, card, cardForeground, popover, popoverForeground, primary, primaryForeground, secondary, secondaryForeground, muted, mutedForeground, accent, accentForeground, destructive, destructiveForeground, border, input, ring, userBubble, userBubbleForeground, assistantBubble, assistantBubbleForeground

**Icons:** toolCall, thinking, citation, image, brokenImage, code, copy, check, close, send, attach, search, delete, add, expand, collapse, chat, model, refresh, error

**Typography:** fontFamily, monoFontFamily, sm (12), base (14), lg (16), xl (20), xxl (24). Methods: `bodySmall()`, `bodyBase()`, `bodyLarge()`, `heading()`, `headingLarge()`, `mono()`

**Radius:** sm (4), md (8), lg (12), xl (16), full (9999)

**Spacing:** xs (4), sm (8), md (16), lg (24), xl (32), xxl (48)

## Provider Setup

### OpenAI Provider

```dart
import 'flai/providers/openai_provider.dart';

final provider = OpenAiProvider(
  apiKey: 'sk-your-key',
  model: 'gpt-4o',            // default: 'gpt-4o'
  // baseUrl: 'https://your-proxy.com/v1',  // optional
  // organization: 'org-xxx',                // optional
);

// Capabilities:
// provider.supportsToolUse    == true
// provider.supportsVision     == true
// provider.supportsStreaming   == true
// provider.supportsThinking   == false
```

### Anthropic Provider

```dart
import 'flai/providers/anthropic_provider.dart';

final provider = AnthropicProvider(
  apiKey: 'sk-ant-your-key',
  model: 'claude-sonnet-4-20250514',   // default
  // thinkingBudgetTokens: 8192,          // enable extended thinking
  // baseUrl: 'https://your-proxy.com',   // optional
);

// Capabilities:
// provider.supportsToolUse    == true
// provider.supportsVision     == true
// provider.supportsStreaming   == true
// provider.supportsThinking   == true
```

### Using a Provider with ChatScreenController

```dart
final controller = ChatScreenController(
  provider: provider,
  systemPrompt: 'You are a helpful AI assistant.',
  // initialMessages: [...],  // optional conversation history
);

// Send a message (streams the response automatically):
await controller.sendMessage('Hello!');

// Cancel streaming:
await controller.cancel();

// Retry last failed message:
await controller.retry();

// Clear conversation:
controller.clearMessages();

// Listen to state changes:
controller.addListener(() {
  print('Streaming: ${controller.isStreaming}');
  print('Current text: ${controller.streamingText}');
  print('Messages: ${controller.messages.length}');
});
```

### Tool Use

Define tools and send them with requests:

```dart
final tools = [
  ToolDefinition(
    name: 'get_weather',
    description: 'Get the current weather for a location',
    parameters: {
      'type': 'object',
      'properties': {
        'location': {
          'type': 'string',
          'description': 'City name',
        },
      },
      'required': ['location'],
    },
  ),
];

final request = ChatRequest(
  messages: messages,
  tools: tools,
);

// Stream and handle tool call events:
await for (final event in provider.streamChat(request)) {
  switch (event) {
    case TextDelta(:final text):
      // Append text to UI
      break;
    case ToolCallStart(:final id, :final name):
      // Show tool call card
      break;
    case ToolCallDelta(:final id, :final argumentsDelta):
      // Update tool call arguments
      break;
    case ToolCallEnd(:final id):
      // Execute tool and send result back
      break;
    case ChatDone():
      // Stream complete
      break;
    case ChatError(:final error):
      // Handle error
      break;
    default:
      break;
  }
}
```

## Data Models

### Message

```dart
Message(
  id: 'unique-id',
  role: MessageRole.user,        // user, assistant, system, tool
  content: 'Hello!',
  timestamp: DateTime.now(),
  status: MessageStatus.complete, // streaming, complete, error
  attachments: [...],            // optional
  toolCalls: [...],              // optional
  thinkingContent: '...',        // optional (Anthropic thinking)
  citations: [...],              // optional
  usage: UsageInfo(...),         // optional
)
```

### ChatEvent (sealed class)

The streaming system uses a sealed `ChatEvent` class for type-safe event handling:

- `TextDelta(text)` -- Incremental text chunk
- `TextDone(fullText)` -- Text complete with full content
- `ThinkingStart()` -- AI began reasoning
- `ThinkingDelta(text)` -- Thinking text chunk
- `ThinkingEnd()` -- Reasoning complete
- `ToolCallStart(id, name)` -- Tool call initiated
- `ToolCallDelta(id, argumentsDelta)` -- Tool call argument chunk
- `ToolCallEnd(id)` -- Tool call complete
- `UsageUpdate(inputTokens, outputTokens, ...)` -- Token usage report
- `ChatDone()` -- Stream finished
- `ChatError(error, stackTrace?)` -- Error occurred

## Architecture Notes

- All widgets use `FlaiTheme.of(context)` to read styling -- no hardcoded colors or icons
- Components access icons via `theme.icons.send`, `theme.icons.copy`, etc.
- Components use the Widget + Controller + State pattern for complex state
- The `AiProvider` abstract class defines the interface; implementations use raw HTTP via `package:http`
- No external state management dependency -- vanilla Flutter (`ChangeNotifier`, `Stream`)
- Components are Mason bricks; the `{{output_dir}}` variable controls output location
- Zero external dependencies in core; provider bricks add `package:http`

## Starter Patterns

### Basic Chat

```bash
dart pub global activate flai_cli
flai init
flai add chat_screen openai_provider
```

```dart
FlaiTheme(
  data: FlaiThemeData.dark(),
  child: MaterialApp(
    home: Scaffold(
      body: FlaiChatScreen(
        controller: ChatScreenController(
          provider: OpenAiProvider(
            apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
            model: 'gpt-4o',
          ),
          systemPrompt: 'You are a helpful assistant.',
        ),
        title: 'AI Chat',
      ),
    ),
  ),
)
```

### Multi-Model Switching

```dart
final providers = {
  'GPT-4o': OpenAiProvider(
    apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
    model: 'gpt-4o',
  ),
  'Claude': AnthropicProvider(
    apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'),
    model: 'claude-sonnet-4-20250514',
  ),
};

// Swap provider at runtime:
void switchModel(String name) {
  _controller.dispose();
  setState(() {
    _controller = ChatScreenController(
      provider: providers[name]!,
      systemPrompt: 'You are a helpful assistant.',
    );
  });
}
```

### Tool Calling

```dart
final controller = ChatScreenController(
  provider: OpenAiProvider(
    apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
    model: 'gpt-4o',
  ),
  systemPrompt: 'You can look up weather.',
  tools: [
    ToolDefinition(
      name: 'get_weather',
      description: 'Get weather for a city',
      parameters: {
        'type': 'object',
        'properties': {
          'city': {'type': 'string', 'description': 'City name'},
        },
        'required': ['city'],
      },
    ),
  ],
  onToolCall: (name, args) async {
    if (name == 'get_weather') {
      return '{"temp": 72, "condition": "sunny"}';
    }
    return '{"error": "unknown tool"}';
  },
);
```

### Custom Theme

```dart
final brandTheme = FlaiThemeData.dark().copyWith(
  colors: FlaiColors.dark().copyWith(
    primary: Color(0xFF10B981),
    userBubble: Color(0xFF10B981),
    userBubbleForeground: Color(0xFFFFFFFF),
  ),
  icons: FlaiIconData.cupertino(),
  typography: FlaiTypography(fontFamily: 'Inter', monoFontFamily: 'Fira Code'),
);

FlaiTheme(
  data: brandTheme,
  child: MaterialApp(home: ChatPage()),
)
```

## Common Patterns

### Switch Between Light and Dark Theme

```dart
class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDark = true;

  @override
  Widget build(BuildContext context) {
    return FlaiTheme(
      data: _isDark ? FlaiThemeData.dark() : FlaiThemeData.light(),
      child: MaterialApp(
        theme: _isDark ? ThemeData.dark() : ThemeData.light(),
        home: ChatPage(
          onToggleTheme: () => setState(() => _isDark = !_isDark),
        ),
      ),
    );
  }
}
```

### Use StreamingText Standalone

```dart
FlaiStreamingText(
  text: controller.streamingText,
  isStreaming: controller.isStreaming,
  style: FlaiTheme.of(context).typography.bodyBase(
    color: FlaiTheme.of(context).colors.foreground,
  ),
)
```

Or directly from a stream:

```dart
FlaiStreamingText.fromStream(
  stream: provider.streamChat(request)
      .whereType<TextDelta>()
      .map((e) => e.text),
  onStreamDone: () => print('Done!'),
)
```

### Custom Empty State

```dart
FlaiChatScreen(
  controller: controller,
  emptyState: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset('assets/logo.png', height: 64),
      SizedBox(height: 16),
      Text('How can I help you today?'),
    ],
  ),
)
```

### Using Theme Icons in Custom Widgets

```dart
Widget build(BuildContext context) {
  final theme = FlaiTheme.of(context);

  return IconButton(
    icon: Icon(theme.icons.send, color: theme.colors.primary),
    onPressed: onSend,
  );
}
```
