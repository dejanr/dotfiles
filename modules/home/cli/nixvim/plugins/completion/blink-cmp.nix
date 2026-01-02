{ pkgs, ... }:
{
  plugins.blink-cmp = {
    enable = true;

    settings = {
      keymap = {
        preset = "default";

        "<Tab>" = [
          "snippet_forward"
          "fallback"
        ];
        "<S-Tab>" = [
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

      sources = {
        default = [
          "lsp"
          "path"
          "snippets"
          "buffer"
        ];
      };

      fuzzy = {
        prebuilt_binaries = {
          ignore_version_mismatch = true;
        };
      };
    };
  };
}
