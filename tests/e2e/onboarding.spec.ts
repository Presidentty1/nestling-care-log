import { test, expect } from '@playwright/test';

test.describe('Onboarding Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Clear local storage before each test
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.clear();
      indexedDB.deleteDatabase('nestling');
    });
  });

  test('should complete onboarding with valid data', async ({ page }) => {
    await page.goto('/onboarding-simple');

    // Fill baby name
    await page.fill('input[name="name"]', 'Test Baby');

    // Fill date of birth
    await page.fill('input[name="date_of_birth"]', '2024-01-01');

    // Select timezone (should be auto-detected)
    await expect(page.locator('text=Timezone')).toBeVisible();

    // Select units
    await page.click('text=Metric');

    // Submit form
    await page.click('button:has-text("Get Started")');

    // Should navigate to home
    await expect(page).toHaveURL('/home');
    await expect(page.locator('text=Test Baby')).toBeVisible();
  });

  test('should show validation errors for invalid data', async ({ page }) => {
    await page.goto('/onboarding-simple');

    // Try to submit without filling
    await page.click('button:has-text("Get Started")');

    // Should show validation errors
    await expect(page.locator('text=Name is required')).toBeVisible();
  });

  test('should handle date of birth in future', async ({ page }) => {
    await page.goto('/onboarding-simple');

    await page.fill('input[name="name"]', 'Test Baby');

    // Try future date
    const futureDate = new Date();
    futureDate.setFullYear(futureDate.getFullYear() + 1);
    await page.fill('input[name="date_of_birth"]', futureDate.toISOString().split('T')[0]);

    await page.click('button:has-text("Get Started")');

    // Should show error
    await expect(page.locator('text=Date cannot be in the future')).toBeVisible();
  });

  test('should create demo baby as fallback', async ({ page }) => {
    await page.goto('/onboarding-simple');

    // Click demo baby button if available
    const demoButton = page.locator('button:has-text("Create Demo Baby")');
    if (await demoButton.isVisible()) {
      await demoButton.click();
      await expect(page).toHaveURL('/home');
    }
  });
});
