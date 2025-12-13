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
    await page.goto('/onboarding');

    // Step 1: Welcome
    await expect(page.locator('text=Welcome to Nestling')).toBeVisible();
    await page.click('button:has-text("Let\'s get started")');

    // Step 2: Name
    await page.fill('input[id="name"]', 'Test Baby');
    await page.click('button:has-text("Next")');

    // Step 3: DOB
    await page.fill('input[placeholder="MM/DD/YYYY"]', '01/01/2024');
    await page.click('button:has-text("Next")');

    // Step 4: Preferences
    await page.click('text=Imperial');
    await page.click('button:has-text("Start Tracking")');

    // Should navigate to home
    await expect(page).toHaveURL('/home');
    await expect(page.locator('text=Test Baby')).toBeVisible();
  });

  test('should show validation errors for invalid data', async ({ page }) => {
    await page.goto('/onboarding');

    // Step 1: Welcome - click next
    await page.click('button:has-text("Let\'s get started")');

    // Step 2: Name - try to submit without filling
    await page.click('button:has-text("Next")');

    // Should show validation errors
    await expect(page.locator('text=Name is required')).toBeVisible();
  });

  test('should handle date of birth in future', async ({ page }) => {
    await page.goto('/onboarding');

    // Step 1: Welcome
    await page.click('button:has-text("Let\'s get started")');

    // Step 2: Name
    await page.fill('input[id="name"]', 'Test Baby');
    await page.click('button:has-text("Next")');

    // Step 3: DOB - try future date
    const futureDate = new Date();
    futureDate.setFullYear(futureDate.getFullYear() + 1);
    await page.fill('input[placeholder="MM/DD/YYYY"]', futureDate.toISOString().split('T')[0]);

    await page.click('button:has-text("Next")');

    // Should show error
    await expect(page.locator('text=Date of birth cannot be in the future')).toBeVisible();
  });

  test('should handle onboarding welcome step', async ({ page }) => {
    await page.goto('/onboarding');

    // Should start at welcome step
    await expect(page.locator('text=Welcome to Nestling')).toBeVisible();
    await expect(page.locator('text=The fastest way to track baby care')).toBeVisible();

    // Should show ValuePreview component
    await expect(page.locator('text=Track in 2 taps')).toBeVisible();

    // Should show time estimate
    await expect(page.locator('text=30 seconds to get started')).toBeVisible();
  });
});
