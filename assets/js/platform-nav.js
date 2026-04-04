/* Platform-aware tab navigation.
 *
 * When a top-level platform tab is clicked, redirect to:
 *   1. the equivalent peer page in that platform (from BGEO_PEERS map), or
 *   2. the last page the user visited in that platform (localStorage), or
 *   3. the default tab target (platform home) — no action needed.
 */
(function () {
  'use strict';

  function detectPlatform(url) {
    if (/\/swift\//.test(url))        return 'swift';
    if (/\/kotlin\//.test(url))       return 'kotlin';
    if (/\/flutter\//.test(url))      return 'dart';
    if (/\/typescript\//.test(url))   return 'ts';
    return 'ts';
  }

  // Platform-specific URL prefix (used when building redirect targets)
  var _PREFIX = { ts: 'typescript/', dart: 'flutter/', swift: 'swift/', kotlin: 'kotlin/' };

  function pageSlug(url) {
    // http://host/swift/GeolocationConfig/     → "GeolocationConfig"
    // http://host/typescript/BackgroundGeolocation/ → "BackgroundGeolocation"
    // Operate on pathname only so the host/port never leaks into the slug.
    var path = (new URL(url)).pathname.replace(/\/$/, '');
    var m = path.match(/\/([^\/]+)$/);
    var s = m ? m[1] : '';
    // Ignore platform root segments
    return (s === 'typescript' || s === 'flutter' || s === 'swift' || s === 'kotlin') ? '' : s;
  }

  var here  = window.location.href;
  var plat  = detectPlatform(here);
  var slug  = pageSlug(here);
  var isIdx = !slug;

  // Persist current page and active platform
  try {
    localStorage.setItem('bgeo-platform', plat);
    if (!isIdx) { localStorage.setItem('bgGeo_nav_' + plat, here); }
  } catch (_) {}

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.md-tabs__link').forEach(function (link) {
      link.addEventListener('click', function (e) {
        var targetPlat = detectPlatform(link.href);
        if (targetPlat === plat || isIdx) return;

        // Derive site root (strip everything from platform prefix onward)
        var base = here
          .replace(/\/typescript\/.*$/, '/')
          .replace(/\/flutter\/.*$/, '/')
          .replace(/\/swift\/.*$/, '/')
          .replace(/\/kotlin\/.*$/, '/');

        // 1. Try peer mapping
        if (typeof BGEO_PEERS !== 'undefined' && slug) {
          var peers = BGEO_PEERS[slug] || {};
          var peerSlug = peers[targetPlat];
          if (peerSlug) {
            e.preventDefault();
            window.location.href = base + _PREFIX[targetPlat] + peerSlug + '/';
            return;
          }
        }

        // 2. Fall back to last visited page in target platform — validate path
        try {
          var saved = localStorage.getItem('bgGeo_nav_' + targetPlat);
          if (saved && saved.indexOf('/' + _PREFIX[targetPlat]) !== -1) {
            e.preventDefault(); window.location.href = saved;
          }
        } catch (_) {}
      });
    });
  });
}());
