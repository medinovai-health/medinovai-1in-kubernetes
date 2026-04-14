/**
 * tailwind.config.ts — MedinovAI Command Center
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 * Apple Liquid Glass theme with oklch color tokens
 */

import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './app/**/*.{js,ts,jsx,tsx,mdx}',
    './components/**/*.{js,ts,jsx,tsx,mdx}',
    './lib/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        // MedinovAI brand tokens
        'mos-primary': 'oklch(0.65 0.22 265)',
        'mos-secondary': 'oklch(0.55 0.18 195)',
        'mos-accent': 'oklch(0.75 0.25 145)',
        'mos-danger': 'oklch(0.65 0.25 25)',
        'mos-warning': 'oklch(0.75 0.2 75)',
        'mos-success': 'oklch(0.7 0.2 145)',
      },
      backdropBlur: {
        'glass': '20px',
      },
      animation: {
        'glow-pulse': 'glow-pulse 3s ease-in-out infinite',
        'slide-in': 'slide-in 0.2s ease-out',
      },
      keyframes: {
        'glow-pulse': {
          '0%, 100%': { boxShadow: '0 0 20px oklch(0.65 0.22 265 / 0.3)' },
          '50%': { boxShadow: '0 0 40px oklch(0.65 0.22 265 / 0.5)' },
        },
        'slide-in': {
          from: { opacity: '0', transform: 'translateY(8px)' },
          to: { opacity: '1', transform: 'translateY(0)' },
        },
      },
      fontFamily: {
        sans: [
          '-apple-system',
          'BlinkMacSystemFont',
          'SF Pro Display',
          'Segoe UI',
          'Roboto',
          'sans-serif',
        ],
        mono: [
          'SF Mono',
          'Fira Code',
          'Fira Mono',
          'Roboto Mono',
          'monospace',
        ],
      },
    },
  },
  plugins: [
    require('@tailwindcss/typography'),
  ],
};

export default config;
