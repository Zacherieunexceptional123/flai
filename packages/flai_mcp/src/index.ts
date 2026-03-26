#!/usr/bin/env node

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

// ---------------------------------------------------------------------------
// Component Registry
// ---------------------------------------------------------------------------

interface ComponentInfo {
  name: string;
  description: string;
  category: string;
  dependencies: string[];
  pubDependencies: string[];
  props: Record<string, string>;
  usageExample: string;
}

const CATEGORIES = {
  CHAT_ESSENTIALS: "Chat Essentials",
  AI_WIDGETS: "AI Widgets",
  CONVERSATION: "Conversation",
  PROVIDERS: "Providers",
} as const;

const COMPONENT_REGISTRY: Record<string, ComponentInfo> = {
  // ── Chat Essentials ─────────────────────────────────────────────────────
  chat_screen: {
    name: "chat_screen",
    description:
      "Full-page AI chat screen composing message bubbles, input bar, streaming text, and typing indicator into a complete chat experience. Connects to a ChatScreenController for state management and AI provider interaction.",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: ["message_bubble", "input_bar", "streaming_text"],
    pubDependencies: [],
    props: {
      controller: "ChatScreenController — manages chat state and AI interaction",
      title: "String? — title displayed in the header",
      subtitle: "String? — subtitle below the title (e.g., model name)",
      leading: "Widget? — optional leading widget in the header (e.g., avatar)",
      actions: "List<Widget>? — trailing widgets in the header",
      onTapCitation: "Function(Citation)? — called when a citation is tapped",
      onLongPress: "Function(Message)? — called when a message is long-pressed",
      onAttachmentTap: "VoidCallback? — called when attachment button is tapped",
      showHeader: "bool — whether to show the header bar (default: true)",
      inputPlaceholder: "String — placeholder text for the input field",
      emptyState: "Widget? — widget to display when there are no messages",
    },
    usageExample: `final controller = ChatScreenController(provider: myAiProvider);

FlaiChatScreen(
  controller: controller,
  title: 'AI Assistant',
  subtitle: 'Claude 3.5 Sonnet',
  onAttachmentTap: () => pickImage(),
)`,
  },

  message_bubble: {
    name: "message_bubble",
    description:
      "Chat message bubble that renders user, assistant, system, and tool messages with distinct styling. Supports thinking blocks, tool call chips, citation cards, streaming cursors, and error retry actions.",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: [],
    pubDependencies: ["flutter_markdown"],
    props: {
      message: "Message — the message to display (required)",
      onTapCitation: "Function(Citation)? — called when a citation is tapped",
      onRetry: "Function(Message)? — called when retry button is tapped on an error message",
      onLongPress: "Function(Message)? — called when the bubble is long-pressed",
    },
    usageExample: `MessageBubble(
  message: Message(
    id: '1',
    role: MessageRole.assistant,
    content: 'Hello! How can I help you today?',
    status: MessageStatus.complete,
  ),
  onTapCitation: (citation) => launchUrl(citation.url),
  onRetry: (msg) => controller.retry(msg),
)`,
  },

  input_bar: {
    name: "input_bar",
    description:
      "Production-quality chat input bar with text field, send button, and optional attachment support. Supports multi-line input with dynamic height growth, Enter-to-send on desktop/web, and SafeArea bottom padding.",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: [],
    pubDependencies: [],
    props: {
      onSend: "ValueChanged<String> — called when the user submits a message (required)",
      onAttachmentTap: "VoidCallback? — called when attachment button is tapped; hidden if null",
      onTextChanged: "ValueChanged<String>? — called when text field content changes",
      placeholder: "String — hint text when field is empty (default: 'Message...')",
      enabled: "bool — whether the input bar is interactive (default: true)",
      maxLines: "int — max visible text lines before scrolling (default: 5)",
      autofocus: "bool — whether to autofocus on build (default: false)",
    },
    usageExample: `FlaiInputBar(
  onSend: (text) => controller.sendMessage(text),
  onAttachmentTap: () => pickFile(),
  placeholder: 'Ask anything...',
)`,
  },

  streaming_text: {
    name: "streaming_text",
    description:
      "Widget that renders text being streamed token-by-token from an AI provider, with an animated blinking cursor. Supports two modes: stream-driven (accepts a Stream<String> of deltas) and text-driven (accepts a changing String).",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: [],
    pubDependencies: [],
    props: {
      text: "String? — current text to display (text-driven mode)",
      stream: "Stream<String>? — stream of text deltas (stream-driven mode)",
      isStreaming: "bool — whether streaming is active (text-driven mode, default: false)",
      style: "TextStyle? — text style for the rendered text",
      showCursor: "bool — whether to show the blinking cursor while streaming",
      cursorColor: "Color? — override color for the cursor",
    },
    usageExample: `// Stream-driven mode
FlaiStreamingText.fromStream(
  stream: aiProvider.streamChat(request)
      .whereType<TextDelta>()
      .map((e) => e.text),
  style: theme.typography.bodyBase(color: theme.colors.foreground),
)

// Text-driven mode
FlaiStreamingText(
  text: controller.currentText,
  isStreaming: controller.isStreaming,
)`,
  },

  typing_indicator: {
    name: "typing_indicator",
    description:
      "Animated three-dot typing indicator showing the AI is generating a response. Styled as an assistant bubble (left-aligned) with each dot bouncing with a staggered delay, creating a wave-like animation.",
    category: CATEGORIES.CHAT_ESSENTIALS,
    dependencies: [],
    pubDependencies: [],
    props: {
      dotSize: "double — diameter of each dot (default: 7.0)",
      dotColor: "Color? — override color for dots; defaults to FlaiColors.mutedForeground",
      bounceHeight: "double — how far each dot bounces upward in logical pixels (default: 6.0)",
    },
    usageExample: `FlaiTypingIndicator(
  dotSize: 8.0,
  bounceHeight: 7.0,
)`,
  },

  // ── AI Widgets ──────────────────────────────────────────────────────────
  tool_call_card: {
    name: "tool_call_card",
    description:
      "Card displaying an AI tool/function call with its name, arguments, result, and loading state. Shows a wrench icon and tool name in the header, parsed JSON arguments in mono-font, and the result once available.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: [],
    props: {
      toolCall: "ToolCall — the tool call data to display (required)",
      onTap: "VoidCallback? — called when the card is tapped",
    },
    usageExample: `FlaiToolCallCard(
  toolCall: ToolCall(
    id: 'call_1',
    name: 'search_web',
    arguments: '{"query": "Flutter AI components"}',
    result: '3 results found...',
    isComplete: true,
  ),
  onTap: () => showToolDetails(),
)`,
  },

  code_block: {
    name: "code_block",
    description:
      "Styled code block with a language label, optional line numbers, horizontal scrolling, and a copy-to-clipboard button. Uses mono font styling from FlaiTheme and a muted background.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: ["flutter_highlight"],
    props: {
      code: "String — the source code to display (required)",
      language: "String? — language identifier shown in the header (e.g. 'dart', 'json')",
      showLineNumbers: "bool — whether to show line numbers (default: false)",
      onCopy: "VoidCallback? — called after the code is copied to clipboard",
    },
    usageExample: `FlaiCodeBlock(
  code: '''
void main() {
  runApp(MyApp());
}
''',
  language: 'dart',
  showLineNumbers: true,
)`,
  },

  thinking_indicator: {
    name: "thinking_indicator",
    description:
      "Expandable panel showing the AI's reasoning/thinking process with a shimmer animation. When isThinking is true, the label pulses with a shimmer effect. Tapping the header toggles between collapsed and expanded states.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: [],
    props: {
      thinkingText: "String — the raw thinking/reasoning text (required)",
      isThinking: "bool — whether the model is still actively thinking (default: false)",
      label: "String — display label in the header row (default: 'Thinking...')",
      initiallyExpanded: "bool — if true, starts in expanded state (default: false)",
    },
    usageExample: `FlaiThinkingIndicator(
  thinkingText: 'Let me analyze this step by step...',
  isThinking: true,
  label: 'Reasoning',
  initiallyExpanded: false,
)`,
  },

  citation_card: {
    name: "citation_card",
    description:
      "Compact inline citation card displaying a source reference with title and optional snippet. Shows a link icon and title in bold. Tapping invokes onTap with the Citation object.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: [],
    props: {
      citation: "Citation — the citation data to display (required)",
      onTap: "Function(Citation)? — called when the card is tapped",
    },
    usageExample: `FlaiCitationCard(
  citation: Citation(
    title: 'Flutter Documentation',
    url: 'https://docs.flutter.dev',
    snippet: 'Official Flutter documentation and API reference.',
  ),
  onTap: (c) => launchUrl(Uri.parse(c.url!)),
)`,
  },

  image_preview: {
    name: "image_preview",
    description:
      "Image preview thumbnail that loads from a URL, displays a shimmer placeholder while loading, shows a broken-image icon on error, and opens a full-screen interactive viewer dialog on tap.",
    category: CATEGORIES.AI_WIDGETS,
    dependencies: [],
    pubDependencies: [],
    props: {
      imageUrl: "String — network URL of the image (required)",
      alt: "String? — alt text shown as tooltip and dialog title",
      width: "double? — constrained thumbnail width (default: 200)",
      height: "double? — constrained thumbnail height (default: 200)",
      onTap: "VoidCallback? — overrides default tap behavior (full-screen dialog)",
    },
    usageExample: `FlaiImagePreview(
  imageUrl: 'https://example.com/diagram.png',
  alt: 'Architecture Diagram',
  width: 300,
  height: 200,
)`,
  },

  // ── Conversation ────────────────────────────────────────────────────────
  conversation_list: {
    name: "conversation_list",
    description:
      "Scrollable list of past conversations with search filtering, selection highlighting, swipe-to-delete, and an empty state. Includes a search bar and new conversation button.",
    category: CATEGORIES.CONVERSATION,
    dependencies: [],
    pubDependencies: [],
    props: {
      conversations: "List<Conversation> — the conversations to display (required)",
      selectedId: "String? — currently selected conversation id",
      onSelect: "Function(Conversation)? — called when a conversation is tapped",
      onDelete: "Function(Conversation)? — called when a conversation is swiped away",
      onCreate: "VoidCallback? — called when 'New Conversation' button is tapped",
      searchPlaceholder: "String — placeholder text in the search bar",
    },
    usageExample: `FlaiConversationList(
  conversations: conversations,
  selectedId: currentConversation?.id,
  onSelect: (conv) => loadConversation(conv),
  onDelete: (conv) => deleteConversation(conv),
  onCreate: () => createNewConversation(),
)`,
  },

  model_selector: {
    name: "model_selector",
    description:
      "Compact chip showing the currently selected AI model that opens a bottom sheet picker. Displays provider badges and capability tags for each model option.",
    category: CATEGORIES.CONVERSATION,
    dependencies: [],
    pubDependencies: [],
    props: {
      models: "List<FlaiModelOption> — all available models (required)",
      selectedModelId: "String? — id of the currently selected model",
      onSelect: "Function(FlaiModelOption)? — called when the user picks a model",
    },
    usageExample: `FlaiModelSelector(
  models: [
    FlaiModelOption(
      id: 'claude-sonnet-4-20250514',
      name: 'Claude Sonnet 4',
      provider: 'Anthropic',
      contextWindow: 200000,
      capabilities: ['vision', 'tool_use', 'thinking'],
    ),
    FlaiModelOption(
      id: 'gpt-4o',
      name: 'GPT-4o',
      provider: 'OpenAI',
      contextWindow: 128000,
      capabilities: ['vision', 'tool_use'],
    ),
  ],
  selectedModelId: 'claude-sonnet-4-20250514',
  onSelect: (model) => switchModel(model),
)`,
  },

  token_usage: {
    name: "token_usage",
    description:
      "Widget displaying token usage statistics with optional cost estimation and a progress bar showing utilisation against a maximum token limit. Supports compact and expanded views.",
    category: CATEGORIES.CONVERSATION,
    dependencies: [],
    pubDependencies: [],
    props: {
      usage: "UsageInfo — token usage data: input, output, cache tokens, total (required)",
      costPerInputToken: "double? — cost per input token in dollars",
      costPerOutputToken: "double? — cost per output token in dollars",
      maxTokens: "int? — maximum token limit; shows a progress bar when provided",
      expanded: "bool — whether to show the expanded breakdown view (default: false)",
    },
    usageExample: `FlaiTokenUsage(
  usage: UsageInfo(inputTokens: 1250, outputTokens: 340),
  costPerInputToken: 0.000003,
  costPerOutputToken: 0.000015,
  maxTokens: 4096,
  expanded: true,
)`,
  },

  // ── Providers ───────────────────────────────────────────────────────────
  openai_provider: {
    name: "openai_provider",
    description:
      "OpenAI API provider implementing the AiProvider interface with streaming, tool use, and vision support. Uses raw HTTP requests to the Chat Completions API.",
    category: CATEGORIES.PROVIDERS,
    dependencies: [],
    pubDependencies: ["http"],
    props: {
      apiKey: "String — required for authentication",
      baseUrl: "String? — defaults to https://api.openai.com/v1",
      model: "String — defaults to 'gpt-4o'",
      organization: "String? — optional OpenAI-Organization header",
    },
    usageExample: `final provider = OpenAiProvider(
  apiKey: 'sk-...',
  model: 'gpt-4o',
);

final stream = provider.streamChat(ChatRequest(
  messages: [Message(role: MessageRole.user, content: 'Hello!')],
));

await for (final event in stream) {
  // Handle ChatEvent (TextDelta, ToolCallDelta, Done, Error, etc.)
}`,
  },

  anthropic_provider: {
    name: "anthropic_provider",
    description:
      "Anthropic Messages API provider implementing the AiProvider interface with streaming, tool use, extended thinking, and vision support. Uses raw HTTP requests to the Messages API.",
    category: CATEGORIES.PROVIDERS,
    dependencies: [],
    pubDependencies: ["http"],
    props: {
      apiKey: "String — required for authentication",
      baseUrl: "String — defaults to https://api.anthropic.com",
      model: "String — defaults to 'claude-sonnet-4-20250514'",
      anthropicVersion: "String — API version header (default: '2023-06-01')",
      thinkingBudgetTokens: "int? — optional thinking budget for extended thinking",
    },
    usageExample: `final provider = AnthropicProvider(
  apiKey: 'sk-ant-...',
  model: 'claude-sonnet-4-20250514',
  thinkingBudgetTokens: 10000,
);

final stream = provider.streamChat(ChatRequest(
  messages: [Message(role: MessageRole.user, content: 'Hello!')],
));

await for (final event in stream) {
  // Handle ChatEvent (TextDelta, ThinkingDelta, ToolCallDelta, etc.)
}`,
  },
};

// ---------------------------------------------------------------------------
// Theme Information
// ---------------------------------------------------------------------------

const THEME_INFO = {
  overview:
    "FlAI uses a custom InheritedWidget-based theme system (FlaiTheme) that provides design tokens for colors, typography, radius, and spacing. All components read tokens exclusively via FlaiTheme.of(context) — no hardcoded values.",
  presets: [
    {
      name: "Light (Zinc)",
      factory: "FlaiThemeData.light()",
      description:
        "Clean light theme with zinc-based neutral palette. The default theme, inspired by shadcn/ui's zinc color scheme.",
    },
    {
      name: "Dark",
      factory: "FlaiThemeData.dark()",
      description:
        "Dark mode theme with inverted zinc palette. High contrast foreground on dark backgrounds.",
    },
    {
      name: "iOS",
      factory: "FlaiThemeData.ios()",
      description:
        "Apple-style theme with iOS blue accent, rounded corners (sm: 8, md: 12, lg: 18, xl: 22), and system font styling.",
    },
    {
      name: "Premium (Linear-inspired)",
      factory: "FlaiThemeData.premium()",
      description:
        "Premium dark theme inspired by Linear's design system. Subtle gradients and refined spacing for a polished look.",
    },
  ],
  tokens: {
    colors:
      "FlaiColors — background, foreground, card, cardForeground, primary, primaryForeground, secondary, secondaryForeground, muted, mutedForeground, accent, accentForeground, destructive, destructiveForeground, border, input, ring",
    typography:
      "FlaiTypography — bodyBase(), bodySmall(), heading(), label(), mono() methods that return TextStyle",
    radius: "FlaiRadius — sm, md, lg, xl, full (double values for BorderRadius)",
    spacing: "FlaiSpacing — xs, sm, md, lg, xl (double values for padding/margin)",
  },
  customization: `// Wrap your widget tree with FlaiTheme
FlaiTheme(
  data: FlaiThemeData.dark(),
  child: MaterialApp(home: MyHomePage()),
)

// Custom theme
FlaiTheme(
  data: FlaiThemeData(
    colors: FlaiColors.dark().copyWith(
      primary: Color(0xFF6366F1),
      accent: Color(0xFF8B5CF6),
    ),
    radius: FlaiRadius(sm: 4, md: 8, lg: 12, xl: 16, full: 9999),
  ),
  child: MaterialApp(home: MyHomePage()),
)

// Access tokens in any widget
final theme = FlaiTheme.of(context);
Container(
  color: theme.colors.card,
  padding: EdgeInsets.all(theme.spacing.md),
  child: Text('Hello', style: theme.typography.bodyBase(
    color: theme.colors.foreground,
  )),
)`,
};

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const CATEGORY_ORDER = [
  CATEGORIES.CHAT_ESSENTIALS,
  CATEGORIES.AI_WIDGETS,
  CATEGORIES.CONVERSATION,
  CATEGORIES.PROVIDERS,
];

function componentsByCategory(): Record<string, ComponentInfo[]> {
  const grouped: Record<string, ComponentInfo[]> = {};
  for (const cat of CATEGORY_ORDER) {
    grouped[cat] = [];
  }
  for (const comp of Object.values(COMPONENT_REGISTRY)) {
    if (!grouped[comp.category]) {
      grouped[comp.category] = [];
    }
    grouped[comp.category].push(comp);
  }
  return grouped;
}

function formatComponentList(): string {
  const grouped = componentsByCategory();
  const lines: string[] = [
    "# FlAI Components",
    "",
    `${Object.keys(COMPONENT_REGISTRY).length} components available across ${CATEGORY_ORDER.length} categories.`,
    "",
  ];

  for (const category of CATEGORY_ORDER) {
    const components = grouped[category];
    if (!components || components.length === 0) continue;

    lines.push(`## ${category}`);
    lines.push("");
    for (const comp of components) {
      const deps =
        comp.dependencies.length > 0
          ? ` (depends on: ${comp.dependencies.join(", ")})`
          : "";
      const pubDeps =
        comp.pubDependencies.length > 0
          ? ` [pub: ${comp.pubDependencies.join(", ")}]`
          : "";
      lines.push(`- **${comp.name}** — ${comp.description}${deps}${pubDeps}`);
    }
    lines.push("");
  }

  lines.push("---");
  lines.push(
    "Use `add_component` to install any component, or `get_component_info` for detailed API docs."
  );

  return lines.join("\n");
}

function formatComponentInfo(comp: ComponentInfo): string {
  const lines: string[] = [
    `# ${comp.name}`,
    "",
    comp.description,
    "",
    `**Category:** ${comp.category}`,
  ];

  if (comp.dependencies.length > 0) {
    lines.push(
      `**FlAI Dependencies:** ${comp.dependencies.join(", ")} (auto-installed)`
    );
  }

  if (comp.pubDependencies.length > 0) {
    lines.push(
      `**Pub Dependencies:** ${comp.pubDependencies.join(", ")} (auto-added to pubspec.yaml)`
    );
  }

  lines.push("");
  lines.push("## Props");
  lines.push("");
  for (const [prop, desc] of Object.entries(comp.props)) {
    lines.push(`- \`${prop}\`: ${desc}`);
  }

  lines.push("");
  lines.push("## Usage");
  lines.push("");
  lines.push("```dart");
  lines.push(comp.usageExample);
  lines.push("```");

  lines.push("");
  lines.push("## Install");
  lines.push("");
  lines.push("```bash");
  lines.push(`flai add ${comp.name}`);
  lines.push("```");

  return lines.join("\n");
}

async function runFlaiCommand(
  command: string,
  projectPath?: string
): Promise<{ stdout: string; stderr: string; exitCode: number }> {
  const cwd = projectPath || process.cwd();
  try {
    const { stdout, stderr } = await execAsync(`flai ${command}`, {
      cwd,
      timeout: 60_000,
    });
    return { stdout, stderr, exitCode: 0 };
  } catch (error: unknown) {
    const execError = error as {
      stdout?: string;
      stderr?: string;
      code?: number;
    };
    return {
      stdout: execError.stdout ?? "",
      stderr: execError.stderr ?? String(error),
      exitCode: execError.code ?? 1,
    };
  }
}

// ---------------------------------------------------------------------------
// MCP Server
// ---------------------------------------------------------------------------

const server = new McpServer({
  name: "flai",
  version: "0.1.0",
});

// ── Tool: list_components ─────────────────────────────────────────────────

server.tool(
  "list_components",
  "Lists all available FlAI components with descriptions and categories. Returns the full component registry (15 components) grouped by category: Chat Essentials, AI Widgets, Conversation, and Providers.",
  {},
  async () => {
    return {
      content: [{ type: "text", text: formatComponentList() }],
    };
  }
);

// ── Tool: add_component ───────────────────────────────────────────────────

server.tool(
  "add_component",
  "Installs a FlAI component into a Flutter project. Validates the component exists, resolves dependencies, and runs `flai add <name>`. Requires FlAI CLI to be installed and the project to be initialized with `flai init`.",
  {
    component_name: z
      .string()
      .describe("Name of the component to install (e.g., 'message_bubble', 'chat_screen')"),
    project_path: z
      .string()
      .optional()
      .describe(
        "Absolute path to the Flutter project. Defaults to the current working directory."
      ),
  },
  async ({ component_name, project_path }) => {
    // Validate component exists
    const comp = COMPONENT_REGISTRY[component_name];
    if (!comp) {
      const available = Object.keys(COMPONENT_REGISTRY).join(", ");
      return {
        content: [
          {
            type: "text",
            text: `Error: Unknown component "${component_name}".\n\nAvailable components: ${available}`,
          },
        ],
        isError: true,
      };
    }

    // Show what will be installed
    const installPlan: string[] = [
      `Installing: ${comp.name}`,
      `Category: ${comp.category}`,
    ];

    if (comp.dependencies.length > 0) {
      installPlan.push(
        `FlAI dependencies (auto-installed): ${comp.dependencies.join(", ")}`
      );
    }
    if (comp.pubDependencies.length > 0) {
      installPlan.push(
        `Pub dependencies (auto-added): ${comp.pubDependencies.join(", ")}`
      );
    }

    installPlan.push("", "Running `flai add " + component_name + "`...", "");

    // Run the CLI command
    const result = await runFlaiCommand(`add ${component_name}`, project_path);

    if (result.exitCode !== 0) {
      installPlan.push("Installation failed:");
      if (result.stderr) installPlan.push(result.stderr);
      if (result.stdout) installPlan.push(result.stdout);
      installPlan.push(
        "",
        "Troubleshooting:",
        "- Make sure `flai` CLI is installed: `dart pub global activate flai_cli`",
        "- Make sure the project is initialized: run `flai init` first",
        "- Make sure you're in a Flutter project directory (has pubspec.yaml)"
      );
      return {
        content: [{ type: "text", text: installPlan.join("\n") }],
        isError: true,
      };
    }

    installPlan.push("Installation successful!");
    if (result.stdout) installPlan.push("", result.stdout.trim());

    return {
      content: [{ type: "text", text: installPlan.join("\n") }],
    };
  }
);

// ── Tool: get_component_info ──────────────────────────────────────────────

server.tool(
  "get_component_info",
  "Gets detailed information about a specific FlAI component including description, category, dependencies, pub dependencies, all props with types, and a usage code example.",
  {
    component_name: z
      .string()
      .describe("Name of the component (e.g., 'message_bubble', 'chat_screen')"),
  },
  async ({ component_name }) => {
    const comp = COMPONENT_REGISTRY[component_name];
    if (!comp) {
      const available = Object.keys(COMPONENT_REGISTRY).join(", ");
      return {
        content: [
          {
            type: "text",
            text: `Error: Unknown component "${component_name}".\n\nAvailable components: ${available}`,
          },
        ],
        isError: true,
      };
    }

    return {
      content: [{ type: "text", text: formatComponentInfo(comp) }],
    };
  }
);

// ── Tool: init_project ────────────────────────────────────────────────────

server.tool(
  "init_project",
  "Initializes FlAI in a Flutter project. Runs `flai init` which sets up the core theme system (FlaiTheme, FlaiColors, FlaiTypography, FlaiRadius, FlaiSpacing), data models (Message, Conversation, ChatEvent, ChatRequest), and the AiProvider interface.",
  {
    project_path: z
      .string()
      .optional()
      .describe(
        "Absolute path to the Flutter project. Defaults to the current working directory."
      ),
  },
  async ({ project_path }) => {
    const lines: string[] = [
      "Initializing FlAI...",
      "",
      "This will create:",
      "- lib/flai/core/theme/ — FlaiTheme, FlaiColors, FlaiTypography, FlaiRadius, FlaiSpacing",
      "- lib/flai/core/models/ — Message, Conversation, ChatEvent, ChatRequest, UsageInfo, ToolCall, Citation",
      "- lib/flai/providers/ — AiProvider abstract interface",
      "- lib/flai/flai.dart — barrel export file",
      "",
      "Running `flai init`...",
      "",
    ];

    const result = await runFlaiCommand("init", project_path);

    if (result.exitCode !== 0) {
      lines.push("Initialization failed:");
      if (result.stderr) lines.push(result.stderr);
      if (result.stdout) lines.push(result.stdout);
      lines.push(
        "",
        "Troubleshooting:",
        "- Make sure `flai` CLI is installed: `dart pub global activate flai_cli`",
        "- Make sure you're in a Flutter project directory (has pubspec.yaml)",
        "- Make sure the lib/ directory exists"
      );
      return {
        content: [{ type: "text", text: lines.join("\n") }],
        isError: true,
      };
    }

    lines.push("Initialization successful!");
    if (result.stdout) lines.push("", result.stdout.trim());
    lines.push(
      "",
      "Next steps:",
      "1. Wrap your app with FlaiTheme:",
      "   ```dart",
      "   FlaiTheme(",
      "     data: FlaiThemeData.light(),",
      "     child: MaterialApp(home: MyHomePage()),",
      "   )",
      "   ```",
      "2. Install components: `flai add message_bubble`, `flai add chat_screen`, etc.",
      '3. Or use `list_components` to see all available components.'
    );

    return {
      content: [{ type: "text", text: lines.join("\n") }],
    };
  }
);

// ── Tool: doctor ──────────────────────────────────────────────────────────

server.tool(
  "doctor",
  "Checks the health of a FlAI project. Runs `flai doctor` to verify FlAI is properly initialized, check installed components, validate dependencies, and identify any issues.",
  {
    project_path: z
      .string()
      .optional()
      .describe(
        "Absolute path to the Flutter project. Defaults to the current working directory."
      ),
  },
  async ({ project_path }) => {
    const lines: string[] = [
      "Running FlAI health check...",
      "",
    ];

    const result = await runFlaiCommand("doctor", project_path);

    if (result.exitCode !== 0) {
      lines.push("Health check encountered issues:");
      if (result.stdout) lines.push(result.stdout.trim());
      if (result.stderr) lines.push(result.stderr.trim());
      lines.push(
        "",
        "Common fixes:",
        "- Run `flai init` to initialize the project",
        "- Run `flutter pub get` to resolve dependencies",
        "- Make sure `flai` CLI is installed: `dart pub global activate flai_cli`"
      );
      return {
        content: [{ type: "text", text: lines.join("\n") }],
        isError: true,
      };
    }

    lines.push("Health check results:");
    lines.push("");
    if (result.stdout) lines.push(result.stdout.trim());

    return {
      content: [{ type: "text", text: lines.join("\n") }],
    };
  }
);

// ── Tool: get_theme_info ──────────────────────────────────────────────────

server.tool(
  "get_theme_info",
  "Gets detailed theming information for FlAI including the 4 theme presets (Light/Zinc, Dark, iOS, Premium/Linear), all design tokens (colors, typography, radius, spacing), and customization examples.",
  {},
  async () => {
    const lines: string[] = [
      "# FlAI Theme System",
      "",
      THEME_INFO.overview,
      "",
      "## Theme Presets",
      "",
    ];

    for (const preset of THEME_INFO.presets) {
      lines.push(`### ${preset.name}`);
      lines.push(`- Factory: \`${preset.factory}\``);
      lines.push(`- ${preset.description}`);
      lines.push("");
    }

    lines.push("## Design Tokens");
    lines.push("");
    for (const [token, desc] of Object.entries(THEME_INFO.tokens)) {
      lines.push(`### ${token}`);
      lines.push(desc);
      lines.push("");
    }

    lines.push("## Customization");
    lines.push("");
    lines.push("```dart");
    lines.push(THEME_INFO.customization);
    lines.push("```");

    return {
      content: [{ type: "text", text: lines.join("\n") }],
    };
  }
);

// ---------------------------------------------------------------------------
// Start Server
// ---------------------------------------------------------------------------

async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error: unknown) => {
  console.error("FlAI MCP server failed to start:", error);
  process.exit(1);
});
