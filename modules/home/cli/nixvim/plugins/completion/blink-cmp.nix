{ pkgs, ... }:
{
  plugins.blink-cmp = {
    enable = true;
    setupLspCapabilities = true;

    settings = {
      keymap = {
        preset = "default";

        "<Tab>" = [
          {
            __raw = ''
              function(cmp)
                local function is_jsx_attribute_quote_context()
                  if not vim.tbl_contains({ "javascriptreact", "typescriptreact" }, vim.bo.filetype) then
                    return false
                  end

                  local cursor = vim.api.nvim_win_get_cursor(0)
                  local line = vim.api.nvim_get_current_line()
                  local before_cursor = line:sub(1, cursor[2])
                  local tag = before_cursor:match('<[%a_$][^>]*$')
                  return tag ~= nil and tag:match("=[\"'][^\"']*$") ~= nil
                end

                local should_jump_after_quote = is_jsx_attribute_quote_context()
                return cmp.select_and_accept({
                  callback = function()
                    if not should_jump_after_quote then
                      return
                    end

                    local cursor = vim.api.nvim_win_get_cursor(0)
                    local line = vim.api.nvim_get_current_line()
                    local next_char = line:sub(cursor[2] + 1, cursor[2] + 1)
                    if next_char == '"' or next_char == "'" then
                      vim.api.nvim_win_set_cursor(0, { cursor[1], cursor[2] + 1 })
                    end
                  end,
                })
              end
            '';
          }
          "snippet_forward"
          "fallback"
        ];
        "<S-Tab>" = [
          "select_prev"
          "snippet_backward"
          "fallback"
        ];
        "<C-p>" = [
          "select_prev"
          "fallback"
        ];
        "<C-n>" = [
          "select_next"
          "fallback"
        ];

        "<S-k>" = [
          "scroll_documentation_up"
          "fallback"
        ];
        "<S-j>" = [
          "scroll_documentation_down"
          "fallback"
        ];

        "<C-space>" = [
          "show"
          "show_documentation"
          "hide_documentation"
        ];
        "<C-e>" = [
          "hide"
          "fallback"
        ];
      };

      appearance = {
        use_nvim_cmp_as_default = true;
        nerd_font_variant = "mono";
      };

      completion = {
        documentation = {
          auto_show = true;
          auto_show_delay_ms = 300;
        };

        trigger = {
          show_on_blocked_trigger_characters = [
            " "
            "\n"
            "\t"
          ];
        };
      };

      sources = {
        default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
        ];

        providers = {
          lsp = {
            transform_items.__raw = ''
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

            override = {
              execute.__raw = ''
                function(_, ctx, item, callback, default_implementation)
                  local text_edit = item.textEdit
                  local new_text = text_edit and text_edit.newText or item.insertText
                  local prop_name = new_text and new_text:match('^([%w_$-]+)=%{%$1%}$')
                  local detail = item.detail or ""
                  local is_string_like = detail:match('"[^"]+"') ~= nil or detail:match(': string') ~= nil
                  local is_mixed_primitive = detail:match('%f[%w]number%f[%W]') ~= nil or detail:match('%f[%w]boolean%f[%W]') ~= nil

                  if prop_name and is_string_like and not is_mixed_primitive then
                    local quoted_new_text = prop_name .. '="$1"'
                    if text_edit then
                      text_edit.newText = quoted_new_text
                    else
                      item.insertText = quoted_new_text
                    end
                  end

                  default_implementation(ctx, item)
                  callback()
                end
              '';
            };
          };
        };
      };

      fuzzy = {
        prebuilt_binaries = {
          ignore_version_mismatch = true;
        };
      };
    };
  };
}
