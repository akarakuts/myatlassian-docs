#!/bin/bash
# my* Suite Security Scanner
echo "=== my* Suite Security Scanner ==="
echo "Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

ISSUES=0

# 1. Hardcoded secrets
echo "1. Hardcoded Secrets Check:"
for app in myjira myconf mybitbucket mycrowd mybamboo myportal mystatuspage myopsgenie myservicedesk mycompass mycalendars mycrm myrovo myanalytics mymarketplace myalign mynotifications mychat mytrello mydiscovery myatlas myflow mysearch myjam myrunbook mytimesheets myforms; do
  found=$(grep -rn "password.*=.*['\"].*['\"]" /home/akarakuts/projects/myatlassian/$app/src/ 2>/dev/null | grep -v "test\|example\|default\|ADMIN_PASSWORD\|hash\|verify\|argon\|dummy" | wc -l)
  if [ $found -gt 0 ]; then
    echo "  ⚠️  $app: $found potential hardcoded passwords"
    ISSUES=$((ISSUES+found))
  fi
done
echo "  ✅ Complete"
echo ""

# 2. SQL injection
echo "2. SQL Injection Check:"
for app in myjira myconf mybitbucket mycrowd mybamboo myportal mystatuspage myopsgenie myservicedesk mycompass mycalendars mycrm myrovo myanalytics mymarketplace myalign mynotifications mychat mytrello mydiscovery myatlas myflow mysearch myjam myrunbook mytimesheets myforms; do
  found=$(grep -rn "format!.*SELECT\|format!.*INSERT\|format!.*UPDATE\|format!.*DELETE" /home/akarakuts/projects/myatlassian/$app/src/ 2>/dev/null | grep -v "test\|example" | wc -l)
  if [ $found -gt 0 ]; then
    echo "  ⚠️  $app: $found potential SQL injection"
    ISSUES=$((ISSUES+found))
  fi
done
echo "  ✅ Complete"
echo ""

# 3. Security headers
echo "3. Security Headers Check:"
for app in myjira myconf mybitbucket mycrowd mybamboo myportal mystatuspage myopsgenie myservicedesk mycompass mycalendars mycrm myrovo myanalytics mymarketplace myalign mynotifications mychat mytrello mydiscovery myatlas myflow mysearch myjam myrunbook mytimesheets myforms; do
  has_headers=$(grep -rn "X-Frame-Options\|X-Content-Type-Options\|Content-Security-Policy" /home/akarakuts/projects/myatlassian/$app/src/ 2>/dev/null | wc -l)
  if [ $has_headers -eq 0 ]; then
    echo "  ⚠️  $app: Missing security headers"
    ISSUES=$((ISSUES+1))
  fi
done
echo "  ✅ Complete"
echo ""

echo "=== RESULTS ==="
echo "Issues found: $ISSUES"
if [ $ISSUES -eq 0 ]; then
  echo "✅ No security issues found!"
else
  echo "⚠️  Review and fix the issues above"
fi
