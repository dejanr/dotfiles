---
name: nvim-config
description: Update and debug Neovim/Nixvim configuration in these dotfiles, especially LSP/completion/editing behavior for TypeScript/TSX, blink.cmp, nvim-autopairs, ts_ls, Emmet, and related plugins.
---

# Neovim Config Skill

Use this when the user asks to change, debug, or improve Neovim behavior in this dotfiles repository.

## Repository Layout

Neovim is configured with Nixvim under:

```text
modules/home/cli/nixvim/
├── default.nix                  # imports core config and plugins
├── settings.nix                 # vim options
├── keymaps.nix                  # global keymaps
├── autocmds.nix                 # autocmds
├── lua/                         # Lua helper modules copied into runtime
└── plugins/
    ├── completion/blink-cmp.nix # completion UI and sources
    ├── editor/nvim-autopairs.nix
    ├── editor/treesitter.nix
    └── lsp/lspconfig.nix        # LSP servers and ts_ls prefs
```

The standalone nvim package is exposed by `flake.nix` as:

```bash
nix build .#nvim --no-link
nix run .#nvim
```

Pi skills are managed by Nix from:

```text
modules/home/cli/pi-mono/skills/<skill-name>/SKILL.md
```

`~/.pi/agent/skills` is a read-only symlink into the built Home Manager profile.

## Investigation Workflow

### 1. Start From the Symptom, Not Assumptions

For screenshots, read the image first:

```text
read /tmp/pi-clipboard-...png
```

Identify whether the behavior is caused by:

- `ts_ls` / TypeScript language server
- `blink.cmp` filtering, sorting, trigger behavior, snippets, or keymaps
- another LSP source such as `emmet_ls` or `tailwindcss`
- `nvim-autopairs`
- project TypeScript types/config

Do not change config until you know which layer is responsible.

### 2. Inspect Relevant Config and Project Types

Useful files:

```bash
rg -n "blink|cmp|ts_ls|typescript|emmet|autopairs|jsx" modules/home/cli/nixvim -S
```

For TypeScript/TSX completion issues, inspect:

- `modules/home/cli/nixvim/plugins/lsp/lspconfig.nix`
- `modules/home/cli/nixvim/plugins/completion/blink-cmp.nix`
- the component definition being completed
- project `tsconfig.json` / `package.json`

Example project checks:

```bash
fd -a 'tsconfig.*|package.json' <project-root> -d 3
```

### 3. Verify Attached LSP Clients

Use headless nvim from the project root/file:

```bash
cd <project>
nvim --headless path/to/file.tsx +'lua vim.defer_fn(function()
  print("ft=" .. vim.bo.filetype)
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    print("client=" .. c.name .. " root=" .. tostring(c.config.root_dir))
    print("completion=" .. tostring(c.server_capabilities.completionProvider ~= nil))
  end
  vim.cmd("qa!")
end, 3000)'
```

If `ts_ls` is attached and returns completions via raw LSP requests, the issue is usually completion UI/source behavior rather than TypeScript itself.

### 4. Query Raw LSP Completions

Use `vim.lsp.buf_request_sync` to compare what each client returns at a position:

```bash
cd <project>
nvim --headless path/to/file.tsx +'lua vim.defer_fn(function()
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(0),
    position = { line = 95, character = 59 },
    context = { triggerKind = 1 },
  }
  local res = vim.lsp.buf_request_sync(0, "textDocument/completion", params, 5000)
  for id, r in pairs(res or {}) do
    local client = vim.lsp.get_client_by_id(id)
    local items = (r.result and (r.result.items or r.result)) or {}
    print("client", client and client.name, "count", #items)
    for i, it in ipairs(items) do
      if i <= 20 then
        print(i, it.label, it.kind, it.detail or "", vim.inspect(it.textEdit or it.insertText))
      end
    end
  end
  vim.cmd("qa!")
end, 3000)'
```

Use this to distinguish:

- TS LSP does not provide item → project/types/server issue
- TS LSP provides item but UI does not show it → blink/source/filter/sort/cache issue
- Emmet provides weird first item → filter/demote Emmet in JSX attribute contexts

### 5. Inspect Resolved Completion Details

Some TS completion detail is only available after `completionItem/resolve`:

```lua
local resolved = client:request_sync("completionItem/resolve", item, 5000, 0)
print(vim.inspect(resolved and resolved.result))
```

This is useful for JSX prop types such as:

```text
(property) align?: "start" | "center" | ... | null | undefined
```

## Patterns From This Session

### TypeScript JSX prop names vs prop values

- Prop values (`align="..."`) can work while prop names do not.
- TS LSP intentionally does not suggest duplicate JSX props. If `<Flex direction="row" ... direct>`, `direction?` will not be suggested again.
- TS LSP may return JSX prop names, but `blink.cmp` can hide them due to source behavior or Emmet competition.

### Blink LSP capabilities

Enable blink's LSP capabilities so TypeScript returns richer completion metadata:

```nix
plugins.blink-cmp = {
  enable = true;
  setupLspCapabilities = true;
};
```

### JSX prop name triggering

Space-triggered LSP completion looked attractive, but caused bad cached TS results and left only Emmet/buffer suggestions. Keep space blocked and use normal keyword/manual triggers:

```nix
completion.trigger.show_on_blocked_trigger_characters = [
  " "
  "\n"
  "\t"
];
```

Use `<C-space>` for manual completion right after a space.

### Emmet interference in TSX attributes

Emmet can suggest fake custom tags like:

```tsx
<alig>${1}</alig>
```

inside component prop lists. Filter Emmet LSP items in JSX/TSX attribute contexts so TS prop completions win:

```nix
sources.providers.lsp.transform_items.__raw = ''
  function(_, items)
    if not vim.tbl_contains({ "javascriptreact", "typescriptreact" }, vim.bo.filetype) then
      return items
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local line = vim.api.nvim_get_current_line()
    local before_cursor = line:sub(1, cursor[2])
    local tag = before_cursor:match('<[%a_$][^>]*$')
    if not tag or not tag:match('^<[%a_$][%w_$.:-]*%s') then
      return items
    end

    return vim.tbl_filter(function(item)
      return item.client_name ~= "emmet_ls" and item.client_name ~= "emmet-language-server"
    end, items)
  end
'';
```

### JSX attribute quote/braces behavior

TypeScript's `jsxAttributeCompletionStyle = "auto"` uses quotes only for string/undefined-only types. If the prop type includes `null`, TypeScript may choose braces:

```tsx
align={$1}
```

For local preferences, configure TS:

```nix
ts_ls.extraOptions.init_options.preferences = {
  jsxAttributeCompletionStyle = "auto";
  quotePreference = "double";
};
```

If needed, transform accepted LSP items in blink's LSP provider `execute` hook. In this session, string-like JSX prop snippets such as `align={$1}` were converted to `align="$1"` by checking `item.detail` and `item.textEdit.newText`.

### Cursor movement after accepting JSX values

For the desired behavior where accepting a value inside quotes moves the cursor after the closing quote, wrap `<Tab>` with a blink keymap function:

1. Detect TSX/JSX attribute quote context before accepting.
2. Call `cmp.select_and_accept({ callback = ... })`.
3. In the callback, if next char is `'` or `"`, move cursor one column right.

Keep `snippet_forward` after the custom function so normal snippets still work.

### nvim-autopairs JSX `=` spacing

A custom `Rule('=', '')` in `nvim-autopairs` inserted spaces around `=`. Disable that rule for JSX/TSX attribute assignments while preserving it elsewhere.

Good pattern:

- detect `javascriptreact` / `typescriptreact`
- ensure cursor is inside an opening tag
- skip inside `{...}` expression braces
- return `false` from `with_pair` so autopairs does not rewrite `=`

## Validation Checklist

Always run formatting and builds after Nixvim edits:

```bash
nixfmt modules/home/cli/nixvim/plugins/<file>.nix
nix-instantiate --parse modules/home/cli/nixvim/plugins/<file>.nix >/dev/null
nix build .#nvim --no-link
```

For embedded Lua in Nix strings, syntax-check the generated Lua when practical:

```bash
tmp=$(mktemp --suffix=.lua)
nix eval --impure --raw --expr '(<expr that extracts extraConfigLua or __raw string>)' > "$tmp"
luajit -bl "$tmp" >/dev/null 2>&1 || lua -e "assert(loadfile('$tmp'))"
```

For actual completion behavior, build an out-link and run that exact nvim:

```bash
nix build .#nvim --out-link /tmp/dotfiles-nvim-test
cd <project>
/tmp/dotfiles-nvim-test/bin/nvim --headless path/to/file.tsx +'lua ...'
```

To inspect blink's visible list in headless nvim:

```lua
local list = require("blink.cmp.completion.list")
print("visible", require("blink.cmp").is_visible(), "count", #list.items)
for k, it in pairs(list.items) do
  print(k, it.label, it.source_id, it.client_name or "", it.kind_name or it.kind, it.detail or "")
end
```

## Best Practices

- Prefer small targeted changes in the relevant plugin module.
- Keep config functional/simple; avoid broad global hacks.
- Verify raw LSP output before changing completion UI behavior.
- Treat Emmet, TS, Tailwind, snippets, buffer as separate completion sources.
- Avoid adding space as an LSP trigger in TSX unless you verify it does not cache incomplete/empty server results.
- Use provider-specific filtering/transforms rather than disabling a tool globally when possible.
- Use TypeScript preferences for server-supported behavior first; use blink transforms only for editor UX that TS does not expose.
- When testing long builds, run raw `nix build` with live output; do not pipe through filters.
- Do not commit unless the user explicitly asks.
