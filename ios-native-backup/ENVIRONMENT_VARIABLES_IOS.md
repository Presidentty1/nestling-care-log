# iOS Environment Variables Setup

This guide explains how to configure environment variables for the Nestling iOS app.

## Required Environment Variables

The iOS app requires the following environment variables:

- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous/public key
- `SENTRY_DSN`: Your Sentry DSN for crash reporting (optional for development)
- `ENVIRONMENT`: Environment name (development, staging, production)

## Setting Up Environment Variables in Xcode

### Method 1: Using Xcode Schemes (Recommended)

1. **Open Xcode** and select your project
2. **Go to Product > Scheme > Edit Scheme** (or press `Cmd + Shift + ,`)
3. **Select the "Run" phase** from the left sidebar
4. **Go to the "Arguments" tab**
5. **Add environment variables in the "Environment Variables" section:**

   ```
   Name: SUPABASE_URL, Value: https://your-project.supabase.co
   Name: SUPABASE_ANON_KEY, Value: your-anon-key-here
   Name: SENTRY_DSN, Value: https://your-dsn@sentry.io/project-id
   Name: ENVIRONMENT, Value: development
   ```

6. **Create different schemes** for different environments:
   - `Nestling-Development`
   - `Nestling-Staging`
   - `Nestling-Production`

### Method 2: Using Build Configurations

1. **Create xcconfig files** for each environment:

   `Development.xcconfig`:

   ```
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = your-anon-key-here
   SENTRY_DSN = https://your-dsn@sentry.io/project-id
   ENVIRONMENT = development
   ```

   `Production.xcconfig`:

   ```
   SUPABASE_URL = https://your-project.supabase.co
   SUPABASE_ANON_KEY = your-anon-key-here
   SENTRY_DSN = https://your-production-dsn@sentry.io/project-id
   ENVIRONMENT = production
   ```

2. **Add the xcconfig files to your project**
3. **Set them in Build Settings > Preprocessor Macros** for each configuration

### Method 3: Using .env files (Alternative)

While not standard for iOS, you can create a simple environment loader:

1. **Create a `.env` file** in the project root (add to .gitignore):

   ```
   SUPABASE_URL=https://your-project.supabase.co
   SUPABASE_ANON_KEY=your-anon-key-here
   SENTRY_DSN=https://your-dsn@sentry.io/project-id
   ENVIRONMENT=development
   ```

2. **Create an environment loader** (add to your AppDelegate or main app file):

   ```swift
   import Foundation

   class Environment {
       static let shared = Environment()

       private var envVars: [String: String] = [:]

       private init() {
           loadEnvFile()
       }

       private func loadEnvFile() {
           guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
               print("⚠️ .env file not found")
               return
           }

           do {
               let content = try String(contentsOfFile: path, encoding: .utf8)
               let lines = content.components(separatedBy: .newlines)

               for line in lines {
                   let components = line.components(separatedBy: "=")
                   if components.count == 2 {
                       let key = components[0].trimmingCharacters(in: .whitespaces)
                       let value = components[1].trimmingCharacters(in: .whitespaces)
                       envVars[key] = value
                   }
               }
           } catch {
               print("❌ Failed to load .env file: \(error)")
           }
       }

       func get(_ key: String) -> String? {
           return envVars[key] ?? ProcessInfo.processInfo.environment[key]
       }
   }
   ```

## Security Considerations

1. **Never commit real credentials** to version control
2. **Use different keys** for different environments
3. **Rotate keys regularly** especially after any potential exposure
4. **Use environment-specific configurations** for production vs development

## Testing Environment Variables

To verify your environment variables are set correctly:

```swift
// In any Swift file, you can check:
let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"]
let anonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]
let sentryDSN = ProcessInfo.processInfo.environment["SENTRY_DSN"]

print("SUPABASE_URL: \(supabaseURL ?? "Not set")")
print("SUPABASE_ANON_KEY: \(anonKey != nil ? "Set" : "Not set")")
print("SENTRY_DSN: \(sentryDSN ?? "Not set")")
```

## Build Script Integration

You can also set environment variables via build scripts in Xcode:

1. **Add a Run Script phase** to your build phases
2. **Add the following script**:

```bash
#!/bin/bash
# Set environment variables for build
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key-here"
```

Note: This approach exposes credentials in build logs, so it's less secure than scheme-based configuration.

## CI/CD Setup

For automated builds, set environment variables in your CI/CD system:

### GitHub Actions Example:

```yaml
- name: Build iOS App
  env:
    SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
    SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
    SENTRY_DSN: ${{ secrets.SENTRY_DSN }}
  run: xcodebuild -scheme Nestling ...
```

### Fastlane Example:

```ruby
lane :build do
  ENV["SUPABASE_URL"] = ENV["SUPABASE_URL"]
  ENV["SUPABASE_ANON_KEY"] = ENV["SUPABASE_ANON_KEY"]
  ENV["SENTRY_DSN"] = ENV["SENTRY_DSN"]

  build_app(
    scheme: "Nestling",
    # ... other options
  )
end
```
