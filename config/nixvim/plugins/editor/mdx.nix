{ pkgs, ... }:
{
  extraPlugins = [
    (pkgs.vimUtils.buildVimPlugin {
      pname = "mdx.nvim";
      version = "2024-12-30";
      src = pkgs.fetchFromGitHub {
        owner = "davidmh";
        repo = "mdx.nvim";
        rev = "30222997ed4c0c7cc7447c4fce360fce87101bbf";
        sha256 = "sha256-QaPYSTH59j8tUa5rTY8I9VdQWLkhy8SWhNigEXHFn1c=";
      };
    })
  ];

  extraConfigLua = ''
    require('mdx').setup()
  '';
}
