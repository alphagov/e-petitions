import lighthouse from 'lighthouse';
import { mkdirSync, writeFileSync } from 'fs';
import { basename, resolve } from 'path';

global.lighthouse = async (spec, url, options) => {
  const defaultOptions = {port: chrome.port, output: 'html'};
  const result = await lighthouse(url, {...defaultOptions, ...options});

  const reportsDir = resolve('tmp/lighthouse/navigation');
  const reportName = basename(spec.file, '.spec.mjs');
  const reportFileName = `${reportName}.html`;
  const reportPath = resolve(reportsDir, reportFileName);

  mkdirSync(reportsDir, {recursive: true});
  writeFileSync(reportPath, result.report);

  return result;
}

global.performanceScore = (report) => {
  return report.lhr.categories['performance'].score * 100;
}

global.accessibilityScore = (report) => {
  return report.lhr.categories['accessibility'].score * 100;
}

global.bestPracticesScore = (report) => {
  return report.lhr.categories['best-practices'].score * 100;
}

global.seoScore = (report) => {
  return report.lhr.categories['seo'].score * 100;
}
