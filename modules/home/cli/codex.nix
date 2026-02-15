{
  config,
  lib,
  ...
}:

with lib;

let
  cfg = config.modules.home.cli.codex;
in
{
  options.modules.home.cli.codex = {
    enable = mkEnableOption "codex";
  };

  config = mkIf cfg.enable {
    home.file.".codex/config.toml" = {
      force = true;
      text = ''
        model = "gpt-5.3-codex"
        model_reasoning_effort = "high"
        tool_output_token_limit = 25000
        # Leave room for native compaction near the 272–273k context window.
        # Formula: 273000 - (tool_output_token_limit + 15000)
        # With tool_output_token_limit=25000 ⇒ 273000 - (25000 + 15000) = 233000
        model_auto_compact_token_limit = 233000
        [features]
        ghost_commit = false
        unified_exec = true
        apply_patch_freeform = true
        web_search_request = true
        skills = true
        shell_snapshot = true

        [projects."/home/dejanr/projects"]
        trust_level = "trusted"
        [projects."/home/dejanr/.dotfiles"]
        trust_level = "trusted"
      '';
    };
  };
}
