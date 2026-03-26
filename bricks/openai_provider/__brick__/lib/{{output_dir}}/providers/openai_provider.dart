import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models/chat_event.dart';
import '../core/models/chat_request.dart';
import '../core/models/message.dart';
import 'ai_provider.dart';

/// OpenAI API provider implementing [AiProvider] with streaming,
/// tool use, and vision support using raw HTTP requests.
class OpenAiProvider implements AiProvider {
  /// Creates an [OpenAiProvider].
  ///
  /// [apiKey] is required for authentication.
  /// [baseUrl] defaults to the OpenAI API endpoint.
  /// [model] defaults to `gpt-4o`.
  /// [organization] is optional and sent as the `OpenAI-Organization` header.
  OpenAiProvider({
    required String apiKey,
    String? baseUrl,
    String model = 'gpt-4o',
    String? organization,
  })  : _apiKey = apiKey,
        _baseUrl = (baseUrl ?? 'https://api.openai.com/v1').replaceAll(
          RegExp(r'/+$'),
          '',
        ),
        _model = model,
        _organization = organization;

  final String _apiKey;
  final String _baseUrl;
  final String _model;
  final String? _organization;

  http.Client? _activeClient;

  // ---------------------------------------------------------------------------
  // AiProvider capabilities
  // ---------------------------------------------------------------------------

  @override
  bool get supportsToolUse => true;

  @override
  bool get supportsVision => true;

  @override
  bool get supportsStreaming => true;

  @override
  bool get supportsThinking => false;

  // ---------------------------------------------------------------------------
  // streamChat
  // ---------------------------------------------------------------------------

  @override
  Stream<ChatEvent> streamChat(ChatRequest request) async* {
    final client = http.Client();
    _activeClient = client;

    try {
      final body = _buildRequestBody(request, stream: true);
      final httpRequest = http.Request('POST', Uri.parse('$_baseUrl/chat/completions'));
      httpRequest.headers.addAll(_headers);
      httpRequest.body = jsonEncode(body);

      final response = await client.send(httpRequest);

      if (response.statusCode != 200) {
        final errorBody = await response.stream.bytesToString();
        yield ChatError(
          'OpenAI API error ${response.statusCode}: $errorBody',
        );
        return;
      }

      final fullTextBuffer = StringBuffer();
      // Track active tool calls for accumulating argument deltas.
      final activeToolCalls = <int, _ToolCallAccumulator>{};

      await for (final chunk in _parseSseStream(response.stream)) {
        final choices = chunk['choices'] as List<dynamic>?;

        if (choices != null && choices.isNotEmpty) {
          final choice = choices[0] as Map<String, dynamic>;
          final delta = choice['delta'] as Map<String, dynamic>?;
          final finishReason = choice['finish_reason'] as String?;

          if (delta != null) {
            // --- Text content ---
            final content = delta['content'] as String?;
            if (content != null && content.isNotEmpty) {
              fullTextBuffer.write(content);
              yield TextDelta(content);
            }

            // --- Tool calls ---
            final toolCalls = delta['tool_calls'] as List<dynamic>?;
            if (toolCalls != null) {
              for (final tc in toolCalls) {
                final tcMap = tc as Map<String, dynamic>;
                final index = tcMap['index'] as int;
                final function = tcMap['function'] as Map<String, dynamic>?;

                if (!activeToolCalls.containsKey(index)) {
                  // New tool call — emit ToolCallStart.
                  final id = tcMap['id'] as String? ?? 'call_$index';
                  final name = function?['name'] as String? ?? '';
                  activeToolCalls[index] = _ToolCallAccumulator(id: id, name: name);
                  yield ToolCallStart(id: id, name: name);
                }

                final argDelta = function?['arguments'] as String?;
                if (argDelta != null && argDelta.isNotEmpty) {
                  final acc = activeToolCalls[index]!;
                  acc.argumentsBuffer.write(argDelta);
                  yield ToolCallDelta(id: acc.id, argumentsDelta: argDelta);
                }
              }
            }
          }

          // --- Finish reason ---
          if (finishReason == 'tool_calls') {
            for (final acc in activeToolCalls.values) {
              yield ToolCallEnd(id: acc.id);
            }
          } else if (finishReason == 'stop') {
            final text = fullTextBuffer.toString();
            if (text.isNotEmpty) {
              yield TextDone(text);
            }
          }
        }

        // --- Usage (often present in the final chunk) ---
        final usage = chunk['usage'] as Map<String, dynamic>?;
        if (usage != null) {
          yield UsageUpdate(
            inputTokens: usage['prompt_tokens'] as int? ?? 0,
            outputTokens: usage['completion_tokens'] as int? ?? 0,
            cacheReadTokens: usage['prompt_tokens_details'] != null
                ? (usage['prompt_tokens_details'] as Map<String, dynamic>)['cached_tokens'] as int?
                : null,
          );
        }
      }

      yield const ChatDone();
    } catch (e, st) {
      yield ChatError(e, st);
    } finally {
      _activeClient = null;
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // chat (non-streaming)
  // ---------------------------------------------------------------------------

  @override
  Future<ChatResponse> chat(ChatRequest request) async {
    final client = http.Client();
    _activeClient = client;

    try {
      final body = _buildRequestBody(request, stream: false);
      final response = await client.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('OpenAI API error ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final choice = (json['choices'] as List<dynamic>)[0] as Map<String, dynamic>;
      final messageJson = choice['message'] as Map<String, dynamic>;

      // Parse tool calls from the response.
      List<ToolCall>? toolCalls;
      final rawToolCalls = messageJson['tool_calls'] as List<dynamic>?;
      if (rawToolCalls != null && rawToolCalls.isNotEmpty) {
        toolCalls = rawToolCalls.map((tc) {
          final tcMap = tc as Map<String, dynamic>;
          final fn = tcMap['function'] as Map<String, dynamic>;
          return ToolCall(
            id: tcMap['id'] as String,
            name: fn['name'] as String,
            arguments: fn['arguments'] as String,
            isComplete: true,
          );
        }).toList();
      }

      final message = Message(
        id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        content: messageJson['content'] as String? ?? '',
        timestamp: DateTime.now(),
        toolCalls: toolCalls,
        status: MessageStatus.complete,
      );

      UsageInfo? usage;
      final usageJson = json['usage'] as Map<String, dynamic>?;
      if (usageJson != null) {
        usage = UsageInfo(
          inputTokens: usageJson['prompt_tokens'] as int? ?? 0,
          outputTokens: usageJson['completion_tokens'] as int? ?? 0,
          cacheReadTokens: usageJson['prompt_tokens_details'] != null
              ? (usageJson['prompt_tokens_details'] as Map<String, dynamic>)['cached_tokens'] as int?
              : null,
        );
      }

      return ChatResponse(message: message, usage: usage);
    } finally {
      _activeClient = null;
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // cancel
  // ---------------------------------------------------------------------------

  @override
  Future<void> cancel() async {
    _activeClient?.close();
    _activeClient = null;
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
        if (_organization != null) 'OpenAI-Organization': _organization!,
      };

  /// Builds the JSON request body for the OpenAI chat completions API.
  Map<String, dynamic> _buildRequestBody(
    ChatRequest request, {
    required bool stream,
  }) {
    final body = <String, dynamic>{
      'model': request.model ?? _model,
      'messages': request.messages.map(_convertMessage).toList(),
      'stream': stream,
    };

    if (stream) {
      // Request usage stats in the final streaming chunk.
      body['stream_options'] = {'include_usage': true};
    }

    if (request.temperature != null) {
      body['temperature'] = request.temperature;
    }
    if (request.maxTokens != null) {
      body['max_tokens'] = request.maxTokens;
    }

    if (request.tools != null && request.tools!.isNotEmpty) {
      body['tools'] = request.tools!.map(_convertTool).toList();
    }

    return body;
  }

  /// Converts a FlAI [Message] to the OpenAI message format.
  Map<String, dynamic> _convertMessage(Message message) {
    final role = switch (message.role) {
      MessageRole.user => 'user',
      MessageRole.assistant => 'assistant',
      MessageRole.system => 'system',
      MessageRole.tool => 'tool',
    };

    final msg = <String, dynamic>{'role': role};

    // --- Tool result messages ---
    if (message.role == MessageRole.tool) {
      msg['content'] = message.content;
      // OpenAI expects tool_call_id for tool result messages.
      if (message.toolCalls != null && message.toolCalls!.isNotEmpty) {
        msg['tool_call_id'] = message.toolCalls!.first.id;
      }
      return msg;
    }

    // --- Assistant messages with tool calls ---
    if (message.role == MessageRole.assistant && message.hasToolCalls) {
      msg['content'] = message.content.isEmpty ? null : message.content;
      msg['tool_calls'] = message.toolCalls!.map((tc) {
        return {
          'id': tc.id,
          'type': 'function',
          'function': {
            'name': tc.name,
            'arguments': tc.arguments,
          },
        };
      }).toList();
      return msg;
    }

    // --- Vision: user messages with image attachments ---
    if (message.role == MessageRole.user && message.hasAttachments) {
      final imageAttachments = message.attachments!
          .where((a) => a.mimeType.startsWith('image/'))
          .toList();

      if (imageAttachments.isNotEmpty) {
        final contentParts = <Map<String, dynamic>>[];

        // Add text content first if present.
        if (message.content.isNotEmpty) {
          contentParts.add({'type': 'text', 'text': message.content});
        }

        // Add each image attachment as an image_url content part.
        for (final attachment in imageAttachments) {
          if (attachment.url != null) {
            contentParts.add({
              'type': 'image_url',
              'image_url': {'url': attachment.url},
            });
          }
        }

        msg['content'] = contentParts;
        return msg;
      }
    }

    // --- Standard text message ---
    msg['content'] = message.content;
    return msg;
  }

  /// Converts a FlAI [ToolDefinition] to the OpenAI function-calling format.
  Map<String, dynamic> _convertTool(ToolDefinition tool) {
    return {
      'type': 'function',
      'function': {
        'name': tool.name,
        'description': tool.description,
        'parameters': tool.parameters,
      },
    };
  }

  /// Parses an SSE byte stream into decoded JSON objects.
  ///
  /// Each `data: ` line is extracted, `data: [DONE]` signals the end of the
  /// stream, and blank lines / comment lines are skipped.
  Stream<Map<String, dynamic>> _parseSseStream(
    Stream<List<int>> byteStream,
  ) async* {
    final lineBuffer = StringBuffer();

    await for (final bytes in byteStream) {
      lineBuffer.write(utf8.decode(bytes));
      final raw = lineBuffer.toString();
      final lines = raw.split('\n');

      // Keep the last (potentially incomplete) line in the buffer.
      lineBuffer.clear();
      lineBuffer.write(lines.removeLast());

      for (final line in lines) {
        final trimmed = line.trim();

        if (trimmed.isEmpty || trimmed.startsWith(':')) {
          continue;
        }

        if (trimmed == 'data: [DONE]') {
          return;
        }

        if (trimmed.startsWith('data: ')) {
          final jsonStr = trimmed.substring(6);
          try {
            final json = jsonDecode(jsonStr) as Map<String, dynamic>;
            yield json;
          } on FormatException {
            // Skip malformed JSON chunks.
          }
        }
      }
    }
  }
}

/// Internal helper to accumulate tool call arguments across streaming deltas.
class _ToolCallAccumulator {
  _ToolCallAccumulator({required this.id, required this.name});

  final String id;
  final String name;
  final StringBuffer argumentsBuffer = StringBuffer();
}
