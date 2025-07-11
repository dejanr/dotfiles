return {
  "f-person/git-blame.nvim",
  event = "VeryLazy",
  opts = {
    enabled = true,          -- if you want to enable the plugin
    virtual_text_column = 1, -- virtual text start column, check Start virtual text at column section for more options
    delay = 3000,
    use_blame_commit_file_urls = true,
  },
}
