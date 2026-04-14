/**
 * layout.tsx — MedinovAI Command Center Root Layout
 * (c) 2026 Copyright MedinovAI. All Rights Reserved.
 *
 * Version: 3.0.0 | Build: 20260414.1 | Release: GA
 */

import type { Metadata, Viewport } from 'next';
import { Inter } from 'next/font/google';
import './globals.css';

// ── Font ───────────────────────────────────────────────────────────────────
const E_INTER = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});

export const metadata: Metadata = {
  title: {
    default: 'MedinovAI Command Center',
    template: '%s | MedinovAI Command Center',
  },
  description:
    'MedinovAI Unified Control Plane — real-time platform health, Nexus AI Agent, ' +
    'deployment orchestration, and compliance monitoring across all environments.',
  applicationName: 'MedinovAI Command Center',
  authors: [{ name: 'MedinovAI Platform Infrastructure Squad' }],
  creator: 'MedinovAI',
  publisher: 'MedinovAI',
  generator: 'Next.js 15',
  metadataBase: new URL(
    process.env.NEXT_PUBLIC_BASE_URL ?? 'https://dev.medinovai.com:9443'
  ),

  // ── Favicon suite ─────────────────────────────────────────────────────
  icons: {
    icon: [
      { url: '/favicon.ico',       sizes: '32x32', type: 'image/x-icon'   },
      { url: '/favicon-16x16.png', sizes: '16x16', type: 'image/png'      },
      { url: '/favicon-32x32.png', sizes: '32x32', type: 'image/png'      },
      { url: '/favicon.svg',       type: 'image/svg+xml'                   },
    ],
    apple: [
      { url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' },
    ],
    other: [
      { rel: 'mask-icon', url: '/favicon.svg', color: '#38bdf8' },
    ],
  },

  // ── Web App Manifest (PWA) ─────────────────────────────────────────────
  manifest: '/site.webmanifest',

  // ── Open Graph ─────────────────────────────────────────────────────────
  openGraph: {
    type: 'website',
    locale: 'en_US',
    url: 'https://dev.medinovai.com:9443',
    siteName: 'MedinovAI Command Center',
    title: 'MedinovAI Command Center',
    description: 'Unified Control Plane for the MedinovAI Healthcare Platform',
    images: [{ url: '/icon-512.png', width: 512, height: 512, alt: 'MedinovAI Command Center' }],
  },

  robots: {
    index: false,   // Internal tool — never index
    follow: false,
    googleBot: { index: false, follow: false },
  },
};

export const viewport: Viewport = {
  themeColor: [
    { media: '(prefers-color-scheme: dark)',  color: '#0f172a' },
    { media: '(prefers-color-scheme: light)', color: '#1e3a5f' },
  ],
  colorScheme: 'dark',
  width: 'device-width',
  initialScale: 1,
  maximumScale: 1,
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className={`${E_INTER.variable} dark`} suppressHydrationWarning>
      <head>
        <meta httpEquiv="X-UA-Compatible" content="IE=edge" />
        <meta name="copyright" content="(c) 2026 MedinovAI. All Rights Reserved." />
        <meta name="version"   content="3.0.0" />
        <meta name="build"     content="20260414.1" />
        {/* CSP nonce injected by middleware in production */}
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
