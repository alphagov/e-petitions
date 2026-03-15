import * as chromeLauncher from 'chrome-launcher';
  import lighthouse from 'lighthouse';
  import { mkdirSync, writeFileSync } from 'fs';
  import { basename, resolve } from 'path';

export default async function (globalConfig, projectConfig) {
  globalThis.lighthouse = async (spec, url, options) => {
    const defaultOptions = {port: chrome.port, output: 'html'};
    const result = await lighthouse(url, {...defaultOptions, ...options});

    const state = spec.expect.getState();
    const reportsDir = resolve('tmp/lighthouse/navigation');
    const reportName = basename(state.testPath, '.spec.mjs');
    const reportFileName = `${reportName}.html`;
    const reportPath = resolve(reportsDir, reportFileName);

    mkdirSync(reportsDir, {recursive: true});
    writeFileSync(reportPath, result.report);

    return result;
  }

  globalThis.performanceScore = (report) => {
    return report.lhr.categories['performance'].score * 100;
  }

  globalThis.accessibilityScore = (report) => {
    return report.lhr.categories['accessibility'].score * 100;
  }

  globalThis.bestPracticesScore = (report) => {
    return report.lhr.categories['best-practices'].score * 100;
  }

  globalThis.seoScore = (report) => {
    return report.lhr.categories['seo'].score * 100;
  }

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
      globalThis.chrome = chrome;
    });
};
