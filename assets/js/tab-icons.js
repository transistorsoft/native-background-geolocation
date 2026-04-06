/* Inject platform icons into top-level nav tabs. */
(function () {
  'use strict';

  var TAB_ICONS = {
    'TypeScript': ['react-native', 'expo', 'capacitor'],
    'Flutter':    ['flutter'],
    'Swift':      ['swift'],
    'Kotlin':     ['kotlin'],
  };

  function assetsBase() {
    var link = document.querySelector('link[rel="stylesheet"][href*="assets/css"]');
    return link ? link.href.replace(/assets\/css\/.*$/, '') : '/';
  }

  function injectTabIcons() {
    var base = assetsBase();
    document.querySelectorAll('[data-md-component="tabs"] .md-tabs__link').forEach(function (link) {
      var label = link.textContent.trim();
      var icons = TAB_ICONS[label];
      if (!icons || !icons.length) return;

      var frag = document.createDocumentFragment();
      icons.forEach(function (icon) {
        var img = document.createElement('img');
        img.src = base + 'assets/images/platforms/' + icon + '.svg';
        img.className = 'bgeo-tab-icon';
        img.alt = icon;
        frag.appendChild(img);
      });
      link.insertBefore(frag, link.firstChild);
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', injectTabIcons);
  } else {
    injectTabIcons();
  }
}());
