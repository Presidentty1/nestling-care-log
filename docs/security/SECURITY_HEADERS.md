# Security Headers Configuration

This document outlines security headers that should be implemented for web deployments of Nestling components.

## Recommended Security Headers

### Content Security Policy (CSP)

For React applications, implement a restrictive CSP:

```nginx
Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://*.supabase.co https://*.sentry.io; frame-ancestors 'none';
```

### Other Essential Headers

```nginx
# Prevent clickjacking
X-Frame-Options: DENY

# Prevent MIME type sniffing
X-Content-Type-Options: nosniff

# Enable XSS filtering
X-XSS-Protection: 1; mode=block

# Control referrer information
Referrer-Policy: strict-origin-when-cross-origin

# Force HTTPS
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload

# Control browser features
Permissions-Policy: geolocation=(), microphone=(), camera=(), payment=()

# Remove server information
Server: [removed]

# Prevent caching of sensitive content
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache
```

## Implementation Examples

### Nginx Configuration

```nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL configuration
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; connect-src 'self' https://*.supabase.co;" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

    # Hide server information
    more_clear_headers Server;

    location / {
        # Your app configuration
        try_files $uri $uri/ /index.html;
    }
}
```

### Apache Configuration

```apache
<VirtualHost *:443>
    ServerName your-domain.com

    # Security headers
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
    Header always set Permissions-Policy "geolocation=(), microphone=(), camera=()"

    # SSL configuration
    SSLEngine on
    SSLCertificateFile /path/to/cert.pem
    SSLCertificateKeyFile /path/to/key.pem

    # Your app configuration
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
    </Directory>
</VirtualHost>
```

### Express.js Middleware

```javascript
const helmet = require('helmet');
const express = require('express');
const app = express();

// Security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      imgSrc: ["'self'", "data:", "https:"],
      connectSrc: ["'self'", "https://*.supabase.co"],
      frameAncestors: ["'none'"],
    },
  },
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  },
  noSniff: true,
  xssFilter: true,
  referrerPolicy: { policy: "strict-origin-when-cross-origin" }
}));

// Additional custom headers
app.use((req, res, next) => {
  res.setHeader('Permissions-Policy', 'geolocation=(), microphone=(), camera=()');
  next();
});
```

### Capacitor/Cordova Considerations

Since Nestling is primarily a mobile app built with Capacitor, security headers are handled differently:

1. **iOS**: Security is managed through App Transport Security (ATS) in Info.plist
2. **Android**: Security is managed through Network Security Configuration
3. **WebView**: Capacitor handles WebView security automatically

For Capacitor apps, ensure:

```xml
<!-- Android Network Security Config -->
<network-security-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">supabase.co</domain>
        <domain includeSubdomains="true">sentry.io</domain>
    </domain-config>
</network-security-config>
```

```plist
<!-- iOS Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSAllowsArbitraryLoadsForMedia</key>
    <false/>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <false/>
    <key>NSAllowsLocalNetworking</key>
    <false/>
</dict>
```

## Testing Security Headers

### Online Tools
- [securityheaders.com](https://securityheaders.com)
- [observatory.mozilla.org](https://observatory.mozilla.org)

### Manual Testing

```bash
# Check headers with curl
curl -I https://your-domain.com

# Check CSP with browser dev tools
# Open browser dev tools > Console > Check for CSP violations

# Test HSTS
curl -I https://your-domain.com
# Should include: Strict-Transport-Security header
```

## Monitoring

Set up monitoring for security header compliance:

1. **Automated checks** in CI/CD pipeline
2. **Regular security scans** with tools like OWASP ZAP
3. **Header monitoring** with services like UpGuard or custom scripts
4. **CSP violation reporting** to monitor for bypass attempts

## Updates

Security headers should be reviewed and updated:

- **Monthly**: Review for new header recommendations
- **Quarterly**: Test header effectiveness
- **After updates**: Verify headers still apply correctly
- **After incidents**: Review and strengthen headers as needed




