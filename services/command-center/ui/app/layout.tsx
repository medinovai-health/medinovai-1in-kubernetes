/**
 * layout.tsx — MedinovAI Command Center Root Layout
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 */

import type { Metadata, Viewport } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: {
    default: 'MedinovAI Command Center',
    template: '%s | MedinovAI Command Center',
  },
  description: 'Unified control plane for the MedinovAI platform — total observability, autonomous remediation, and AI-powered operations.',
  robots: {
    index: false, // Command Center is not public — never index
    follow: false,
    googleBot: { index: false, follow: false },
  },
  authors: [{ name: 'MedinovAI Platform Infrastructure Squad' }],
  creator: 'MedinovAI',
  publisher: 'MedinovAI',
  keywords: [],
  // No Open Graph — this is an internal tool
};

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
  themeColor: [
    { media: '(prefers-color-scheme: light)', color: '#0f172a' },
    { media: '(prefers-color-scheme: dark)', color: '#0f172a' },
  ],
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="dark">
      <head>
        {/* Hardening Point 20: No external resource loading */}
        <meta httpEquiv="X-UA-Compatible" content="IE=edge" />
        {/* CSP nonce would be injected here in production via middleware */}
      </head>
      <body className="bg-slate-950 text-slate-100 antialiased min-h-screen">
        {/* 
          Command Center Shell
          Apple Liquid Glass aesthetic — translucent panels, blur effects, oklch color tokens
        */}
        <div id="command-center-root" className="flex flex-col min-h-screen">
          {children}
        </div>
        {/* Copyright — never remove */}
        <div className="hidden" aria-hidden="true">
          (c) 2026 MedinovAI. All Rights Reserved. Unauthorized access prohibited.
        </div>
      </body>
    </html>
  );
}
