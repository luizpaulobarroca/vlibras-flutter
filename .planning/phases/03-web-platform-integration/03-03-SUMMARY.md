---
phase: 03-web-platform-integration
plan: "03"
subsystem: assets+verification
tags: [vlibras-js, web-asset, android, mobile, human-verify]

# Dependency graph
requires:
  - phase: 03-02
    provides: VLibrasView, VLibrasController wired end-to-end

provides:
  - web/vlibras/vlibras.js committed to plugin repository (VLibras.Player SDK)
  - Android mobile platform functional via WebView (VLibrasMobilePlatform)
  - Human-verified end-to-end: avatar renders and translate animates on both Flutter Web and Android

affects:
  - Phase 4 (publication readiness — plugin now functional on Web and Android)

# What was built

Task 1: web/vlibras/vlibras.js confirmed present in plugin repository.

Additionally (outside original plan scope, resolved during this session):
- Fixed Android platform black screen — three root causes identified and corrected:
  1. Missing INTERNET permission in spike/android/app/src/main/AndroidManifest.xml
  2. Wrong targetPath in VLibrasMobilePlatform: was 'https://vlibras.gov.br/app' (no UnityLoader.js there), corrected to 'https://cdn.jsdelivr.net/gh/spbgovbr-vlibras/vlibras-portal@dev/app/target' (direct CDN, bypasses ERR_BLOCKED_BY_ORB redirect)
  3. Outdated server URLs in assets/vlibras.js using 2018 dev servers (-dth): updated translatorUrl and dictionaryUrl to production hostnames
- Added initialize() call in spike/lib/main.dart initState()
- Added WebView console logging and JS error bridge for diagnostics

Task 2: Human verification complete — avatar renders and translate animates on:
- Flutter Web (browser)
- Android (WebView via VLibrasMobilePlatform)

# Key decisions

| Decision | Rationale |
|----------|-----------|
| targetPath = cdn.jsdelivr.net/.../app/target | vlibras.gov.br/app redirects to CDN but /app/UnityLoader.js returns 403 (file at /app/target/); direct CDN URL bypasses ORB cross-origin redirect block |
| assets/vlibras.js server URLs: -dth removed | DTH = dev/test servers from 2018, inaccessible in production; production hostnames are without -dth suffix |
| VLibras.Player API retained (not Widget) | vlibras.js bundle exposes VLibras.Player with translate(), animation events — Widget API lacks programmatic control |

# Outcomes

- Phase 3 goal MET: Flutter Web app displays VLibras avatar and translates text to LIBRAS end-to-end
- Android bonus: VLibrasMobilePlatform working, extending plugin scope beyond original v1 Web-only plan
- Phase 4 (publication readiness) is unblocked
