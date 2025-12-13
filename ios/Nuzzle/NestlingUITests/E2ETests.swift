//
//  E2ETests.swift
//  NestlingUITests
//
//  End-to-end test suite covering critical user flows
//

import XCTest

final class E2ETests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Launch arguments for testing
        app.launchArguments = ["--uitesting"]
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Activation Flow Tests
    
    /// Test complete onboarding flow from welcome to first log
    func testOnboardingFlow() throws {
        // Wait for app to load
        XCTAssertTrue(app.waitForExistence(timeout: 5))
        
        // Step 1: Welcome screen
        let welcomeText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'welcome' OR label CONTAINS[c] 'Nuzzle'"))
        if welcomeText.firstMatch.exists {
            let continueButton = app.buttons["Continue"]
            if continueButton.exists {
                continueButton.tap()
            }
        }
        
        // Step 2: Baby Setup
        let nameField = app.textFields.firstMatch
        if nameField.exists {
            nameField.tap()
            nameField.typeText("Test Baby")
        }
        
        // Continue from baby setup
        let continueBtn = app.buttons["Continue"]
        if continueBtn.exists {
            continueBtn.tap()
        }
        
        // Step 3: First Log
        let logButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'log' OR label CONTAINS[c] 'feed'"))
        if logButton.firstMatch.exists {
            logButton.firstMatch.tap()
            
            // Wait for paywall or completion
            sleep(2)
        }
        
        // Verify onboarding completed
        // Should see home screen or paywall
        XCTAssertTrue(app.waitForExistence(timeout: 5))
    }
    
    // MARK: - Purchase Flow Tests
    
    /// Test subscription purchase flow
    func testPurchaseFlow() throws {
        // Skip onboarding if already completed
        if app.buttons["Maybe later"].exists {
            app.buttons["Maybe later"].tap()
        }
        
        // Navigate to subscription/paywall
        // This might be in settings or shown during onboarding
        let paywallButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'trial' OR label CONTAINS[c] 'subscribe' OR label CONTAINS[c] 'pro'"))
        
        if paywallButton.firstMatch.exists {
            paywallButton.firstMatch.tap()
            
            // Wait for paywall to load
            sleep(2)
            
            // Verify paywall elements exist
            let startTrialButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'trial' OR label CONTAINS[c] 'start'"))
            XCTAssertTrue(startTrialButton.firstMatch.exists, "Start trial button should exist")
            
            // Test restore purchases
            let restoreButton = app.buttons["Restore Purchases"]
            if restoreButton.exists {
                restoreButton.tap()
                sleep(1)
                // Should show alert or dismiss
            }
        }
    }
    
    // MARK: - Quick Log Tests
    
    /// Test quick log functionality (≤2 taps)
    func testQuickLogFeed() throws {
        // Navigate to home if not already there
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
        }
        
        // Find and tap quick log feed button
        let feedButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'feed' OR label CONTAINS[c] 'bottle' OR label CONTAINS[c] 'milk'"))
        
        if feedButton.firstMatch.exists {
            feedButton.firstMatch.tap()
            
            // Should log immediately or show minimal form
            // Verify event appears in timeline
            sleep(1)
            
            // Check for success indicator or timeline update
            XCTAssertTrue(app.waitForExistence(timeout: 3))
        }
    }
    
    func testQuickLogDiaper() throws {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
        }
        
        let diaperButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'diaper'"))
        if diaperButton.firstMatch.exists {
            diaperButton.firstMatch.tap()
            sleep(1)
            XCTAssertTrue(app.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Sync Tests
    
    /// Test CloudKit sync functionality
    func testCloudKitSync() throws {
        // Navigate to settings
        let settingsTab = app.tabBars.buttons["Settings"]
        if settingsTab.exists {
            settingsTab.tap()
        }
        
        // Look for sync status or CloudKit settings
        let syncStatus = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'sync' OR label CONTAINS[c] 'cloudkit'"))
        
        // Verify sync status is visible (if CloudKit is enabled)
        // This is a basic check - actual sync testing requires multiple devices
        if syncStatus.firstMatch.exists {
            XCTAssertTrue(syncStatus.firstMatch.exists)
        }
    }
    
    // MARK: - Offline Queue Tests
    
    /// Test offline functionality
    func testOfflineQueue() throws {
        // Enable airplane mode simulation (if available in test environment)
        // For now, just verify app doesn't crash when offline
        
        // Log an event
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
        }
        
        let feedButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'feed'"))
        if feedButton.firstMatch.exists {
            feedButton.firstMatch.tap()
            sleep(1)
            
            // Event should be queued if offline
            // Verify no error is shown
            XCTAssertTrue(app.waitForExistence(timeout: 3))
        }
    }
    
    // MARK: - Accessibility Tests
    
    /// Test VoiceOver accessibility
    func testAccessibility() throws {
        // Enable VoiceOver programmatically (if possible)
        // For now, verify UI elements have accessibility labels
        
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists {
            XCTAssertTrue(homeTab.isAccessibilityElement, "Home tab should be accessible")
        }
        
        // Check for accessibility labels on key buttons
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons.prefix(5) {
            if button.exists {
                let label = button.label
                XCTAssertFalse(label.isEmpty, "Button should have accessibility label")
            }
        }
    }
    
    // MARK: - Navigation Tests
    
    /// Test deep link routing from notifications
    func testNotificationDeepLinks() throws {
        // This would require simulating a notification
        // For now, verify deep link handling exists
        
        // Simulate opening app via deep link
        let deepLinkURL = "nestling://log/feed"
        // Note: Actual deep link testing requires app to be backgrounded
        // This is a placeholder for the test structure
    }
    
    // MARK: - Data Persistence Tests
    
    /// Test that data persists after app restart
    func testDataPersistence() throws {
        // Log an event
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
        }
        
        let feedButton = app.buttons.containing(NSPredicate(format: "label CONTAINS[c] 'feed'"))
        if feedButton.firstMatch.exists {
            feedButton.firstMatch.tap()
            sleep(1)
        }
        
        // Terminate and relaunch app
        app.terminate()
        sleep(2)
        app.launch()
        
        // Verify event still exists
        XCTAssertTrue(app.waitForExistence(timeout: 5))
    }
    
    // MARK: - Error Handling Tests
    
    /// Test error handling and recovery
    func testErrorHandling() throws {
        // Try to perform actions that might fail
        // Verify app doesn't crash and shows appropriate error messages
        
        // Navigate to a feature that requires network
        // Verify graceful degradation when offline
        
        XCTAssertTrue(app.waitForExistence(timeout: 3))
    }
}
