#!/usr/bin/env node

/**
 * Security validation script for Nestling
 * Checks for common security issues and validates configurations
 */

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

class SecurityChecker {
  constructor() {
    this.issues = [];
    this.warnings = [];
  }

  log(message, type = 'info') {
    const timestamp = new Date().toISOString();
    console.log(`[${timestamp}] ${type.toUpperCase()}: ${message}`);
  }

  error(message) {
    this.issues.push(message);
    this.log(message, 'error');
  }

  warning(message) {
    this.warnings.push(message);
    this.log(message, 'warning');
  }

  success(message) {
    this.log(message, 'success');
  }

  // Check for hardcoded secrets
  checkHardcodedSecrets() {
    this.log('Checking for hardcoded secrets...');

    const secretPatterns = [
      /SUPABASE_URL\s*=\s*["'][^"']*supabase\.co["']/gi,
      /SUPABASE_ANON_KEY\s*=\s*["'][^"']{50,}["']/gi,
      /SENTRY_DSN\s*=\s*["'][^"']*sentry\.io["']/gi,
      /API_KEY|SECRET_KEY|TOKEN/gi,
      /password|Password/gi,
      /mongodb\+srv:\/\//gi,
      /postgresql:\/\//gi
    ];

    const filesToCheck = [
      'src/**/*.{ts,tsx,js,jsx}',
      'ios/**/*.{swift,m,h}',
      'android/**/*.{java,kt}',
      '*.{json,env,config}'
    ];

    // Simple file reading (in production, use glob patterns)
    try {
      const srcFiles = fs.readdirSync('src', { recursive: true })
        .filter(file => file.endsWith('.ts') || file.endsWith('.tsx') || file.endsWith('.js') || file.endsWith('.jsx'))
        .map(file => path.join('src', file));

      srcFiles.forEach(filePath => {
        try {
          const content = fs.readFileSync(filePath, 'utf8');
          secretPatterns.forEach(pattern => {
            const matches = content.match(pattern);
            if (matches) {
              // Filter out legitimate environment variable usage
              const filteredMatches = matches.filter(match =>
                !match.includes('process.env') &&
                !match.includes('ProcessInfo.processInfo.environment') &&
                !match.includes('Bundle.main.infoDictionary')
              );
              if (filteredMatches.length > 0) {
                this.error(`Potential hardcoded secret in ${filePath}: ${filteredMatches[0]}`);
              }
            }
          });
        } catch (err) {
          this.warning(`Could not read file ${filePath}: ${err.message}`);
        }
      });

      this.success('Hardcoded secrets check completed');
    } catch (err) {
      this.warning(`Could not check for hardcoded secrets: ${err.message}`);
    }
  }

  // Check environment variable configuration
  checkEnvironmentVariables() {
    this.log('Checking environment variable configuration...');

    // Check for .env files
    const envFiles = ['.env', '.env.local', '.env.development', '.env.production'];
    envFiles.forEach(file => {
      if (fs.existsSync(file)) {
        this.error(`Environment file ${file} should not be committed`);
      }
    });

    // Check for template files
    if (!fs.existsSync('ios/Environment.xcconfig.template')) {
      this.warning('iOS environment template not found');
    }

    this.success('Environment variable configuration check completed');
  }

  // Check for insecure dependencies
  checkDependencies() {
    this.log('Checking dependencies...');

    try {
      const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
      const dependencies = { ...packageJson.dependencies, ...packageJson.devDependencies };

      // Check for known insecure packages (simplified check)
      const insecurePackages = [
        'left-pad', // Example of vulnerable package
        // Add more known insecure packages as needed
      ];

      insecurePackages.forEach(pkg => {
        if (dependencies[pkg]) {
          this.error(`Potentially insecure package found: ${pkg}@${dependencies[pkg]}`);
        }
      });

      this.success('Dependency security check completed');
    } catch (err) {
      this.warning(`Could not check dependencies: ${err.message}`);
    }
  }

  // Check for proper input sanitization
  checkInputSanitization() {
    this.log('Checking input sanitization...');

    // Check if sanitization utility exists
    if (!fs.existsSync('src/lib/sanitization.ts')) {
      this.error('Input sanitization utility not found');
      return;
    }

    // Check if sanitization is imported in key files
    const keyFiles = [
      'src/components/sheets/FeedForm.tsx',
      'src/components/sheets/DiaperForm.tsx',
      'src/services/eventsService.ts',
      'src/services/babyService.ts'
    ];

    keyFiles.forEach(file => {
      try {
        const content = fs.readFileSync(file, 'utf8');
        if (!content.includes('sanitization') && !content.includes('sanitize')) {
          this.warning(`Input sanitization not found in ${file}`);
        }
      } catch (err) {
        this.warning(`Could not check sanitization in ${file}: ${err.message}`);
      }
    });

    this.success('Input sanitization check completed');
  }

  // Check for HTTPS configuration
  checkHTTPSConfiguration() {
    this.log('Checking HTTPS configuration...');

    // Check iOS ATS configuration
    const iosPlistPath = 'ios/Nestling/Nestling/Info.plist';
    if (fs.existsSync(iosPlistPath)) {
      try {
        const content = fs.readFileSync(iosPlistPath, 'utf8');
        if (!content.includes('NSAppTransportSecurity') || content.includes('<false/>')) {
          this.warning('iOS App Transport Security may not be properly configured');
        }
      } catch (err) {
        this.warning(`Could not check iOS ATS: ${err.message}`);
      }
    }

    this.success('HTTPS configuration check completed');
  }

  // Check for proper error handling
  checkErrorHandling() {
    this.log('Checking error handling...');

    const keyFiles = [
      'src/services/eventsService.ts',
      'src/services/babyService.ts',
      'src/lib/offlineQueue.ts'
    ];

    keyFiles.forEach(file => {
      try {
        const content = fs.readFileSync(file, 'utf8');
        if (!content.includes('try') || !content.includes('catch')) {
          this.warning(`Limited error handling found in ${file}`);
        }
      } catch (err) {
        this.warning(`Could not check error handling in ${file}: ${err.message}`);
      }
    });

    this.success('Error handling check completed');
  }

  // Generate security report
  generateReport() {
    console.log('\n' + '='.repeat(50));
    console.log('SECURITY AUDIT REPORT');
    console.log('='.repeat(50));

    if (this.issues.length > 0) {
      console.log('\n🚨 CRITICAL ISSUES:');
      this.issues.forEach((issue, index) => {
        console.log(`  ${index + 1}. ${issue}`);
      });
    }

    if (this.warnings.length > 0) {
      console.log('\n⚠️  WARNINGS:');
      this.warnings.forEach((warning, index) => {
        console.log(`  ${index + 1}. ${warning}`);
      });
    }

    if (this.issues.length === 0 && this.warnings.length === 0) {
      console.log('\n✅ No security issues found!');
    }

    console.log('\n' + '='.repeat(50));

    // Exit with error code if there are critical issues
    if (this.issues.length > 0) {
      process.exit(1);
    }
  }

  // Run all checks
  async run() {
    this.log('Starting security audit...');

    this.checkHardcodedSecrets();
    this.checkEnvironmentVariables();
    this.checkDependencies();
    this.checkInputSanitization();
    this.checkHTTPSConfiguration();
    this.checkErrorHandling();

    this.generateReport();
  }
}

// Run the security checker
if (require.main === module) {
  const checker = new SecurityChecker();
  checker.run().catch(err => {
    console.error('Security check failed:', err);
    process.exit(1);
  });
}

module.exports = SecurityChecker;




