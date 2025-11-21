# Security Vulnerabilities Found & Fixes

**Scan Date:** November 21, 2025  
**Report:** security-reports/snyk-scan-20251121-151050.txt

---

## Summary of Issues Found

### 🔴 High Severity (3 issues)

1. **Result Service**: Body-parser Asymmetric Resource Consumption
2. **Result Service**: ws Denial of Service (DoS)
3. **Result Service**: cross-spawn ReDoS & glob Command Injection

### 🟡 Medium Severity (11 issues)

1. **Vote Service**: Debug Mode Enabled (1 issue)
2. **Result Service**: Code issues (3 issues)
3. **Result Service**: Dependency vulnerabilities (4 issues)
4. **Kubernetes**: Security context issues (3 issues)

---

## 1. Vote Service Fixes (Python/Flask)

### Issue: Debug Mode Enabled

**File:** `vote/app.py`, line 56  
**Severity:** Medium  
**Risk:** Security risk if accessible by untrusted parties

**Fix:**

```python
# BEFORE (Insecure)
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80, debug=True)

# AFTER (Secure)
if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80, debug=False)
```

**Apply Fix:**

```bash
sed -i 's/debug=True/debug=False/' vote/app.py
```

---

## 2. Result Service Fixes (Node.js/Express)

### Issue 1: X-Powered-By Header Exposure

**File:** `result/server.js`, line 6  
**Severity:** Medium  
**Risk:** Exposes framework information to attackers

**Fix: Install and use Helmet middleware**

```bash
cd result/
npm install helmet@latest --save
cd ..
```

**Update server.js:**

```javascript
// Add at the top with other requires
const helmet = require('helmet');

// Add after creating express app
app.use(helmet());
app.disable('x-powered-by');
```

### Issue 2: No Rate Limiting

**File:** `result/server.js`, line 84  
**Severity:** Medium  
**Risk:** DoS attacks possible

**Fix: Install express-rate-limit**

```bash
cd result/
npm install express-rate-limit@latest --save
cd ..
```

**Update server.js:**

```javascript
// Add at the top
const rateLimit = require('express-rate-limit');

// Add rate limiting middleware
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use(limiter);
```

### Issue 3: CSRF Protection Disabled

**File:** `result/server.js`, line 6  
**Severity:** Medium  
**Risk:** Cross-Site Request Forgery attacks

**Fix: Install csurf middleware**

```bash
cd result/
npm install csurf@latest --save
cd ..
```

**Update server.js:**

```javascript
// Add at the top
const csrf = require('csurf');
const csrfProtection = csrf({ cookie: true });

// Add CSRF protection to POST routes
app.use(csrfProtection);
```

### Issue 4: Outdated Dependencies

**Severity:** High (body-parser), Medium (express, cookie-parser, socket.io)

**Fix: Upgrade packages**

```bash
cd result/
npm install express@4.21.2 --save
npm install cookie-parser@1.4.7 --save
npm install socket.io@4.8.0 --save
npm install ws@8.17.1 --save
npm audit fix --force
cd ..
```

**Update package.json:**

```json
{
  "dependencies": {
    "body-parser": "^1.20.3",
    "cookie-parser": "^1.4.7",
    "express": "^4.21.2",
    "socket.io": "^4.8.0",
    "ws": "^8.17.1"
  }
}
```

---

## 3. Kubernetes Security Fixes

### Issue 1: Worker Deployment - Missing runAsNonRoot

**File:** `k8s/manifests/07-worker.yaml`  
**Severity:** Medium

**Fix:**

```yaml
# Add to spec.template.spec.containers[worker].securityContext
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: true
```

**Apply Fix:**

```bash
# The fix is already in the file, but verify:
grep -A 8 "securityContext:" k8s/manifests/07-worker.yaml
```

### Issue 2: Seed Job - Missing Security Context

**File:** `k8s/manifests/10-seed.yaml`  
**Severity:** Medium (3 issues)

**Fix:**

```yaml
# Add to spec.template.spec.containers[seed].securityContext
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: false  # Seed needs to write temp files
```

**Apply Fix - Update 10-seed.yaml:**

---

## 4. Hardcoded Secrets Check

**Issue:** Potential hardcoded secrets detected

**Action Required:**

```bash
# Find potential secrets
grep -r "password\|secret\|token" --include="*.py" --include="*.js" --include="*.cs" --exclude-dir=node_modules --exclude-dir=.git .

# Review each finding and ensure:
# 1. No actual passwords/secrets in code
# 2. All secrets use environment variables or K8s secrets
# 3. Comments/variable names are not flagged
```

**Good Practices:**

- ✅ Use Kubernetes Secrets for sensitive data
- ✅ Use environment variables
- ✅ Use .env files (not committed to git)
- ❌ Never hardcode passwords/tokens in code

---

## 5. Quick Fix Script

Save this as `fix-security-issues.sh`:

```bash
#!/bin/bash
set -e

echo "🔒 Applying Security Fixes..."
echo ""

# 1. Fix vote debug mode
echo "1. Fixing vote debug mode..."
sed -i 's/debug=True/debug=False/g' vote/app.py
echo "   ✓ Debug mode disabled"

# 2. Upgrade result dependencies
echo "2. Upgrading result dependencies..."
cd result/
npm install express@4.21.2 cookie-parser@1.4.7 socket.io@4.8.0 --save
npm install helmet express-rate-limit --save
npm audit fix
cd ..
echo "   ✓ Dependencies upgraded"

# 3. Fix Kubernetes seed job
echo "3. Fixing Kubernetes seed job security..."
cat > /tmp/seed-security.yaml << 'EOF'
        securityContext:
          runAsNonRoot: true
          runAsUser: 1000
          allowPrivilegeEscalation: false
          capabilities:
            drop:
              - ALL
          readOnlyRootFilesystem: false
EOF

# Insert after line with "name: seed" in containers section
# This is a placeholder - manual edit recommended
echo "   ⚠ Manual edit required for k8s/manifests/10-seed.yaml"

# 4. Rebuild images
echo "4. Rebuilding Docker images..."
docker build -t tactful-votingapp-cloud-infra-vote:latest vote/
docker build -t tactful-votingapp-cloud-infra-result:latest result/
docker build -t tactful-votingapp-cloud-infra-worker:latest worker/
echo "   ✓ Images rebuilt"

echo ""
echo "✅ Security fixes applied!"
echo ""
echo "⚠️  Manual steps required:"
echo "   1. Update result/server.js with Helmet, rate limiting, CSRF"
echo "   2. Update k8s/manifests/10-seed.yaml with security context"
echo "   3. Review and remove any actual hardcoded secrets"
echo "   4. Rescan with: ./snyk-full-scan.sh"
```

---

## 6. Apply Fixes Step-by-Step

### Step 1: Fix Vote Service

```bash
# Disable debug mode
sed -i 's/debug=True/debug=False/g' vote/app.py

# Verify
grep "debug=" vote/app.py

# Rebuild image
docker build -t tactful-votingapp-cloud-infra-vote:latest vote/
```

### Step 2: Fix Result Service Dependencies

```bash
cd result/

# Backup package.json
cp package.json package.json.backup

# Upgrade vulnerable packages
npm install express@4.21.2 --save
npm install cookie-parser@1.4.7 --save
npm install socket.io@4.8.0 --save

# Install security packages
npm install helmet@latest --save
npm install express-rate-limit@latest --save

# Run npm audit
npm audit fix

cd ..

# Rebuild image
docker build -t tactful-votingapp-cloud-infra-result:latest result/
```

### Step 3: Update Result Server.js

```bash
# Edit result/server.js manually to add:
# - helmet middleware
# - rate limiting
# - CSRF protection (optional for this app type)

# See detailed code changes in section 2 above
```

### Step 4: Fix Kubernetes Manifests

```bash
# Edit k8s/manifests/10-seed.yaml
# Add security context as shown in section 3 above

# Verify all manifests have security contexts
grep -A 8 "securityContext:" k8s/manifests/*.yaml
```

### Step 5: Rebuild and Test

```bash
# Rebuild all images
docker build -t tactful-votingapp-cloud-infra-vote:latest vote/
docker build -t tactful-votingapp-cloud-infra-result:latest result/
docker build -t tactful-votingapp-cloud-infra-worker:latest worker/

# Test with Docker Compose
docker compose up -d
docker compose ps

# Verify no errors
docker compose logs

# Stop
docker compose down
```

### Step 6: Rescan with Snyk

```bash
# Run full scan again
./snyk-full-scan.sh

# Check for improvements
cat security-reports/snyk-scan-*.txt | tail -100
```

---

## 7. Verification Checklist

After applying fixes, verify:

```bash
# ✅ Vote service - debug disabled
grep "debug=False" vote/app.py && echo "✓ Debug disabled" || echo "✗ Still enabled"

# ✅ Result dependencies updated
cd result/ && npm list express cookie-parser socket.io && cd ..

# ✅ Images rebuilt
docker images | grep tactful-votingapp-cloud-infra

# ✅ No high/critical vulnerabilities
./snyk-full-scan.sh 2>&1 | grep -i "critical\|high"

# ✅ Kubernetes manifests secure
kubectl apply --dry-run=client -f k8s/manifests/
```

---

## 8. Monitoring & Prevention

### Continuous Monitoring

```bash
# Monitor in Snyk dashboard
snyk monitor --all-projects

# Set up GitHub Actions to scan on every PR
# (Already configured in .github/workflows/security-scanning.yml)
```

### Prevention

1. **Dependabot**: Already configured in `.github/dependabot.yml`
2. **Pre-commit hooks**: Consider adding Snyk scan
3. **Regular scans**: Run `./snyk-full-scan.sh` weekly

---

## Summary

**Total Issues Found:** 14  
**Critical:** 0  
**High:** 3  
**Medium:** 11  
**Low:** 0  

**Priority Order:**

1. 🔴 **HIGH**: Upgrade result service dependencies (express, body-parser, ws)
2. 🟡 **MEDIUM**: Add Helmet, rate limiting to result service
3. 🟡 **MEDIUM**: Disable debug mode in vote service
4. 🟡 **MEDIUM**: Fix Kubernetes seed job security context
5. 🟡 **LOW**: Review potential hardcoded secrets

**Estimated Time to Fix:** 30-45 minutes

---

## Quick Start

```bash
# 1. Run the quick fix (automated parts)
chmod +x fix-security-issues.sh
./fix-security-issues.sh

# 2. Manually update result/server.js (see section 2)
nano result/server.js

# 3. Manually update k8s/manifests/10-seed.yaml (see section 3)
nano k8s/manifests/10-seed.yaml

# 4. Rescan
./snyk-full-scan.sh

# 5. Verify improvements
echo "Check new report in security-reports/"
```

---

**Report Generated:** November 21, 2025  
**Next Scan:** Schedule weekly with `./snyk-full-scan.sh`
