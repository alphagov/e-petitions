describe('the cookies page', function () {
  let report = null;

  before('Run lighthouse test', async () => {
    report = await lighthouse(this, 'http://petitions.localhost:3000/cookies');
  });

  it('should have an accessibility score of 100', () => {
    expect(accessibilityScore(report), 'to equal', 100);
  });

  it('should have an best practices score greater than or equal to 95', () => {
    expect(bestPracticesScore(report), 'to be greater than or equal to', 95);
  });

  it('should have an SEO score greater than or equal to 95', () => {
    expect(seoScore(report), 'to be greater than or equal to', 95);
  });
});
