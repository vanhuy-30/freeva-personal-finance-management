module.exports = {
  ...require('./jest.config.cjs'),
  testRegex: '.*\\.integration-spec\\.ts$',
  testTimeout: 30000,
  maxWorkers: 1,
};
