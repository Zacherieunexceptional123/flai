# @getflai/mcp

MCP (Model Context Protocol) server for [FlAI](https://getflai.dev) -- AI chat components for Flutter. Gives AI assistants like Claude full knowledge of FlAI's component library, theme system, and installation workflow.

## Usage with Claude Code

Add to your Claude Code MCP settings (`.claude/settings.json` or project `.mcp.json`):

```json
{
  "mcpServers": {
    "flai": {
      "command": "npx",
      "args": ["-y", "@getflai/mcp"]
    }
  }
}
```

Or if installed globally:

```json
{
  "mcpServers": {
    "flai": {
      "command": "flai-mcp-server"
    }
  }
}
```

## Available Tools

| Tool | Description |
|------|-------------|
| `list_components` | Lists all FlAI components grouped by category |
| `get_component_info` | Detailed API docs for a specific component (props, usage, deps) |
| `add_component` | Installs a component into a Flutter project via the CLI |
| `init_project` | Initializes FlAI in a Flutter project (theme, models, provider interface) |
| `doctor` | Checks project health and validates the FlAI setup |
| `get_theme_info` | Theme system docs: presets, design tokens, customization |
| `scaffold_chat_app` | Generates a complete main.dart for a chat app with chosen provider and theme |
| `get_starter_template` | Returns full starter code for common patterns (basic chat, multi-model, tool calling, custom theme) |

## Prerequisites

- [FlAI CLI](https://pub.dev/packages/flai_cli) installed and on your PATH
- A Flutter project with `pubspec.yaml`

## Build from Source

```bash
cd packages/flai_mcp
npm install
npm run build
npm start
```

## Links

- Documentation: https://getflai.dev
- Repository: https://github.com/getflai-dev/flai
- CLI: https://pub.dev/packages/flai_cli

## License

MIT
