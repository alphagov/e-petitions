export default async function (globalConfig, projectConfig) {
  console.log("Shutting down chromium ...");
  globalThis.chrome.kill();
};
