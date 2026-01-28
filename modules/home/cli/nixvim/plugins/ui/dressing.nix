{ ... }:
{
  plugins.dressing = {
    enable = true;
  };

  extraConfigLuaPost = ''
    require('dressing').setup({
      input = {
        enabled = true,
        default_prompt = "",
        border = "rounded",
        relative = "cursor",
      },
      select = {
        enabled = false,
      },
    })
  '';
}
