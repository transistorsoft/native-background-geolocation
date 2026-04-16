/**
 * platform-search.js
 *
 * Two responsibilities:
 *
 * 1. SCOPE FILTERING — on any platform or FAQ page, hides MkDocs Material
 *    search results that belong to a different platform or context.
 *
 * 2. CUSTOM INDEX INJECTION — on API platform pages, fetches a pre-built
 *    per-platform search index (generated from docforge/db at site build time),
 *    scores entries against the current query, and injects matching results at
 *    the top of Material's result list before Material's own results.
 *
 * The MutationObserver on .md-search-result__list fires whenever Material
 * adds new result items. We disconnect → apply changes → reconnect to prevent
 * re-entrant callbacks and DOM mutation loops.
 *
 * Scoring (no lunr required for ~400 entries per platform):
 *   100 — exact member name match  (e.g. "odometer"    → Location.odometer)
 *    90 — member name prefix match (e.g. "getOdo"      → BackgroundGeolocation.getOdometer)
 *    70 — member name contains    (e.g. "odometer"     → BackgroundGeolocation.getOdometer)
 *    50 — full title contains     (e.g. "odometer"     → LocationFilter.odometerAccuracyThreshold)
 *    20 — description text match
 */
(function () {

  var PLATFORMS      = ['react-native', 'capacitor', 'flutter', 'swift', 'kotlin', 'cordova', 'typescript'];
  var PLATFORM_LABELS = { faq: 'FAQ' };
  var MAX_CUSTOM     = 10;
  var MIN_QUERY_LEN  = 2;

  // ── Platform detection ────────────────────────────────────────────────────

  function activePlatform() {
    var path = window.location.pathname;
    if (path.indexOf('/help/faq') !== -1) { return 'faq'; }
    var first = path.replace(/^\//, '').split('/')[0];
    return PLATFORMS.indexOf(first) !== -1 ? first : null;
  }

  function resultPlatform(anchor) {
    if (anchor.href && anchor.href.indexOf('/help/faq') !== -1) { return 'faq'; }
    var m = anchor.href && anchor.href.match(
      /\/(react-native|capacitor|flutter|swift|kotlin|cordova|typescript)\//
    );
    return m ? m[1] : null;
  }

  // ── Custom index ──────────────────────────────────────────────────────────

  var customIndex = null;  // null = still loading, [] = loaded (may be empty)

  function loadIndex(platform) {
    if (platform === 'faq') { return; }
    fetch('/assets/search/' + platform + '.json')
      .then(function (r) { return r.ok ? r.json() : []; })
      .then(function (data) { customIndex = Array.isArray(data) ? data : []; })
      .catch(function () { customIndex = []; });
  }

  function scoreEntry(entry, query) {
    var q   = query.toLowerCase();
    var tl  = entry.title.toLowerCase();
    var mem = tl.split('.').pop();             // member part after the last dot
    if (mem === q)               { return 100; }
    if (mem.indexOf(q) === 0)    { return  90; }
    if (mem.indexOf(q) !== -1)   { return  70; }
    if (tl.indexOf(q)  !== -1)   { return  50; }
    if ((entry.text || '').toLowerCase().indexOf(q) !== -1) { return 20; }
    return 0;
  }

  function queryIndex(query) {
    if (!customIndex || !query || query.length < MIN_QUERY_LEN) { return []; }
    var scored = [];
    for (var i = 0; i < customIndex.length; i++) {
      var s = scoreEntry(customIndex[i], query);
      if (s > 0) { scored.push({ entry: customIndex[i], score: s }); }
    }
    scored.sort(function (a, b) {
      return b.score - a.score || a.entry.title.localeCompare(b.entry.title);
    });
    return scored.slice(0, MAX_CUSTOM).map(function (x) { return x.entry; });
  }

  // ── DOM: build a result item matching Material's HTML structure ───────────

  function makeItem(entry) {
    var li      = document.createElement('li');
    li.className = 'md-search-result__item bgeo-custom-result';

    var a       = document.createElement('a');
    a.href      = entry.location;
    a.className = 'md-search-result__link';
    a.tabIndex  = -1;

    var art     = document.createElement('article');
    art.className = 'md-search-result__article md-typeset';
    art.setAttribute('data-md-score', '1');

    var h1      = document.createElement('h1');
    h1.className   = 'md-search-result__title';
    h1.textContent = entry.title;

    var p       = document.createElement('p');
    p.className   = 'md-search-result__teaser';
    p.textContent = (entry.text || '').slice(0, 220);

    art.appendChild(h1);
    art.appendChild(p);
    a.appendChild(art);
    li.appendChild(a);
    return li;
  }

  // ── Scope toggle ──────────────────────────────────────────────────────────

  var filterEnabled = true;

  function updateToggle(platform, hiddenCount) {
    var container = document.querySelector('.md-search-result');
    if (!container) { return; }
    var el = container.querySelector('.bgeo-search-scope-toggle');
    if (!filterEnabled || hiddenCount === 0) {
      if (el) { el.remove(); }
      return;
    }
    if (!el) {
      el = document.createElement('div');
      el.className = 'bgeo-search-scope-toggle';
      el.addEventListener('click', function (e) {
        if (!e.target.classList.contains('bgeo-scope-link')) { return; }
        e.preventDefault();
        filterEnabled = false;
        applySearch(platform);
      });
      container.insertBefore(el, container.firstChild);
    }
    var label = PLATFORM_LABELS[platform] || platform;
    el.innerHTML =
      'Showing <strong>' + label + '</strong> results only. ' +
      '<a href="#" class="bgeo-scope-link">Show all</a>';
  }

  // ── Core: filter Material results + inject custom results ─────────────────

  function getQuery() {
    var inp = document.querySelector('.md-search__input');
    return inp ? inp.value.trim() : '';
  }

  function applySearch(platform) {
    var list = document.querySelector('.md-search-result__list');
    if (!list) { return; }

    var query = getQuery();

    // 1. Remove any previously injected custom results
    var prev = list.querySelectorAll('.bgeo-custom-result');
    for (var i = 0; i < prev.length; i++) {
      prev[i].parentNode.removeChild(prev[i]);
    }

    // 2. Filter Material's native results by platform scope
    var matItems = list.querySelectorAll('.md-search-result__item');
    var existingLocs = new Set();
    var hidden = 0;
    for (var j = 0; j < matItems.length; j++) {
      var item = matItems[j];
      var a    = item.querySelector('a');
      if (!a) { continue; }
      var rp   = resultPlatform(a);
      var hide = filterEnabled && rp !== null && rp !== platform;
      item.style.display = hide ? 'none' : '';
      if (hide) {
        hidden++;
      } else {
        // Track visible Material result locations for deduplication
        var href = (a.getAttribute('href') || '')
          .replace(/^https?:\/\/[^/]+/, '')
          .split('?')[0];
        existingLocs.add(href);
      }
    }

    // 3. Inject custom results at top of list
    if (customIndex && platform !== 'faq' && query.length >= MIN_QUERY_LEN) {
      var results = queryIndex(query);
      var frag    = document.createDocumentFragment();
      for (var k = 0; k < results.length; k++) {
        var loc = results[k].location;
        if (!existingLocs.has(loc)) {
          frag.appendChild(makeItem(results[k]));
        }
      }
      if (frag.childNodes.length > 0) {
        list.insertBefore(frag, list.firstChild);
      }
    }

    // 4. Update the "Showing X only / Show all" toggle
    updateToggle(platform, hidden);
  }

  // ── Init ──────────────────────────────────────────────────────────────────

  function init() {
    var platform = activePlatform();
    if (!platform) { return; }

    loadIndex(platform);

    // Reset scope filter each time the search overlay is opened
    document.addEventListener('focusin', function (e) {
      if (e.target && e.target.classList.contains('md-search__input')) {
        filterEnabled = true;
      }
    });

    var list = document.querySelector('.md-search-result__list');
    if (!list) { return; }

    // Disconnect before mutating DOM, reconnect after — prevents re-entrant loops.
    var observer = new MutationObserver(function () {
      observer.disconnect();
      applySearch(platform);
      observer.observe(list, { childList: true });
    });
    observer.observe(list, { childList: true });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }

})();
