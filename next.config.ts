import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  output: 'standalone',  // Optimizes for production deployment
  env: {
    PORT: process.env.PORT || '3000'
  }
};

export default nextConfig;
