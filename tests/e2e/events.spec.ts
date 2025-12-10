import { test, expect } from '@playwright/test';

test.describe('Event Logging', () => {
  test.beforeEach(async ({ page }) => {
    // Setup: Create a baby first
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
    await expect(page).toHaveURL('/home');
  });

  test('should log a bottle feed', async ({ page }) => {
    // Click Feed button
    await page.click('button:has-text("Feed")');

    // Should open feed sheet
    await expect(page.locator('text=Log Feed')).toBeVisible();

    // Select Bottle tab
    await page.click('text=Bottle');

    // Fill amount
    await page.fill('input[type="number"]', '120');

    // Click save
    await page.click('button:has-text("Save")');

    // Should close sheet and show event in timeline
    await expect(page.locator('text=120 ml')).toBeVisible();
  });

  test('should log sleep with timer', async ({ page }) => {
    // Click Sleep button
    await page.click('button:has-text("Sleep")');

    // Should open sleep sheet
    await expect(page.locator('text=Log Sleep')).toBeVisible();

    // Start timer
    await page.click('button:has-text("Start")');

    // Wait a bit
    await page.waitForTimeout(2000);

    // Stop timer
    await page.click('button:has-text("Stop")');

    // Save
    await page.click('button:has-text("Save")');

    // Should show in timeline
    await expect(page.locator('[data-testid="timeline-item"]')).toContainText('Nap');
  });

  test('should log diaper change', async ({ page }) => {
    // Click Diaper button
    await page.click('button:has-text("Diaper")');

    // Should open diaper sheet
    await expect(page.locator('text=Log Diaper')).toBeVisible();

    // Select type
    await page.click('text=Wet');

    // Save
    await page.click('button:has-text("Save")');

    // Should show in timeline
    await expect(page.locator('text=Diaper')).toBeVisible();
  });

  test('should edit an event', async ({ page }) => {
    // Create an event first
    await page.click('button:has-text("Feed")');
    await page.click('text=Bottle');
    await page.fill('input[type="number"]', '120');
    await page.click('button:has-text("Save")');

    // Click on the event to edit
    await page.click('[data-testid="timeline-item"]');

    // Should open edit mode
    await expect(page.locator('input[value="120"]')).toBeVisible();

    // Change amount
    await page.fill('input[type="number"]', '150');
    await page.click('button:has-text("Save")');

    // Should update in timeline
    await expect(page.locator('text=150 ml')).toBeVisible();
  });

  test('should delete an event', async ({ page }) => {
    // Create an event
    await page.click('button:has-text("Feed")');
    await page.click('text=Bottle');
    await page.fill('input[type="number"]', '120');
    await page.click('button:has-text("Save")');

    // Click menu on event
    await page.click('[data-testid="event-menu"]');

    // Click delete
    await page.click('text=Delete');

    // Confirm deletion
    await page.click('button:has-text("Delete")');

    // Event should be gone
    await expect(page.locator('text=120 ml')).not.toBeVisible();
  });
});
