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

  test('should test cry recorder with context data', async ({ page }) => {
    // First add some events to provide context
    await page.evaluate(async () => {
      const supabase = window.supabase;
      const { data: { user } } = await supabase.auth.getUser();
      const { data: family } = await supabase
        .from('family_members')
        .select('family_id')
        .eq('user_id', user.id)
        .single();

      // Add a feed event from 2 hours ago
      const twoHoursAgo = new Date(Date.now() - 2 * 60 * 60 * 1000);
      await supabase.from('events').insert({
        baby_id: localStorage.getItem('selected_baby_id'),
        family_id: family.family_id,
        type: 'feed',
        subtype: 'breast',
        start_time: twoHoursAgo.toISOString(),
        amount: 120,
        unit: 'ml'
      });

      // Add a sleep event from 3 hours ago
      const threeHoursAgo = new Date(Date.now() - 3 * 60 * 60 * 1000);
      const threeHoursAgoEnd = new Date(Date.now() - 1 * 60 * 60 * 1000);
      await supabase.from('events').insert({
        baby_id: localStorage.getItem('selected_baby_id'),
        family_id: family.family_id,
        type: 'sleep',
        start_time: threeHoursAgo.toISOString(),
        end_time: threeHoursAgoEnd.toISOString()
      });
    });

    await page.goto('/cry-insights');

    // Check that the cry recorder loads with proper context
    const recordButton = page.locator('button:has-text("Start Recording")');
    await expect(recordButton).toBeVisible();

    // Check that free usage indicator is shown (for non-Pro users)
    const freeUsageText = page.locator('text=/free.*Cry.*Insight/i');
    await expect(freeUsageText).toBeVisible();
  });

  test('should display AI assistant input', async ({ page }) => {
    await page.goto('/ai-assistant');

    // Should have textarea or input for questions
    const input = page.locator('textarea, input[type="text"]').first();
    await expect(input).toBeVisible();
  });

  test('should test AI consent flow', async ({ page }) => {
    await page.goto('/ai-assistant');

    // Check that medical disclaimer is visible
    const disclaimer = page.locator('text=/not a replacement for medical advice/i');
    await expect(disclaimer).toBeVisible();

    // If AI is disabled, should show appropriate message
    const disabledMessage = page.locator('text=/AI.*disabled/i');
    // Note: This may or may not be visible depending on settings
  });

  test('should test predictions feature', async ({ page }) => {
    await page.goto('/predictions');

    // Wait for page to load
    await page.waitForTimeout(2000);

    // Should show prediction interface
    const predictionButton = page.locator('button:has-text("Generate")').first();
    await expect(predictionButton).toBeVisible();
  });
});
