/* Platform-aware tab navigation.
 *
 * When a top-level platform tab is clicked, redirect to:
 *   1. the equivalent peer page in that platform (from BGEO_PEERS map), or
 *   2. the last page the user visited in that platform (localStorage), or
 *   3. the default tab target (platform home) — no action needed.
 */
(function () {
  'use strict';

  // Maps every URL prefix to the peer-map key used in BGEO_PEERS.
  // Multiple URL prefixes share "ts" because they use the same TypeScript API.
  var _PEER_KEY = {
    'react-native': 'ts',
    'capacitor':    'ts',
    'cordova':      'ts',
    'typescript':   'ts',
    'flutter':      'dart',
    'swift':        'swift',
    'kotlin':       'kotlin'
  };

  // All known platform root segments (used to detect index pages).
  var _ROOTS = Object.keys(_PEER_KEY);

  function urlPrefix(url) {
    var m = (new URL(url)).pathname.match(/^\/([^\/]+)/);
    return m ? m[1] : '';
  }

  function peerKey(url) {
    return _PEER_KEY[urlPrefix(url)] || 'ts';
  }

  function pageSlug(url) {
    var path = (new URL(url)).pathname.replace(/\/$/, '');
    var m = path.match(/\/([^\/]+)$/);
    var s = m ? m[1] : '';
    return _ROOTS.indexOf(s) !== -1 ? '' : s;
  }

  function siteBase(url) {
    var pfx = urlPrefix(url);
    if (!pfx) return url;
    var i = url.indexOf('/' + pfx + '/');
    return i !== -1 ? url.substring(0, i + 1) : url;
  }

  var here    = window.location.href;
  var herePfx = urlPrefix(here);
  var herePK  = peerKey(here);
  var slug    = pageSlug(here);
  var isIdx   = !slug;

  // Persist current page and active platform prefix
  try {
    localStorage.setItem('bgeo-platform', herePfx);
    if (!isIdx) { localStorage.setItem('bgGeo_nav_' + herePfx, here); }
  } catch (_) {}

  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.md-tabs__link').forEach(function (link) {
      link.addEventListener('click', function (e) {
        var targetPfx = urlPrefix(link.href);
        var targetPK  = peerKey(link.href);
        if (targetPfx === herePfx || isIdx) return;

        var base = siteBase(here);

        // 1. Try peer mapping
        if (typeof BGEO_PEERS !== 'undefined' && slug) {
          var peers = BGEO_PEERS[slug] || {};
          var peerSlug = peers[targetPK];
          if (peerSlug) {
            e.preventDefault();
            window.location.href = base + targetPfx + '/' + peerSlug + '/';
            return;
          }
        }

        // 2. Fall back to last visited page in target platform
        try {
          var saved = localStorage.getItem('bgGeo_nav_' + targetPfx);
          if (saved && saved.indexOf('/' + targetPfx + '/') !== -1) {
            e.preventDefault();
            window.location.href = saved;
          }
        } catch (_) {}
      });
    });
  });
}());
