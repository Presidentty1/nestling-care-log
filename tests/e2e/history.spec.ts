import { test, expect } from '@playwright/test';

test.describe('History Screen', () => {
  test.beforeEach(async ({ page }) => {
    // Setup: Create baby and some events
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

  test('should navigate to history page', async ({ page }) => {
    // Click History in nav
    await page.click('a[href="/history"]');

    // Should show history page
    await expect(page).toHaveURL('/history');
    await expect(page.locator('text=History')).toBeVisible();
  });

  test('should show day strip with selectable dates', async ({ page }) => {
    await page.goto('/history');

    // Should show day strip
    await expect(page.locator('[data-testid="day-strip"]')).toBeVisible();

    // Should show today as selected
    const today = new Date().getDate().toString();
    await expect(page.locator(`[data-selected="true"]:has-text("${today}")`)).toBeVisible();
  });

  test('should switch between days', async ({ page }) => {
    await page.goto('/history');

    // Get all day buttons
    const dayButtons = await page.locator('[data-testid="day-button"]').all();

    if (dayButtons.length > 1) {
      // Click second day
      await dayButtons[1].click();

      // Should update selected state
      await expect(dayButtons[1]).toHaveAttribute('data-selected', 'true');
    }
  });

  test('should show correct summary for selected day', async ({ page }) => {
    // Create an event today
    await page.goto('/home');
    await page.click('button:has-text("Feed")');
    await page.click('text=Bottle');
    await page.fill('input[type="number"]', '120');
    await page.click('button:has-text("Save")');

    // Go to history
    await page.goto('/history');

    // Should show summary chip with feed count
    await expect(page.locator('text=1 feed')).toBeVisible();
    await expect(page.locator('text=120 ml')).toBeVisible();
  });

  test('should show empty state for days with no events', async ({ page }) => {
    await page.goto('/history');

    // Click yesterday or any past day
    const yesterdayButton = page.locator('[data-testid="day-button"]').nth(1);
    await yesterdayButton.click();

    // Should show empty state
    await expect(page.locator('text=No events logged')).toBeVisible();
  });
});
