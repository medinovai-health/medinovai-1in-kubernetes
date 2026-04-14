/** @type {import('next').NextConfig} */
// next.config.mjs — MedinovAI Command Center v3.0
// (c) 2026 Copyright MedinovAI. All Rights Reserved.

const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  poweredByHeader: false,
  compress: true,

  // Hardening Point 16: Security headers at Next.js level
  async headers() {
    return [
      {
        source: '/(.*)',
        headers: [
          { key: 'X-DNS-Prefetch-Control', value: 'on' },
          { key: 'X-Download-Options', value: 'noopen' },
          { key: 'X-Permitted-Cross-Domain-Policies', value: 'none' },
        ],
      },
    ];
  },

  // Hardening Point 17: Strict redirects
  async redirects() {
    return [
      {
        source: '/command-center',
        destination: '/dashboard',
        permanent: true,
      },
    ];
  },

  // Hardening Point 18: Image optimization with allowed domains only
  images: {
    domains: ['medinovai.health', 'avatars.githubusercontent.com'],
    formats: ['image/avif', 'image/webp'],
  },

  // Hardening Point 19: Webpack security configuration
  webpack: (config, { isServer }) => {
    // Prevent client-side exposure of server-only modules
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        crypto: false,
      };
    }
    return config;
  },

  // Environment variables exposed to client (non-secret only)
  env: {
    NEXT_PUBLIC_COMMAND_CENTER_VERSION: '3.0.0',
    NEXT_PUBLIC_COPYRIGHT: '(c) 2026 MedinovAI. All Rights Reserved.',
  },

  experimental: {
    serverComponentsExternalPackages: ['@node-rs/argon2', 'bcrypt'],
  },
};

export default nextConfig;
