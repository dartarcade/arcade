import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { ion, resolve } from 'starlight-ion-theme';

// https://astro.build/config
export default defineConfig({
  site: 'https://arcade.ex3.dev',
  base: '/',
  integrations: [starlight({
    title: 'Arcade',
    logo: {
      dark: './src/assets/ion-logo.svg',
      light: './src/assets/ion-logo-light.svg',
    },
    social: {
      github: 'https://github.com/dartarcade/arcade'
    },
    sidebar: [
      { label: '[home] Home', link: '/' },
      { label: '[list] Getting Started', link: '/getting-started/' },
      { label: '[box] Packages', autogenerate: { directory: 'packages' } },
      { label: '[rocket] Todo API Sample', link: '/samples/todo-api/' }
    ],
    customCss: [
      '@fontsource-variable/space-grotesk/index.css',
      '@fontsource/space-mono/400.css',
      '@fontsource/space-mono/700.css',
      './src/styles/global.css'
    ],
    lastUpdated: true,
    pagination: false,
    plugins: [
      ion({
        icons: {
          iconDir: './src/icons',
        },
        footer: {
          text: '©️ Arcade contributors',
          links: [{
            text: 'GitHub',
            href: 'https://github.com/dartarcade/arcade'
          }]
        }
      })
    ]
  })],
  output: "static"
});
