local gen = require('gen')

gen.prompts = {
  Generate = { prompt = "$input1", replace = true },
  Summarize = { prompt = "Summarize the following text:\n$text" },
  Ask = { prompt = "Regarding the following text, $input1:\n$text" },
  Refactor = {
    prompt = [[
    [INST]<<SYS>>
      Software Engineer Code Assistant focused on writing elegant and readable code.
      Refactor the provided code snippet without elaborating on solution.
      <<SYS>>

      Refactor code, $input1, in the following code: $text[/INST]
    ]],
    extract = "```$filetype\n(.-)```",
    replace = true
  },
  ImproveGrammar = { prompt = "Enhance the grammar and spelling in the following text:\n$text", replace = true },
  ImproveWording = { prompt = "Enhance the wording in the following text:\n$text", replace = true },
  MakeConcise = { prompt = "Make the following text as simple and concise as possible:\n$text", replace = true }
}
