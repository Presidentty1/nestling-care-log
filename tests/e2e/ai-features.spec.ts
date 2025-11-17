import { test, expect } from '@playwright/test';

test.describe('AI Features', () => {
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

  test('should show nap prediction on home page', async ({ page }) => {
    await page.goto('/home');
    
    // Wait for page to load
    await page.waitForTimeout(2000);
    
    // Nap window or prediction should be visible
    const napElement = page.locator('text=/Nap|Sleep|Window/i').first();
    await expect(napElement).toBeVisible({ timeout: 10000 });
  });

  test('should navigate to AI Assistant', async ({ page }) => {
    await page.goto('/home');
    
    // Navigate to AI Assistant
    await page.click('a[href="/ai-assistant"]');
    await expect(page).toHaveURL('/ai-assistant');
    await expect(page.locator('text=/AI Assistant|Chat/i')).toBeVisible();
  });

  test('should show cry insights page', async ({ page }) => {
    await page.goto('/cry-insights');
    await expect(page.locator('text=/Cry|Analysis/i')).toBeVisible();
  });

  test('should display AI assistant input', async ({ page }) => {
    await page.goto('/ai-assistant');
    
    // Should have textarea or input for questions
    const input = page.locator('textarea, input[type="text"]').first();
    await expect(input).toBeVisible();
  });
});
