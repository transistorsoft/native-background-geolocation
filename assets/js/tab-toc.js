/**
 * tab-toc.js
 *
 * 1. Annotates tab labels with data-platform for CSS icon injection.
 * 2. When the page has a top-level tabbed set whose labels match TOC top-level
 *    entries (e.g. "React Native / Expo / Capacitor" on the TypeScript setup
 *    page), shows only the active framework's TOC tree and hides the rest.
 *
 * Safe on all other pages — if no labels match TOC entries, nothing changes.
 */
(function () {
  "use strict";

  // Map tab label text → platform icon slug (must match assets/images/platforms/<slug>.svg)
  var PLATFORM_ICONS = {
    "React Native":       "react-native",
    "React Native / Expo": "react-native",
    "Expo":               "expo",
    "Capacitor":    "capacitor",
    "Flutter":      "flutter",
    "Swift":        "swift",
    "Kotlin":       "kotlin",
    "Cordova":      "cordova",
  };

  function annotatePlatformTabs() {
    document.querySelectorAll(".tabbed-labels label").forEach(function (label) {
      var text = label.textContent.trim();
      var slug = PLATFORM_ICONS[text];
      if (slug) label.setAttribute("data-platform", slug);
    });
  }

  function getLabelText(el) {
    // Text may be wrapped in <span class="md-ellipsis"> with surrounding whitespace
    var span = el.querySelector(".md-ellipsis");
    return (span || el).textContent.trim();
  }

  function syncToc() {
    // Only target the first (outermost) tabbed-set on the page
    var tabbedSet = document.querySelector(".md-content .tabbed-set");
    if (!tabbedSet) return;

    var labelEls = Array.from(
      tabbedSet.querySelectorAll(":scope > .tabbed-labels > label")
    );
    if (!labelEls.length) return;

    var labelTexts = labelEls.map(getLabelText);

    // Determine which tab is active
    var active = "";
    labelEls.forEach(function (label) {
      var input = document.getElementById(label.getAttribute("for"));
      if (input && input.checked) active = getLabelText(label);
    });
    if (!active) return;

    // There are two TOC instances (desktop sidebar + mobile) — update both
    document.querySelectorAll("[data-md-component='toc']").forEach(function (tocList) {
      Array.from(tocList.children).forEach(function (li) {
        var link = li.querySelector(":scope > a.md-nav__link");
        if (!link) return;
        var text = getLabelText(link);
        if (labelTexts.indexOf(text) >= 0) {
          li.style.display = text === active ? "" : "none";
        }
      });
    });
  }

  var didInit = false;
  function init() {
    if (didInit) return;
    didInit = true;

    var tabbedSet = document.querySelector(".md-content .tabbed-set");
    if (!tabbedSet) return;

    // radio change — fired when user clicks a tab label directly
    tabbedSet.querySelectorAll("input[type='radio']").forEach(function (input) {
      input.addEventListener("change", syncToc);
    });

    // label click — belt-and-suspenders for content.tabs.link linked tabs
    // (Material may set radio.checked without firing 'change')
    tabbedSet
      .querySelectorAll(":scope > .tabbed-labels > label")
      .forEach(function (label) {
        label.addEventListener("click", function () {
          setTimeout(syncToc, 0);
        });
      });

    // If Material replaces either TOC list element, re-sync
    document.querySelectorAll("[data-md-component='toc']").forEach(function (tl) {
      if (tl.parentElement) {
        new MutationObserver(syncToc).observe(tl.parentElement, { childList: true });
      }
    });

    annotatePlatformTabs();

    // Initial sync — two passes:
    //   pass 1 (0 ms): catches the default checked radio immediately
    //   pass 2 (200 ms): catches Material's content.tabs.link localStorage restore
    setTimeout(syncToc, 0);
    setTimeout(syncToc, 200);
  }

  // DOMContentLoaded fires after all deferred scripts (including Material's)
  document.addEventListener("DOMContentLoaded", init);
  // Fallback if we're somehow running after DOMContentLoaded already fired
  if (document.readyState !== "loading") {
    setTimeout(init, 0);
  }
})();
