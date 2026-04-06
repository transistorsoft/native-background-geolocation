/* Method sub-group TOC expand / collapse + Lucide icon injection.
 *
 * Reads BGEO_TOC_ICONS (emitted by generate_mkdocs.py from docs.yml)
 * to inject Lucide icons into TOC entries — both top-level group headers
 * (Events, Methods, Properties, Constants) and method sub-group headers
 * (Geofencing, Data Management, …).
 *
 * Material for MkDocs duplicates the secondary nav (desktop sidebar + mobile
 * drawer), so we process every .md-nav--secondary element on the page.
 *
 * Sub-group entries are also wired for collapse / expand with an arrow
 * indicator.
 */
(function () {
  'use strict';

  /* Convert kebab-case icon name to PascalCase for lucide.icons lookup. */
  function toPascalCase(name) {
    return name.replace(/(^|-)([a-z0-9])/g, function (_, __, c) { return c.toUpperCase(); });
  }

  /* Build a Lucide SVG element for a given icon name (kebab-case). */
  function buildIcon(iconName) {
    if (!iconName || typeof lucide === 'undefined') { return null; }
    var key = toPascalCase(iconName);
    var iconDef = lucide.icons && lucide.icons[key];
    if (!iconDef) { return null; }
    return lucide.createElement(iconDef);
  }

  /* Inject a Lucide SVG icon before the label text inside a TOC <a> element. */
  function injectIcon(link, iconName) {
    if (!iconName || link.querySelector('.bgeo-toc-icon')) { return; }
    var svg = buildIcon(iconName);
    if (!svg) { return; }
    svg.classList.add('bgeo-toc-icon');
    svg.setAttribute('aria-hidden', 'true');
    link.insertBefore(svg, link.firstChild);
  }

  /* Inject a Lucide SVG icon into a page heading (h3.bgeo-method-group). */
  function injectHeadingIcon(heading, iconName) {
    if (!iconName || heading.querySelector('.bgeo-heading-icon')) { return; }
    var svg = buildIcon(iconName);
    if (!svg) { return; }
    svg.classList.add('bgeo-heading-icon');
    svg.setAttribute('aria-hidden', 'true');
    heading.insertBefore(svg, heading.firstChild);
  }

  /* Extract visible label text from a TOC <a> (strip whitespace). */
  function linkLabel(link) {
    var span = link.querySelector('.md-ellipsis');
    return span ? span.textContent.trim() : link.textContent.trim();
  }

  /* Process one .md-nav--secondary element. */
  function initToc(toc) {
    var icons = (typeof BGEO_TOC_ICONS !== 'undefined') ? BGEO_TOC_ICONS : {};

    // ── Top-level group headers (Events, Methods, Properties, Constants) ───
    // Only inject on reference pages — pages that have bgeo-method-group headings.
    // This prevents false matches on FAQ/help pages whose section names (e.g. "Geofencing")
    // coincide with method sub-group labels in BGEO_TOC_ICONS.
    if (document.querySelector('h3.bgeo-method-group')) {
      toc.querySelectorAll(':scope > .md-nav__list > .md-nav__item > .md-nav__link')
        .forEach(function (link) {
          injectIcon(link, icons[linkLabel(link)]);
        });
    }

    // ── Method sub-group headers (Geofencing, Data Management, …) ──────────
    document.querySelectorAll('h3.bgeo-method-group').forEach(function (h) {
      var id = h.getAttribute('id');
      if (!id) { return; }

      var link = toc.querySelector('a[href="#' + id + '"]');
      if (!link) { return; }

      var label = linkLabel(link);
      injectIcon(link, icons[label]);
      injectHeadingIcon(h, icons[label]);

      var li = link.parentElement;
      var nested = li.querySelector('.md-nav');
      if (!nested) { return; }

      // Guard: don't wire up the same link twice (both nav copies share h3 ids)
      if (link.querySelector('.bgeo-group-indicator')) { return; }

      var indicator = document.createElement('span');
      indicator.className = 'bgeo-group-indicator';
      indicator.setAttribute('aria-hidden', 'true');
      indicator.textContent = '\u25b8'; // ▸
      link.appendChild(indicator);

      li.classList.add('bgeo-group--collapsed');

      link.addEventListener('click', function (e) {
        e.preventDefault();
        var collapsed = li.classList.toggle('bgeo-group--collapsed');
        indicator.textContent = collapsed ? '\u25b8' : '\u25be'; // ▸ or ▾
        if (!collapsed) {
          h.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      });
    });
  }

  function initMethodGroups() {
    document.querySelectorAll('.md-nav--secondary').forEach(initToc);
  }

  // ── Setup page heading icons ─────────────────────────────────────────────

  /* Map heading text → Lucide icon name, or "platform:<slug>" for SVG icons. */
  var SETUP_HEADING_ICONS = {
    // Common — all platforms
    'Installation':                                               'package',
    'Configure your license':                                     'key-round',
    'Example':                                                    'code-2',
    // Platform section headers
    'iOS Setup':                                                  'platform:ios',
    'iOS \u2014 Info.plist':                                      'platform:ios',
    'Android Setup':                                              'platform:android',
    'Android \u2014 AndroidManifest.xml':                        'platform:android',
    // TypeScript tab framework headers
    'React Native':                                               'platform:react-native',
    'Expo':                                                       'platform:expo',
    'Capacitor':                                                  'platform:capacitor',
    // iOS sub-sections
    'CocoaPods':                                                  'layers',
    'Podfile':                                                    'layers',
    'Background Modes':                                           'radio',
    'Background Task Identifiers':                                'tag',
    'Location Usage Descriptions':                                'map-pin',
    'Info.plist':                                                 'file-code',
    'AppDelegate':                                                'file-cog',
    // Android sub-sections
    'Gradle ext vars':                                            'sliders-horizontal',
    'android/app/build.gradle':                                   'file-code',
    'android/app/build.gradle / android/app/build.gradle.kts':   'file-code',
    'AndroidManifest.xml':                                        'file-code',
    '1. Add the Maven dependencies':                              'package-plus',
    '2. Permissions, services, and receivers':                    'shield',
  };

  /* Inject a platform SVG icon (span with data-platform, styled via CSS). */
  function injectPlatformHeadingIcon(heading, slug) {
    if (heading.querySelector('.bgeo-platform-heading-icon')) { return; }
    var span = document.createElement('span');
    span.className = 'bgeo-platform-heading-icon';
    span.setAttribute('data-platform', slug);
    span.setAttribute('aria-hidden', 'true');
    heading.insertBefore(span, heading.firstChild);
  }

  function initSetupHeadings() {
    var article = document.querySelector('.md-content article');
    if (!article) { return; }

    article.querySelectorAll('h2, h3, h4').forEach(function (h) {
      if (h.classList.contains('bgeo-method-group')) { return; }
      if (h.querySelector('.bgeo-heading-icon, .bgeo-platform-heading-icon')) { return; }
      // Strip the MkDocs permalink anchor (¶) before matching
      var clone = h.cloneNode(true);
      var hl = clone.querySelector('.headerlink');
      if (hl) { hl.remove(); }
      var text = clone.textContent.trim();
      var icon = SETUP_HEADING_ICONS[text];
      if (!icon) { return; }
      if (icon.indexOf('platform:') === 0) {
        injectPlatformHeadingIcon(h, icon.slice(9));
      } else {
        injectHeadingIcon(h, icon);
      }
    });
  }

  // Primary nav icons (Home / Setup / Examples) are now handled by pure CSS
  // ::before pseudo-elements in site.css — no JS injection needed.

  window.addEventListener('load', function () {
    initMethodGroups();
    initSetupHeadings();
  });
}());
