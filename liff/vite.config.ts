/// <reference types="vitest" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  base: process.env.VERCEL ? '/' : '/',
  build: {
    outDir: 'dist',
    sourcemap: true,
  },
  server: {
    port: 3002,
    host: true,
  },
  // Vitest settings (type augmented via the triple-slash reference above)
  // If your editor flags this, it's safe to ignore during build.
  test: {
    environment: 'jsdom',
    setupFiles: ['./test/setup.ts'],
    globals: true,
  },
})
