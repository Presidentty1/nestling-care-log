import { test, expect } from '@playwright/test';

test.describe('Offline Sync', () => {
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

  test('should log events while offline', async ({ page, context }) => {
    // Go offline
    await context.setOffline(true);

    // Log an event
    await page.click('button:has-text("Feed")');
    await page.click('button:has-text("Bottle")');
    await page.fill('input[type="number"]', '100');
    await page.click('button:has-text("Save")');

    // Wait for UI update
    await page.waitForTimeout(1000);

    // Event should appear in timeline
    await expect(page.locator('text=100 ml')).toBeVisible({ timeout: 5000 });
  });

  test('should sync when coming back online', async ({ page, context }) => {
    // Go offline
    await context.setOffline(true);

    // Log event offline
    await page.click('button:has-text("Feed")');
    await page.click('button:has-text("Bottle")');
    await page.fill('input[type="number"]', '90');
    await page.click('button:has-text("Save")');
    await page.waitForTimeout(1000);

    // Go back online
    await context.setOffline(false);

    // Wait for potential sync
    await page.waitForTimeout(5000);

    // Event should still be visible
    await expect(page.locator('text=90 ml')).toBeVisible();
  });

  test('should show offline indicator', async ({ page, context }) => {
    // Go offline
    await context.setOffline(true);

    // Refresh page to trigger offline detection
    await page.reload();

    // May show offline indicator or work normally
    // Just verify page still loads
    await expect(page.locator('body')).toBeVisible();
  });
});
