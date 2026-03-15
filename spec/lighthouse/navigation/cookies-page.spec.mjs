describe('the cookies page', function () {
  let report = null;

  beforeAll(async () => {
    report = await lighthouse(this, 'http://petitions.localhost:3000/cookies');
  });

  it('should have an accessibility score of 100', () => {
    expect(accessibilityScore(report)).toEqual(100);
  });

  it('should have an best practices score greater than or equal to 95', () => {
    expect(bestPracticesScore(report)).toBeGreaterThanOrEqual(95);
  });

  it('should have an SEO score greater than or equal to 95', () => {
    expect(seoScore(report)).toBeGreaterThanOrEqual(95);
  });
});
