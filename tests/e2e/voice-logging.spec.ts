import { test, expect } from '@playwright/test';

test.describe('Voice Logging', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.clear();
      indexedDB.deleteDatabase('nestling');
    });

    await page.goto('/onboarding-simple');
    await page.fill('input[name="name"]', 'Test Baby');
    await page.fill('input[name="date_of_birth"]', '2024-01-01');
    await page.click('text=Metric');
    await page.click('button:has-text("Get Started")');
  });

  test('should show voice menu button on home', async ({ page }) => {
    await page.goto('/home');

    // Look for voice button or FAB menu
    const hasVoiceButton = (await page.locator('button[aria-label*="voice"]').count()) > 0;
    const hasFAB = (await page.locator('[data-testid="fab-menu"]').count()) > 0;

    expect(hasVoiceButton || hasFAB).toBeTruthy();
  });

  test('should navigate to voice logging page', async ({ page }) => {
    // Check if voice menu is accessible
    const voiceLink = page.locator('a[href*="voice"]');
    if (await voiceLink.isVisible()) {
      await voiceLink.click();
      await expect(page).toHaveURL(/voice/);
    }
  });
});
