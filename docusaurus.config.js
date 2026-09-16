/** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  title: "Harmonia Protocol",
  tagline: "Hashgraph-speed consensus meets decentralized indexing",
  url: "https://harmonia.org",
  baseUrl: "/",
  favicon: "img/favicon.ico",

  onBrokenLinks: "warn",
  onBrokenMarkdownLinks: "warn",

  presets: [
    [
      "classic",
      {
        docs: {
          sidebarPath: require.resolve("./sidebars.js"),
        },
        theme: {
          customCss: require.resolve("./src/css/custom.css"),
        },
      },
    ],
  ],

  themeConfig: {
    navbar: {
      title: "Harmonia",
      items: [
        { to: "/docs/intro", label: "Docs", position: "left" },
        { href: "https://github.com/harmonia/harmonia-protocol", label: "GitHub", position: "right" },
      ],
    },
    footer: {
      style: "dark",
      copyright: `Copyright ${new Date().getFullYear()} Harmonia Protocol. Built with Docusaurus.`,
    },
  },
};
