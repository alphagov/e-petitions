const config = {
  detectOpenHandles: true,
  globalSetup: './spec/lighthouse/support/setup.mjs',
  globalTeardown: './spec/lighthouse/support/teardown.mjs',
  testRegex: 'spec/lighthouse/navigation/[^.]+.spec.mjs',
  testTimeout: 10000
};

module.exports = config;
