import tsParser from "@typescript-eslint/parser";
import importPlugin from "eslint-plugin-import";

const coreModules = [
  "@earendil-works/pi-coding-agent",
  "@earendil-works/pi-ai",
  "@earendil-works/pi-tui",
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
        "^@earendil-works/",
        "^typebox$",
      ],
    },
  },
];
