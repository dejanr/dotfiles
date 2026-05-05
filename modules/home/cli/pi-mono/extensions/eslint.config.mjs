import tsParser from "@typescript-eslint/parser";
import importPlugin from "eslint-plugin-import";

const coreModules = [
  "@mariozechner/pi-coding-agent",
  "@mariozechner/pi-ai",
  "@mariozechner/pi-tui",
  "typebox",
];

export default [
  {
    files: ["**/*.ts"],
    languageOptions: {
      parser: tsParser,
      parserOptions: {
        project: "./tsconfig.json",
        tsconfigRootDir: import.meta.dirname,
      },
    },
    plugins: {
      import: importPlugin,
    },
    rules: {
      "import/no-unresolved": "off",
      "import/no-extraneous-dependencies": "off",
    },
    settings: {
      "import/core-modules": coreModules,
      "import/ignore": [
        "^@mariozechner/",
        "^typebox$",
      ],
    },
  },
];
