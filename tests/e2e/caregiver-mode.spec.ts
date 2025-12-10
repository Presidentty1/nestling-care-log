import { test, expect } from '@playwright/test';

test.describe('Caregiver Mode', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.clear();
      indexedDB.deleteDatabase('nestling');
    });

    // Setup: Complete onboarding
    await page.goto('/onboarding-simple');
    await page.fill('input[name="name"]', 'Test Baby');
    await page.fill('input[name="date_of_birth"]', '2024-01-01');
    await page.click('text=Metric');
    await page.click('button:has-text("Get Started")');
  });

  test('Toggle caregiver mode scales UI', async ({ page }) => {
    // Navigate to accessibility settings
    await page.click('a[href="/settings"]');
    await page.click('text=Accessibility');

    // Toggle caregiver mode
    const caregiverToggle = page.locator('button:has-text("Caregiver Mode")');
    await caregiverToggle.click();

    // Check that body has caregiver-mode class
    const body = page.locator('body');
    await expect(body).toHaveClass(/caregiver-mode/);

    // Verify text is larger (check computed font size)
    const headline = page.locator('.text-headline').first();
    if (await headline.isVisible()) {
      const fontSize = await headline.evaluate(el => window.getComputedStyle(el).fontSize);
      // Font should be scaled up from 22px
      const sizeNum = parseFloat(fontSize);
      expect(sizeNum).toBeGreaterThan(22);
    }
  });

  test('Caregiver mode persists across sessions', async ({ page }) => {
    // Enable caregiver mode
    await page.click('a[href="/settings"]');
    await page.click('text=Accessibility');
    await page.click('button:has-text("Caregiver Mode")');

    // Verify enabled
    await expect(page.locator('body')).toHaveClass(/caregiver-mode/);

    // Reload page
    await page.reload();

    // Should still be enabled
    await expect(page.locator('body')).toHaveClass(/caregiver-mode/);
  });

  test('Caregiver mode affects all interactive elements', async ({ page }) => {
    // Enable caregiver mode
    await page.click('a[href="/settings"]');
    await page.click('text=Accessibility');
    await page.click('button:has-text("Caregiver Mode")');

    // Go back to home
    await page.click('a[href="/home"]');

    // Check quick action buttons are larger
    const feedButton = page.locator('button:has-text("Feed")');
    const box = await feedButton.boundingBox();

    if (box) {
      // Height should be scaled (112px * 1.2 = 134px minimum)
      expect(box.height).toBeGreaterThan(130);
    }
  });
});
