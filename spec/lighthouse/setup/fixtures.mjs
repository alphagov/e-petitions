import * as chromeLauncher from 'chrome-launcher';

export const mochaGlobalSetup = async () => {
  const chromeFlags = [
    '--headless',
    '--disable-gpu',
    '--no-sandbox',
    '--disable-dev-shm-usage',
  ];

  console.log('Waiting for chromium to launch ...')

  await chromeLauncher
    .launch({chromeFlags})
    .then((chrome) => {
      global.chrome = chrome;
    });
};

export const mochaGlobalTeardown = async () => {
  global.chrome.kill();
};
