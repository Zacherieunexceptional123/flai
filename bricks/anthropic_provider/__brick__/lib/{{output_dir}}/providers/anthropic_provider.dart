import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/chat_event.dart';
import '../core/models/chat_request.dart';
import '../core/models/message.dart';
import 'ai_provider.dart';

/// Anthropic Messages API provider implementing [AiProvider].
///
/// Uses raw HTTP calls to the Anthropic Messages API with support for
/// streaming, tool use, extended thinking, and vision.
class AnthropicProvider implements AiProvider {
  AnthropicProvider({
    required String apiKey,
    String baseUrl = 'https://api.anthropic.com',
    String model = 'claude-sonnet-4-20250514',
    String anthropicVersion = '2023-06-01',
    int? thinkingBudgetTokens,
  })  : _apiKey = apiKey,
        _baseUrl = baseUrl,
        _model = model,
        _anthropicVersion = anthropicVersion,
        _thinkingBudgetTokens = thinkingBudgetTokens;

  final String _apiKey;
  final String _baseUrl;
  final String _model;
  final String _anthropicVersion;
  final int? _thinkingBudgetTokens;

  http.Client? _client;

  @override
  bool get supportsToolUse => true;

  @override
  bool get supportsVision => true;

  @override
  bool get supportsStreaming => true;

  @override
  bool get supportsThinking => true;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  @override
  Stream<ChatEvent> streamChat(ChatRequest request) async* {
    final client = http.Client();
    _client = client;

    try {
      final body = _buildRequestBody(request, stream: true);
      final httpRequest = http.Request(
        'POST',
        Uri.parse('$_baseUrl/v1/messages'),
      );
      httpRequest.headers.addAll(_headers);
      httpRequest.body = jsonEncode(body);

      final response = await client.send(httpRequest);

      if (response.statusCode != 200) {
        final responseBody = await response.stream.bytesToString();
        yield ChatError(
          AnthropicApiException(
            statusCode: response.statusCode,
            message: responseBody,
          ),
        );
        return;
      }

      yield* _parseSseStream(response.stream);
    } catch (e, st) {
      yield ChatError(e, st);
    } finally {
      _client = null;
      client.close();
    }
  }

  @override
  Future<ChatResponse> chat(ChatRequest request) async {
    final client = http.Client();
    _client = client;

    try {
      final body = _buildRequestBody(request, stream: false);
      final response = await client.post(
        Uri.parse('$_baseUrl/v1/messages'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw AnthropicApiException(
          statusCode: response.statusCode,
          message: response.body,
        );
      }

      return _parseResponse(jsonDecode(response.body) as Map<String, dynamic>);
    } finally {
      _client = null;
      client.close();
    }
  }

  @override
  Future<void> cancel() async {
    _client?.close();
    _client = null;
  }

  // ---------------------------------------------------------------------------
  // Request building
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers => {
        'x-api-key': _apiKey,
        'anthropic-version': _anthropicVersion,
        'content-type': 'application/json',
      };

  Map<String, dynamic> _buildRequestBody(
    ChatRequest request, {
    required bool stream,
  }) {
    final model = request.model ?? _model;
    final maxTokens = request.maxTokens ?? 4096;

    // Extract system prompt from messages.
    final systemMessages = request.messages
        .where((m) => m.role == MessageRole.system)
        .toList();
    final nonSystemMessages = request.messages
        .where((m) => m.role != MessageRole.system)
        .toList();

    final body = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'messages': nonSystemMessages.map(_convertMessage).toList(),
      'stream': stream,
    };

    if (systemMessages.isNotEmpty) {
      body['system'] = systemMessages.map((m) => m.content).join('\n\n');
    }

    if (request.temperature != null) {
      body['temperature'] = request.temperature;
    }

    if (request.tools != null && request.tools!.isNotEmpty) {
      body['tools'] = request.tools!.map(_convertTool).toList();
    }

    if (_thinkingBudgetTokens != null) {
      body['thinking'] = {
        'type': 'enabled',
        'budget_tokens': _thinkingBudgetTokens,
      };
    }

    return body;
  }

  Map<String, dynamic> _convertMessage(Message message) {
    final role = message.role == MessageRole.tool ? 'user' : message.role.name;

    // Handle tool result messages.
    if (message.role == MessageRole.tool) {
      return {
        'role': 'user',
        'content': [
          {
            'type': 'tool_result',
            'tool_use_id': message.toolCalls?.firstOrNull?.id ?? message.id,
            'content': message.content,
          },
        ],
      };
    }

    // Handle messages with image attachments (vision).
    if (message.hasAttachments) {
      final contentParts = <Map<String, dynamic>>[];
      for (final attachment in message.attachments!) {
        if (_isImage(attachment.mimeType)) {
          if (attachment.url != null) {
            // If the URL is a data URI or base64, use source type base64.
            if (attachment.url!.startsWith('data:')) {
              final parts = attachment.url!.split(',');
              final base64Data = parts.length > 1 ? parts[1] : '';
              contentParts.add({
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': attachment.mimeType,
                  'data': base64Data,
                },
              });
            } else {
              contentParts.add({
                'type': 'image',
                'source': {
                  'type': 'url',
                  'url': attachment.url,
                },
              });
            }
          }
        }
      }
      if (message.content.isNotEmpty) {
        contentParts.add({'type': 'text', 'text': message.content});
      }
      return {'role': role, 'content': contentParts};
    }

    // Handle assistant messages with tool calls.
    if (message.role == MessageRole.assistant && message.hasToolCalls) {
      final contentParts = <Map<String, dynamic>>[];
      if (message.content.isNotEmpty) {
        contentParts.add({'type': 'text', 'text': message.content});
      }
      for (final toolCall in message.toolCalls!) {
        contentParts.add({
          'type': 'tool_use',
          'id': toolCall.id,
          'name': toolCall.name,
          'input': _tryParseJson(toolCall.arguments),
        });
      }
      return {'role': role, 'content': contentParts};
    }

    // Simple text message.
    return {'role': role, 'content': message.content};
  }

  Map<String, dynamic> _convertTool(ToolDefinition tool) {
    return {
      'name': tool.name,
      'description': tool.description,
      'input_schema': tool.parameters,
    };
  }

  // ---------------------------------------------------------------------------
  // SSE stream parsing
  // ---------------------------------------------------------------------------

  Stream<ChatEvent> _parseSseStream(Stream<List<int>> byteStream) async* {
    // Track state across content blocks.
    final textBuffer = StringBuffer();
    final blockTypes = <int, String>{};
    final toolCallIds = <int, String>{};
    final toolCallNames = <int, String>{};
    var currentBlockIndex = -1;

    // Accumulated usage across the stream.
    var inputTokens = 0;
    var outputTokens = 0;
    int? cacheReadTokens;
    int? cacheCreationTokens;

    await for (final line in _splitSseLines(byteStream)) {
      if (!line.startsWith('data: ')) continue;
      final jsonStr = line.substring(6).trim();
      if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

      Map<String, dynamic> event;
      try {
        event = jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }

      final type = event['type'] as String?;
      if (type == null) continue;

      switch (type) {
        case 'message_start':
          final message = event['message'] as Map<String, dynamic>?;
          final usage = message?['usage'] as Map<String, dynamic>?;
          if (usage != null) {
            inputTokens = (usage['input_tokens'] as num?)?.toInt() ?? 0;
            cacheReadTokens =
                (usage['cache_read_input_tokens'] as num?)?.toInt();
            cacheCreationTokens =
                (usage['cache_creation_input_tokens'] as num?)?.toInt();
          }

        case 'content_block_start':
          final index = (event['index'] as num?)?.toInt() ?? 0;
          currentBlockIndex = index;
          final block = event['content_block'] as Map<String, dynamic>?;
          final blockType = block?['type'] as String?;
          blockTypes[index] = blockType ?? 'text';

          switch (blockType) {
            case 'thinking':
              yield const ThinkingStart();
            case 'tool_use':
              final id = block?['id'] as String? ?? '';
              final name = block?['name'] as String? ?? '';
              toolCallIds[index] = id;
              toolCallNames[index] = name;
              yield ToolCallStart(id: id, name: name);
            case 'text':
              // Text accumulation starts; nothing to emit yet.
              break;
          }

        case 'content_block_delta':
          final index = (event['index'] as num?)?.toInt() ?? currentBlockIndex;
          final delta = event['delta'] as Map<String, dynamic>?;
          final deltaType = delta?['type'] as String?;

          switch (deltaType) {
            case 'text_delta':
              final text = delta?['text'] as String? ?? '';
              textBuffer.write(text);
              yield TextDelta(text);
            case 'thinking_delta':
              final text = delta?['thinking'] as String? ?? '';
              yield ThinkingDelta(text);
            case 'input_json_delta':
              final partial = delta?['partial_json'] as String? ?? '';
              final id = toolCallIds[index] ?? '';
              yield ToolCallDelta(id: id, argumentsDelta: partial);
          }

        case 'content_block_stop':
          final index = (event['index'] as num?)?.toInt() ?? currentBlockIndex;
          final blockType = blockTypes[index];
          switch (blockType) {
            case 'thinking':
              yield const ThinkingEnd();
            case 'tool_use':
              final id = toolCallIds[index] ?? '';
              yield ToolCallEnd(id: id);
            case 'text':
              yield TextDone(textBuffer.toString());
          }

        case 'message_delta':
          final usage = event['usage'] as Map<String, dynamic>?;
          if (usage != null) {
            outputTokens = (usage['output_tokens'] as num?)?.toInt() ?? 0;
          }
          yield UsageUpdate(
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheReadTokens: cacheReadTokens,
            cacheCreationTokens: cacheCreationTokens,
          );

        case 'message_stop':
          yield const ChatDone();

        case 'error':
          final error = event['error'] as Map<String, dynamic>?;
          final errorMsg = error?['message'] as String? ?? 'Unknown error';
          yield ChatError(AnthropicApiException(message: errorMsg));
      }
    }
  }

  /// Splits an HTTP byte stream into individual SSE lines.
  Stream<String> _splitSseLines(Stream<List<int>> byteStream) async* {
    final buffer = StringBuffer();
    await for (final chunk in byteStream.transform(utf8.decoder)) {
      buffer.write(chunk);
      final text = buffer.toString();
      final lines = text.split('\n');
      // Keep the last (potentially incomplete) segment in the buffer.
      buffer
        ..clear()
        ..write(lines.last);
      for (var i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isNotEmpty) {
          yield line;
        }
      }
    }
    // Flush remaining buffer.
    final remaining = buffer.toString().trim();
    if (remaining.isNotEmpty) {
      yield remaining;
    }
  }

  // ---------------------------------------------------------------------------
  // Non-streaming response parsing
  // ---------------------------------------------------------------------------

  ChatResponse _parseResponse(Map<String, dynamic> json) {
    final contentBlocks = json['content'] as List<dynamic>? ?? [];

    final textParts = <String>[];
    String? thinkingContent;
    final toolCalls = <ToolCall>[];

    for (final block in contentBlocks) {
      final blockMap = block as Map<String, dynamic>;
      final blockType = blockMap['type'] as String?;
      switch (blockType) {
        case 'text':
          textParts.add(blockMap['text'] as String? ?? '');
        case 'thinking':
          thinkingContent = blockMap['thinking'] as String? ?? '';
        case 'tool_use':
          toolCalls.add(
            ToolCall(
              id: blockMap['id'] as String? ?? '',
              name: blockMap['name'] as String? ?? '',
              arguments: jsonEncode(blockMap['input'] ?? {}),
            ),
          );
      }
    }

    final usage = json['usage'] as Map<String, dynamic>?;
    final usageInfo = usage != null
        ? UsageInfo(
            inputTokens: (usage['input_tokens'] as num?)?.toInt() ?? 0,
            outputTokens: (usage['output_tokens'] as num?)?.toInt() ?? 0,
            cacheReadTokens:
                (usage['cache_read_input_tokens'] as num?)?.toInt(),
            cacheCreationTokens:
                (usage['cache_creation_input_tokens'] as num?)?.toInt(),
          )
        : null;

    final message = Message(
      id: json['id'] as String? ?? '',
      role: MessageRole.assistant,
      content: textParts.join(),
      timestamp: DateTime.now(),
      toolCalls: toolCalls.isNotEmpty ? toolCalls : null,
      thinkingContent: thinkingContent,
      status: MessageStatus.complete,
      usage: usageInfo,
    );

    return ChatResponse(message: message, usage: usageInfo);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  bool _isImage(String mimeType) {
    return mimeType.startsWith('image/');
  }

  dynamic _tryParseJson(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }
}

/// Exception thrown when the Anthropic API returns an error.
class AnthropicApiException implements Exception {
  final int? statusCode;
  final String message;

  const AnthropicApiException({this.statusCode, required this.message});

  @override
  String toString() {
    if (statusCode != null) {
      return 'AnthropicApiException($statusCode): $message';
    }
    return 'AnthropicApiException: $message';
  }
}
