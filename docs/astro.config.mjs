// @ts-check
import { defineConfig, passthroughImageService } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightThemeFlexoki from 'starlight-theme-flexoki';

// https://astro.build/config
export default defineConfig({
  image: {
    service: passthroughImageService(),
  },
  integrations: [
    starlight({
      plugins: [starlightThemeFlexoki()],
      title: 'Arcade Framework',
      description: 'A minimal, Express-like web framework for Dart',
      favicon: '/favicon.svg',
      logo: {
        src: './src/assets/arcade-logo.svg',
        replacesTitle: true,
      },
      customCss: ['./src/styles/custom.css'],
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/dartarcade/arcade',
        },
      ],
      sidebar: [
        {
          label: 'Introduction',
          items: [
            { label: 'Overview', slug: 'index' },
            { label: 'Getting Started', slug: 'getting-started' },
          ],
        },
        {
          label: 'Core Concepts',
          items: [
            { label: 'Routing', slug: 'core/routing' },
            { label: 'Request Context', slug: 'core/request-context' },
            { label: 'Hooks', slug: 'core/hooks' },
            { label: 'Error Handling', slug: 'core/error-handling' },
          ],
        },
        {
          label: 'Guides',
          items: [
            { label: 'Basic Routing', slug: 'guides/basic-routing' },
            { label: 'Request Handling', slug: 'guides/request-handling' },
            { label: 'WebSockets', slug: 'guides/websockets' },
            { label: 'Static Files', slug: 'guides/static-files' },
            {
              label: 'Dependency Injection',
              slug: 'guides/dependency-injection',
            },
          ],
        },
        {
          label: 'Packages',
          items: [
            { label: 'Arcade Cache', slug: 'packages/arcade-cache' },
            {
              label: 'Arcade Cache Redis',
              slug: 'packages/arcade-cache-redis',
            },
            { label: 'Arcade CLI', slug: 'packages/arcade-cli' },
            { label: 'Arcade Config', slug: 'packages/arcade-config' },
            { label: 'Arcade Logger', slug: 'packages/arcade-logger' },
            { label: 'Arcade Storage', slug: 'packages/arcade-storage' },
            {
              label: 'Arcade Storage MinIO',
              slug: 'packages/arcade-storage-minio',
            },
            { label: 'Arcade Swagger', slug: 'packages/arcade-swagger' },
            { label: 'Arcade Test', slug: 'packages/arcade-test' },
            { label: 'Arcade Views', slug: 'packages/arcade-views' },
          ],
        },
      ],
    }),
  ],
});
