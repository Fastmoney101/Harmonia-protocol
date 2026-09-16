/** @type {import('@docusaurus/plugin-content-docs').SidebarsConfig} */
module.exports = {
  docs: [
    "intro",
    {
      type: "category",
      label: "Protocol",
      items: [
        "protocol/overview",
        "protocol/consensus",
        "protocol/indexing",
        "protocol/tokenomics",
        "protocol/governance",
      ],
    },
    {
      type: "category",
      label: "Developers",
      items: [
        "developers/getting-started",
        "developers/contracts",
        "developers/node-setup",
        "developers/api",
        "developers/subgraphs",
      ],
    },
    {
      type: "category",
      label: "Economics",
      items: ["economics/rewards"],
    },
  ],
};
