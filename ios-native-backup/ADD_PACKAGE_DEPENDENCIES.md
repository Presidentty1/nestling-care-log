# Adding Swift Package Dependencies

The project needs the `ZipArchive` package. Follow these steps to add it:

## Steps to Add ZipArchive Package

1. **Open the project in Xcode:**

   ```bash
   open ios/Nestling/Nestling.xcodeproj
   ```

2. **Select the project** in the Project Navigator (blue icon at the top)

3. **Select the "Nestling" target** in the main editor area

4. **Go to the "Package Dependencies" tab**

5. **Click the "+" button** at the bottom left

6. **Enter the package URL:**

   ```
   https://github.com/ZipArchive/ZipArchive.git
   ```

7. **Set the version:**
   - Choose "Up to Next Major Version"
   - Set minimum version to `2.5.0` or leave default

8. **Click "Add Package"**

9. **When prompted, select "ZipArchive"** and ensure it's added to the "Nestling" target

10. **Click "Add Package"**

Xcode will automatically resolve and download the package.

## Alternative: Quick Add Script

If you prefer, you can also add it via Xcode's menu:

1. **File → Add Package Dependencies...**
2. Enter: `https://github.com/ZipArchive/ZipArchive.git`
3. Click "Add Package"
4. Select "ZipArchive" and add to "Nestling" target

## Verify

After adding, you should see:

- The package listed under "Package Dependencies" in Project Navigator
- No more build errors about missing ZipArchive module

## Build Again

Once the package is added:

1. Build: ⌘B
2. Run: ⌘R
