import js from "@eslint/js";
import globals from "globals";
import reactHooks from "eslint-plugin-react-hooks";
import reactRefresh from "eslint-plugin-react-refresh";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["dist", "node_modules", "*.config.js", "*.config.ts"] },
  {
    extends: [js.configs.recommended, ...tseslint.configs.recommended],
    files: ["**/*.{ts,tsx}"],
    languageOptions: {
      ecmaVersion: 2020,
      globals: globals.browser,
    },
    plugins: {
      "react-hooks": reactHooks,
      "react-refresh": reactRefresh,
    },
    rules: {
      ...reactHooks.configs.recommended.rules,
      "react-refresh/only-export-components": ["warn", { allowConstantExport: true }],

      // TypeScript strict rules (warnings for gradual adoption)
      "@typescript-eslint/no-unused-vars": ["warn", {
        "argsIgnorePattern": "^_",
        "varsIgnorePattern": "^_",
        "caughtErrorsIgnorePattern": "^_"
      }],
      "@typescript-eslint/no-explicit-any": "warn",
      "@typescript-eslint/no-var-requires": "error",

      // Code quality rules (warnings for gradual adoption)
      "no-console": "off", // Allow console for now (replaced with logger)
      "no-debugger": "error",
      "no-duplicate-imports": "warn",
      "prefer-const": "warn",
      "no-var": "warn",
      "object-shorthand": "warn",
      "prefer-arrow-callback": "warn",
      "prefer-template": "warn",

      // React specific rules
      "react-hooks/exhaustive-deps": "warn",

      // Import rules
      "@typescript-eslint/consistent-type-imports": ["warn", {
        "prefer": "type-imports",
        "disallowTypeAnnotations": false
      }],

      // Allow some flexibility for existing code
      "@typescript-eslint/no-non-null-assertion": "warn",
      "no-undef": "off", // TypeScript handles this
    },
  },
);
