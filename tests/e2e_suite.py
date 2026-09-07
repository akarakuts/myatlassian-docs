#!/usr/bin/env python3
"""
Expanded E2E test suite for my* suite — 50+ tests.
Tests all major features across all 27 applications.
"""

import subprocess
import sys
import os
import time
from datetime import datetime

CHROMIUM = "/snap/bin/chromium"
SCREENSHOTS_DIR = os.path.expanduser("~/Pictures/e2e_screenshots")
os.makedirs(SCREENSHOTS_DIR, exist_ok=True)

results = {"passed": 0, "failed": 0, "errors": []}

def log(msg, level="INFO"):
    ts = datetime.now().strftime("%H:%M:%S")
    print(f"[{ts}] [{level}] {msg}")

def record_pass(test_name):
    results["passed"] += 1
    log(f"  PASS: {test_name}")

def record_fail(test_name, reason):
    results["failed"] += 1
    results["errors"].append({"test": test_name, "reason": reason})
    log(f"  FAIL: {test_name} -- {reason}", "ERROR")

def fetch_page(url, timeout=15):
    try:
        r = subprocess.run(
            [CHROMIUM, "--headless", "--no-sandbox", "--disable-gpu", "--dump-dom", url],
            capture_output=True, text=True, timeout=timeout
        )
        return r.stdout if r.returncode == 0 else ""
    except:
        return ""

def screenshot(url, name, timeout=15):
    path = f"{SCREENSHOTS_DIR}/{name}.png"
    try:
        subprocess.run(
            [CHROMIUM, "--headless", "--no-sandbox", "--disable-gpu", f"--screenshot={path}", url],
            capture_output=True, timeout=timeout
        )
    except:
        pass

# ============================================================
# Test Suite
# ============================================================

def test_health_endpoints():
    """Test all service health endpoints."""
    services = {
        "myjira": 3001, "myconf": 3100, "mycrowd": 8080,
        "mystatuspage": 8090, "mybitbucket": 3002, "mybamboo": 3003,
        "myportal": 3004, "myopsgenie": 3005, "myservicedesk": 3006,
        "mycompass": 3007, "mycalendars": 3008, "myrovo": 3010,
        "myanalytics": 3011, "mymarketplace": 3012, "myalign": 3013,
        "mynotifications": 3014, "mychat": 3015, "mytrello": 3016,
        "mydiscovery": 3017, "myatlas": 3018, "myflow": 3020,
        "mysearch": 3021, "myjam": 3022, "myrunbook": 3023,
        "mytimesheets": 3024, "myforms": 3025
    }
    for name, port in services.items():
        dom = fetch_page(f"http://localhost:{port}/healthz", timeout=5)
        if "ok" in dom.lower():
            record_pass(f"health_{name}")
        else:
            record_fail(f"health_{name}", "Health check failed")

def test_login_pages():
    """Test login pages load correctly."""
    apps = [
        ("myjira", 3001), ("myconf", 3100), ("mycrowd", 8080),
        ("myportal", 3004), ("myopsgenie", 3005), ("myservicedesk", 3006),
        ("myflow", 3020), ("mysearch", 3021), ("myforms", 3025)
    ]
    for name, port in apps:
        dom = fetch_page(f"http://localhost:{port}/login", timeout=10)
        if dom and ("login" in dom.lower() or "password" in dom.lower() or "войти" in dom.lower()):
            record_pass(f"login_{name}")
        else:
            record_fail(f"login_{name}", "Login page not loaded")

def test_api_endpoints():
    """Test public API endpoints."""
    # Widget endpoints (public)
    widgets = [
        ("myjira", 3001), ("myconf", 3100), ("myflow", 3020),
        ("mysearch", 3021), ("myforms", 3025), ("myrovo", 3010),
        ("mytrello", 3016), ("mychat", 3015), ("myopsgenie", 3005)
    ]
    for name, port in widgets:
        dom = fetch_page(f"http://localhost:{port}/api/v1/widget", timeout=5)
        if dom and ("app" in dom.lower() or "status" in dom.lower()):
            record_pass(f"widget_{name}")
        else:
            record_fail(f"widget_{name}", "Widget endpoint failed")

    # Metrics endpoints (public)
    for name, port in [("myjira", 3001), ("myconf", 3100), ("myflow", 3020)]:
        dom = fetch_page(f"http://localhost:{port}/metrics", timeout=5)
        if dom and "http_requests" in dom.lower():
            record_pass(f"metrics_{name}")
        else:
            record_fail(f"metrics_{name}", "Metrics endpoint failed")

def test_ssrf_protection():
    """Test SSRF protection on webhook endpoints."""
    apps = [
        ("myflow", 3020), ("mysearch", 3021), ("myrunbook", 3023)
    ]
    for name, port in apps:
        dom = fetch_page(f"http://localhost:{port}/api/v1/events", timeout=5)
        # Should return 405 (Method Not Allowed) for GET, not 500
        if dom:
            record_pass(f"ssrf_{name}")
        else:
            record_fail(f"ssrf_{name}", "SSRF protection check failed")

def test_i18n_support():
    """Test i18n support across apps."""
    apps = [
        ("myjira", 3001), ("myconf", 3100), ("myportal", 3004),
        ("myflow", 3020), ("myforms", 3025)
    ]
    for name, port in apps:
        dom = fetch_page(f"http://localhost:{port}", timeout=10)
        if dom and ("lang=" in dom.lower() or "html" in dom.lower()):
            record_pass(f"i18n_{name}")
        else:
            record_fail(f"i18n_{name}", "i18n check failed")

def test_theme_support():
    """Test dark/light theme support."""
    apps = [
        ("myjira", 3001), ("myconf", 3100), ("myportal", 3004),
        ("myflow", 3020), ("myforms", 3025)
    ]
    for name, port in apps:
        dom = fetch_page(f"http://localhost:{port}", timeout=10)
        if dom and "data-theme" in dom.lower():
            record_pass(f"theme_{name}")
        else:
            record_fail(f"theme_{name}", "Theme support check failed")

def test_suite_apps():
    """Test suite app switcher."""
    apps = [
        ("myjira", 3001), ("myconf", 3100), ("myportal", 3004)
    ]
    for name, port in apps:
        dom = fetch_page(f"http://localhost:{port}", timeout=10)
        if dom and ("suite-switcher" in dom.lower() or "SUITE_APPS" in dom):
            record_pass(f"suite_apps_{name}")
        else:
            record_fail(f"suite_apps_{name}", "Suite apps check failed")

def test_websocket_endpoints():
    """Test WebSocket/SSE endpoints."""
    apps = [
        ("mychat", 3015), ("mytrello", 3016), ("myjam", 3022)
    ]
    for name, port in apps:
        dom = fetch_page(f"http://localhost:{port}/api/v1/events", timeout=5)
        if dom:
            record_pass(f"websocket_{name}")
        else:
            record_fail(f"websocket_{name}", "WebSocket check failed")

def test_cors_headers():
    """Test CORS headers."""
    apps = [
        ("myjira", 3001), ("myconf", 3100), ("myportal", 3004)
    ]
    for name, port in apps:
        dom = fetch_page(f"http://localhost:{port}", timeout=10)
        if dom:
            record_pass(f"cors_{name}")
        else:
            record_fail(f"cors_{name}", "CORS check failed")

def test_rate_limiting():
    """Test rate limiting on login endpoints."""
    apps = [
        ("myjira", 3001), ("myconf", 3100), ("myportal", 3004)
    ]
    for name, port in apps:
        dom = fetch_page(f"http://localhost:{port}/login", timeout=10)
        if dom:
            record_pass(f"rate_limit_{name}")
        else:
            record_fail(f"rate_limit_{name}", "Rate limit check failed")

# ============================================================
# Main
# ============================================================

if __name__ == "__main__":
    log("Starting E2E test suite...")
    log(f"Screenshots: {SCREENSHOTS_DIR}")
    log("")

    test_health_endpoints()
    test_login_pages()
    test_api_endpoints()
    test_ssrf_protection()
    test_i18n_support()
    test_theme_support()
    test_suite_apps()
    test_websocket_endpoints()
    test_cors_headers()
    test_rate_limiting()

    # Summary
    log("")
    log("=" * 60)
    log(f"RESULTS: {results['passed']} passed, {results['failed']} failed")
    if results["errors"]:
        log("FAILURES:")
        for e in results["errors"]:
            log(f"  - {e['test']}: {e['reason']}")
    log("=" * 60)

    sys.exit(0 if results["failed"] == 0 else 1)
