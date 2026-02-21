/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'export',
  distDir: 'out',
  poweredByHeader: false,
  reactStrictMode: true,
  images: {
    unoptimized: true,
  },
  env: {
    SERVICE_NAME: process.env.SERVICE_NAME || 'blackroad-infra',
    SERVICE_ENV: process.env.SERVICE_ENV || 'production',
    NEXT_PUBLIC_APP_NAME: process.env.NEXT_PUBLIC_APP_NAME || 'BlackRoad Infrastructure',
  },
}

export default nextConfig
