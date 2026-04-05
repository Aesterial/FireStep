import js from '@eslint/js';
import nextPlugin from '@next/eslint-plugin-next';
import tsEslintPlugin from '@typescript-eslint/eslint-plugin';
import tsParser from '@typescript-eslint/parser';
import {defineConfig, globalIgnores} from 'eslint/config';
import globals from 'globals';
import simpleImportSort from 'eslint-plugin-simple-import-sort';
import unusedImports from 'eslint-plugin-unused-imports';

export default defineConfig([
    js.configs.recommended,
    {
        files: ['**/*.{js,jsx,ts,tsx,mjs,cjs}'],
        plugins: {
            '@next/next': nextPlugin,
            '@typescript-eslint': tsEslintPlugin,
            'simple-import-sort': simpleImportSort,
            'unused-imports': unusedImports,
        },
        languageOptions: {
            parser: tsParser,
            parserOptions: {
                ecmaVersion: 'latest',
                sourceType: 'module',
                ecmaFeatures: {
                    jsx: true,
                },
            },
            globals: {
                ...globals.browser,
                ...globals.node,
            },
        },
        rules: {
            ...tsEslintPlugin.configs.recommended.rules,
            ...nextPlugin.configs.recommended.rules,
            ...nextPlugin.configs['core-web-vitals'].rules,
            'no-undef': 'off',
            'no-unused-vars': 'off',
            'no-console': 'warn',
            '@typescript-eslint/explicit-module-boundary-types': 'off',
            '@typescript-eslint/no-unused-vars': 'off',
            'unused-imports/no-unused-imports': 'warn',
            'unused-imports/no-unused-vars': [
                'warn',
                {
                    vars: 'all',
                    varsIgnorePattern: '^_',
                    args: 'after-used',
                    argsIgnorePattern: '^_',
                },
            ],
            'simple-import-sort/exports': 'warn',
            'simple-import-sort/imports': [
                'warn',
                {
                    groups: [
                        ['^@?\\w', '^\\u0000'],
                        ['^.+\\.s?css$'],
                        ['^@/lib', '^@/hooks'],
                        ['^@/data'],
                        ['^@/components', '^@/container'],
                        ['^@/store'],
                        ['^@/'],
                        [
                            '^\\./?$',
                            '^\\.(?!/?$)',
                            '^\\.\\./?$',
                            '^\\.\\.(?!/?$)',
                            '^\\.\\./\\.\\./?$',
                            '^\\.\\./\\.\\.(?!/?$)',
                            '^\\.\\./\\.\\./\\.\\./?$',
                            '^\\.\\./\\.\\./\\.\\.(?!/?$)',
                        ],
                        ['^@/types'],
                        ['^'],
                    ],
                },
            ],
        },
    },
    {
        files: ['**/*.test.{js,jsx,ts,tsx}', '**/__tests__/**/*.{js,jsx,ts,tsx}'],
        languageOptions: {
            globals: {
                ...globals.jest,
            },
        },
        rules: {
            '@typescript-eslint/no-require-imports': 'off',
            'no-useless-assignment': 'off',
            'simple-import-sort/imports': 'off',
        },
    },
    globalIgnores([
        '.github/**',
        '.husky/**',
        '.next/**',
        'out/**',
        'build/**',
        'coverage/**',
        'next-env.d.ts',
        'node_modules/**',
        'jest.config.js',
        'lint-staged.config.js',
        'next.config.js',
        'postcss.config.js',
        'tailwind.config.js',
        '.prettierrc.js',
        '.prettierignore',
    ]),
]);
