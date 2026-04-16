/**
 * search-scope.js
 *
 * Scopes MkDocs Material search results to the active top-level platform
 * (typescript | flutter | swift | kotlin) when one is active.
 *
 * .md-search-result__list exists in the DOM from page load. A MutationObserver
 * on that list fires whenever Material adds new result items (childList change).
 * applyFilter then hides items whose path doesn't match the current platform.
 *
 * A "Show all results" toggle lets the user opt out per session.
 */
(function () {
  var PLATFORMS = ['react-native', 'capacitor', 'flutter', 'swift', 'kotlin', 'cordova', 'typescript'];
  var PLATFORM_LABELS = { faq: 'FAQ' };

  function activePlatform() {
    var path = window.location.pathname;
    if (path.indexOf('/help/faq') !== -1) { return 'faq'; }
    var first = path.replace(/^\//, '').split('/')[0];
    return PLATFORMS.indexOf(first) !== -1 ? first : null;
  }

  function resultPlatform(anchor) {
    if (anchor.href.indexOf('/help/faq') !== -1) { return 'faq'; }
    var m = anchor.href.match(/\/(react-native|capacitor|flutter|swift|kotlin|cordova|typescript)\//);
    return m ? m[1] : null;
  }

  var filterEnabled = true;

  function applyFilter(platform) {
    var results = document.querySelectorAll('.md-search-result__item');
    if (!results.length) { return; }
    var hidden = 0;
    results.forEach(function (item) {
      var a = item.querySelector('a');
      if (!a) { return; }
      var rp = resultPlatform(a);
      var hide = filterEnabled && rp !== null && rp !== platform;
      item.style.display = hide ? 'none' : '';
      if (hide) { hidden++; }
    });
    updateToggle(platform, hidden);
  }

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
        applyFilter(platform);
      });
      container.insertBefore(el, container.firstChild);
    }
    var label = PLATFORM_LABELS[platform] || platform;
    el.innerHTML =
      'Showing <strong>' + label + '</strong> results only. ' +
      '<a href="#" class="bgeo-scope-link">Show all</a>';
  }

  function init() {
    var platform = activePlatform();
    if (!platform) { return; }

    // Reset filter each time the search input is opened
    document.addEventListener('focusin', function (e) {
      if (e.target && e.target.classList.contains('md-search__input')) {
        filterEnabled = true;
      }
    });

    var list = document.querySelector('.md-search-result__list');
    if (!list) { return; }

    new MutationObserver(function () {
      applyFilter(platform);
    }).observe(list, { childList: true });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
