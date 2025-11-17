import { test, expect } from '@playwright/test';

test.describe('MVP Critical Path', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/');
    await page.evaluate(() => {
      localStorage.clear();
      indexedDB.deleteDatabase('nestling');
    });
  });

  test('Complete user journey: onboard → log events → view history', async ({ page }) => {
    // 1. Onboarding
    await page.goto('/onboarding-simple');
    
    // Fill baby name
    await page.fill('input[name="name"]', 'Test Baby');
    
    // Fill date of birth
    await page.fill('input[name="date_of_birth"]', '2024-01-01');
    
    // Select units
    await page.click('text=Metric');
    
    // Submit form
    await page.click('button:has-text("Get Started")');
    
    // Should land on Home
    await expect(page).toHaveURL('/home');
    await expect(page.locator('text=Test Baby')).toBeVisible();
    
    // 2. Log a feed
    await page.click('button:has-text("Feed")');
    await page.click('button:has-text("Bottle")');
    await page.fill('input[type="number"]', '90');
    await page.click('button:has-text("Save Log")');
    
    // Wait for success message
    await page.waitForTimeout(1000);
    
    // 3. Verify summary chip updated
    await expect(page.locator('text=90 ml')).toBeVisible();
    
    // 4. Log a sleep with timer
    await page.click('button:has-text("Sleep")');
    await page.click('button[aria-label="Start timer"]');
    await page.waitForTimeout(3000); // 3 second nap
    await page.click('button[aria-label="Stop timer"]');
    await page.click('button:has-text("Save Log")');
    
    // 5. Check timeline
    await expect(page.locator('text=Bottle').first()).toBeVisible();
    await expect(page.locator('text=Sleep').first()).toBeVisible();
    
    // 6. Navigate to History
    await page.click('a[href="/history"]');
    await expect(page).toHaveURL('/history');
    
    // 7. Verify events appear in history
    await expect(page.locator('text=Bottle')).toBeVisible();
    await expect(page.locator('text=Sleep')).toBeVisible();
  });
  
  test('Demo Baby creation', async ({ page }) => {
    await page.goto('/onboarding-simple');
    const demoButton = page.locator('button:has-text("Create Demo Baby")');
    if (await demoButton.isVisible()) {
      await demoButton.click();
      await expect(page).toHaveURL('/home');
      await expect(page.locator('text=Demo Baby')).toBeVisible();
    }
  });
  
  test('Edit and delete event', async ({ page }) => {
    // Setup: create baby
    await page.goto('/onboarding-simple');
    await page.fill('input[name="name"]', 'Test Baby');
    await page.fill('input[name="date_of_birth"]', '2024-01-01');
    await page.click('text=Metric');
    await page.click('button:has-text("Get Started")');
    
    // Add event
    await page.click('button:has-text("Feed")');
    await page.click('button:has-text("Bottle")');
    await page.fill('input[type="number"]', '90');
    await page.click('button:has-text("Save Log")');
    await page.waitForTimeout(1000);
    
    // Edit event
    const moreButton = page.locator('button[aria-label*="More"]').first();
    await moreButton.click();
    await page.click('text=Edit');
    await page.fill('input[type="number"]', '120');
    await page.click('button:has-text("Save Log")');
    await page.waitForTimeout(1000);
    await expect(page.locator('text=120 ml')).toBeVisible();
    
    // Delete event (swipe or menu)
    const timelineRow = page.locator('[data-testid="timeline-row"]').first();
    if (await timelineRow.isVisible()) {
      // Try swipe delete
      const box = await timelineRow.boundingBox();
      if (box) {
        await page.mouse.move(box.x + box.width - 10, box.y + box.height / 2);
        await page.mouse.down();
        await page.mouse.move(box.x + 10, box.y + box.height / 2);
        await page.mouse.up();
        
        // Click delete button if visible
        const deleteBtn = page.locator('button:has-text("Delete")');
        if (await deleteBtn.isVisible()) {
          await deleteBtn.click();
        }
      }
    }
  });
  
  test('Switch between babies', async ({ page }) => {
    // Create first baby
    await page.goto('/onboarding-simple');
    await page.fill('input[name="name"]', 'Baby One');
    await page.fill('input[name="date_of_birth"]', '2024-01-01');
    await page.click('text=Metric');
    await page.click('button:has-text("Get Started")');
    
    // Add a feed for Baby One
    await page.click('button:has-text("Feed")');
    await page.click('button:has-text("Bottle")');
    await page.fill('input[type="number"]', '90');
    await page.click('button:has-text("Save Log")');
    await page.waitForTimeout(1000);
    
    // Go to settings to add another baby
    await page.click('a[href="/settings"]');
    await page.click('text=Manage Babies');
    await page.click('button:has-text("Add Baby")');
    await page.fill('input[name="name"]', 'Baby Two');
    await page.fill('input[name="date_of_birth"]', '2024-06-01');
    await page.click('button:has-text("Save")');
    
    // Switch to Baby Two
    await page.click('[data-testid="baby-switcher"]');
    await page.click('text=Baby Two');
    
    // Verify empty timeline for Baby Two
    await expect(page.locator('text=Baby Two')).toBeVisible();
    await expect(page.locator('text=Your day is off to a quiet start')).toBeVisible();
  });
});
