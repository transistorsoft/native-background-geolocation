/**
 * tab-toc.js
 *
 * When the page has a top-level tabbed set whose labels match TOC top-level
 * entries (e.g. "React Native / Expo / Capacitor" on the TypeScript setup
 * page), shows only the active framework's TOC tree and hides the rest.
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

    // ?tab=<slug> URL param — select the matching tab, overriding localStorage restore
    var tabParam = new URLSearchParams(window.location.search).get("tab");
    if (tabParam) {
      // Run after Material's content.tabs.link localStorage restore (200 ms).
      // Click the label (not just input.checked) to trigger Material's full
      // tab-switching logic, including localStorage update and panel visibility.
      setTimeout(function () {
        var labels = Array.from(
          tabbedSet.querySelectorAll(":scope > .tabbed-labels > label")
        );
        var target = labels.find(function (label) {
          return PLATFORM_ICONS[getLabelText(label)] === tabParam;
        });
        if (target) {
          target.click();
        }
        syncToc();
      }, 300);
    }

    // DOMContentLoaded fires after Material's deferred JS (including content.tabs.link
    // localStorage restore), so the radio state is already correct — one sync is enough.
    setTimeout(syncToc, 0);
  }

  // DOMContentLoaded fires after all deferred scripts (including Material's)
  document.addEventListener("DOMContentLoaded", init);
  // Fallback if we're somehow running after DOMContentLoaded already fired
  if (document.readyState !== "loading") {
    setTimeout(init, 0);
  }
})();
