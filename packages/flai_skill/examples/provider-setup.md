# Provider Configuration

FlAI uses an abstract `AiProvider` interface with concrete implementations for OpenAI and Anthropic. Both providers use raw HTTP via `package:http` with no SDK dependencies.

## The AiProvider Interface

```dart
abstract class AiProvider {
  Stream<ChatEvent> streamChat(ChatRequest request);
  Future<ChatResponse> chat(ChatRequest request);
  Future<void> cancel();

  bool get supportsToolUse;
  bool get supportsVision;
  bool get supportsStreaming;
  bool get supportsThinking;
}
```

## OpenAI Provider

### Installation

```bash
flai add openai_provider
```

This adds `package:http` to your `pubspec.yaml` and generates `providers/openai_provider.dart`.

### Basic Setup

```dart
import 'flai/providers/openai_provider.dart';

final provider = OpenAiProvider(
  apiKey: const String.fromEnvironment('OPENAI_API_KEY'),
  model: 'gpt-4o',
);
```

### All Configuration Options

```dart
final provider = OpenAiProvider(
  apiKey: 'sk-...',                              // required
  model: 'gpt-4o',                               // default: 'gpt-4o'
  baseUrl: 'https://api.openai.com/v1',          // default; override for proxies
  organization: 'org-xxx',                        // optional Organization header
);
```

### Capabilities

| Feature | Supported |
|---|---|
| Streaming | Yes |
| Tool/Function calling | Yes |
| Vision (image input) | Yes |
| Extended thinking | No |

### Compatible Models

- `gpt-4o` (default, recommended)
- `gpt-4o-mini`
- `gpt-4-turbo`
- `o1`, `o1-mini`, `o3-mini`
- Any OpenAI-compatible API (Azure OpenAI, Together AI, Groq, etc.)

### Using with a Proxy or OpenAI-Compatible API

```dart
// Azure OpenAI
final provider = OpenAiProvider(
  apiKey: 'your-azure-key',
  baseUrl: 'https://your-resource.openai.azure.com/openai/deployments/gpt-4o',
);

// Groq
final provider = OpenAiProvider(
  apiKey: 'gsk_...',
  baseUrl: 'https://api.groq.com/openai/v1',
  model: 'llama-3.3-70b-versatile',
);

// Together AI
final provider = OpenAiProvider(
  apiKey: 'your-together-key',
  baseUrl: 'https://api.together.xyz/v1',
  model: 'meta-llama/Llama-3-70b-chat-hf',
);
```

## Anthropic Provider

### Installation

```bash
flai add anthropic_provider
```

### Basic Setup

```dart
import 'flai/providers/anthropic_provider.dart';

final provider = AnthropicProvider(
  apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'),
  model: 'claude-sonnet-4-20250514',
);
```

### All Configuration Options

```dart
final provider = AnthropicProvider(
  apiKey: 'sk-ant-...',                          // required
  model: 'claude-sonnet-4-20250514',             // default
  baseUrl: 'https://api.anthropic.com',          // default; override for proxies
  anthropicVersion: '2023-06-01',                // default API version
  thinkingBudgetTokens: 8192,                    // null = disabled (default)
);
```

### Capabilities

| Feature | Supported |
|---|---|
| Streaming | Yes |
| Tool/Function calling | Yes |
| Vision (image input) | Yes |
| Extended thinking | Yes |

### Compatible Models

- `claude-sonnet-4-20250514` (default, recommended)
- `claude-opus-4-20250514`
- `claude-3-5-haiku-20241022`
- Any Anthropic Messages API-compatible endpoint

### Extended Thinking

Anthropic's extended thinking lets the model reason before responding. The thinking content is captured and displayed in the message bubble's collapsible thinking block.

```dart
final provider = AnthropicProvider(
  apiKey: const String.fromEnvironment('ANTHROPIC_API_KEY'),
  model: 'claude-sonnet-4-20250514',
  thinkingBudgetTokens: 8192,  // allocate tokens for thinking
);
```

When thinking is enabled, the streaming events include:

1. `ThinkingStart()` -- reasoning begins
2. `ThinkingDelta(text)` -- thinking text chunks
3. `ThinkingEnd()` -- reasoning complete
4. `TextDelta(text)` -- response text begins

The `ChatScreenController` automatically captures thinking content and stores it in `Message.thinkingContent`. The `MessageBubble` renders it as a collapsible "Thinking..." block above the response.

## Streaming Pattern

Both providers emit the same `ChatEvent` types. Here is the full streaming pattern:

```dart
final request = ChatRequest(
  messages: [
    Message(
      id: '1',
      role: MessageRole.user,
      content: 'Hello!',
      timestamp: DateTime.now(),
    ),
  ],
  maxTokens: 1024,
  temperature: 0.7,
);

await for (final event in provider.streamChat(request)) {
  switch (event) {
    // Text streaming
    case TextDelta(:final text):
      stdout.write(text);  // incremental token
    case TextDone(:final fullText):
      print('\n--- Complete: $fullText');

    // Thinking (Anthropic only)
    case ThinkingStart():
      print('[Thinking...]');
    case ThinkingDelta(:final text):
      stdout.write(text);
    case ThinkingEnd():
      print('[/Thinking]');

    // Tool calls
    case ToolCallStart(:final id, :final name):
      print('Tool call: $name ($id)');
    case ToolCallDelta(:final id, :final argumentsDelta):
      stdout.write(argumentsDelta);
    case ToolCallEnd(:final id):
      print('\nTool call $id complete');

    // Usage and completion
    case UsageUpdate(:final inputTokens, :final outputTokens):
      print('Tokens: $inputTokens in / $outputTokens out');
    case ChatDone():
      print('Stream complete');
    case ChatError(:final error):
      print('Error: $error');
  }
}
```

## Non-Streaming Usage

For simple request/response without streaming:

```dart
final response = await provider.chat(ChatRequest(
  messages: [
    Message(
      id: '1',
      role: MessageRole.user,
      content: 'What is 2+2?',
      timestamp: DateTime.now(),
    ),
  ],
));

print(response.message.content);  // "4"
print(response.usage?.totalTokens);  // token count
```

## Tool Use with Providers

Both OpenAI and Anthropic providers support function/tool calling with the same `ToolDefinition` interface:

```dart
final tools = [
  ToolDefinition(
    name: 'search_web',
    description: 'Search the web for current information',
    parameters: {
      'type': 'object',
      'properties': {
        'query': {
          'type': 'string',
          'description': 'The search query',
        },
      },
      'required': ['query'],
    },
  ),
  ToolDefinition(
    name: 'get_weather',
    description: 'Get current weather for a city',
    parameters: {
      'type': 'object',
      'properties': {
        'city': {'type': 'string', 'description': 'City name'},
        'units': {
          'type': 'string',
          'enum': ['celsius', 'fahrenheit'],
          'description': 'Temperature units',
        },
      },
      'required': ['city'],
    },
  ),
];

final request = ChatRequest(
  messages: messages,
  tools: tools,
);
```

The tool definition format is the same regardless of provider. FlAI converts it to the appropriate API format (OpenAI function-calling format or Anthropic tool_use format) internally.

### Handling Tool Results

After receiving a `ToolCallEnd` event, execute the tool and send the result back:

```dart
// After tool call completes, add the tool result to messages:
controller.addMessage(Message(
  id: 'tool_result_1',
  role: MessageRole.tool,
  content: '{"temperature": 72, "condition": "sunny"}',
  timestamp: DateTime.now(),
  toolCalls: [
    ToolCall(
      id: toolCallId,  // must match the tool call ID from the event
      name: 'get_weather',
      arguments: '{"city": "San Francisco"}',
    ),
  ],
));
```

## Vision (Image Input)

Both providers support image input through the `Attachment` model:

```dart
final message = Message(
  id: 'img_msg',
  role: MessageRole.user,
  content: 'What do you see in this image?',
  timestamp: DateTime.now(),
  attachments: [
    Attachment(
      id: 'img1',
      name: 'photo.jpg',
      mimeType: 'image/jpeg',
      url: 'https://example.com/photo.jpg',  // URL or base64 data URI
    ),
  ],
);
```

For Anthropic, both URL and base64 data URIs are supported:

```dart
Attachment(
  id: 'img1',
  name: 'screenshot.png',
  mimeType: 'image/png',
  url: 'data:image/png;base64,iVBORw0KGgo...',  // base64 data URI
)
```

## Cancellation

Both providers support cancellation by closing the underlying HTTP client:

```dart
// Via controller (recommended):
await controller.cancel();

// Via provider directly:
await provider.cancel();
```

When cancelled mid-stream, the `ChatScreenController` saves any partial response as a complete message so the user does not lose context.

## Error Handling

API errors are emitted as `ChatError` events in the stream. The `ChatScreenController` automatically:

1. Captures the error
2. Saves a message with `MessageStatus.error`
3. Renders a retry button on the message bubble

For the Anthropic provider, HTTP errors are wrapped in `AnthropicApiException` with the status code and response body.

```dart
try {
  await for (final event in provider.streamChat(request)) {
    if (event is ChatError) {
      final error = event.error;
      if (error is AnthropicApiException) {
        print('Status: ${error.statusCode}');
        print('Message: ${error.message}');
      }
    }
  }
} catch (e) {
  // Network-level errors
}
```

## Security: API Key Management

Never hardcode API keys in source code. Use `--dart-define` for development:

```bash
flutter run \
  --dart-define=OPENAI_API_KEY=sk-... \
  --dart-define=ANTHROPIC_API_KEY=sk-ant-...
```

For production, use a backend proxy to avoid exposing API keys in client apps:

```dart
final provider = OpenAiProvider(
  apiKey: 'not-needed-if-proxy-handles-auth',
  baseUrl: 'https://your-backend.com/api/ai',
);
```
