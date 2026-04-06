/**
 * faq-search.js
 *
 * Inline search / filter for the FAQ page only.
 * Scoped strictly to /help/faq/ — does nothing on any other page.
 *
 * Groups the rendered article into Q&A entries (bounded by <hr> elements),
 * injects a search <input> beneath the page title, and shows/hides entries
 * as the user types. Section <h2> headings are hidden when all their entries
 * are filtered out.
 */
(function () {
  'use strict';

  function onFaqPage() {
    return window.location.pathname.indexOf('/help/faq') !== -1;
  }

  function initFaqSearch() {
    if (!onFaqPage()) { return; }

    var article = document.querySelector('.md-content article');
    if (!article) { return; }

    // ── Build entry list ────────────────────────────────────────────────────
    // Walk child elements; group everything between <hr> tags into entries.
    // <h2> elements mark section boundaries and are tracked separately.

    var entries     = [];   // [{section, question, bodyText, elements[]}]
    var sectionEls  = {};   // section heading text → <h2> element
    var currentSection = '';
    var currentEntry   = null;

    function flushEntry() {
      if (currentEntry && currentEntry.elements.length) {
        entries.push(currentEntry);
      }
      currentEntry = null;
    }

    Array.from(article.children).forEach(function (el) {
      var tag = el.tagName.toLowerCase();

      if (tag === 'h1') { return; }           // page title — skip

      if (tag === 'h2') {
        flushEntry();
        currentSection = el.textContent.trim();
        sectionEls[currentSection] = el;
        return;
      }

      if (tag === 'hr') {
        flushEntry();
        return;
      }

      if (!currentEntry) {
        currentEntry = {
          section:  currentSection,
          question: '',
          bodyText: '',
          elements: [],
        };
      }

      currentEntry.elements.push(el);

      // First <p><strong>…</strong></p> is the question heading
      if (!currentEntry.question && tag === 'p') {
        var strong = el.querySelector('strong');
        if (strong) {
          currentEntry.question = el.textContent.trim().toLowerCase();
          return;
        }
      }
      currentEntry.bodyText += ' ' + el.textContent.toLowerCase();
    });

    flushEntry();

    if (!entries.length) { return; }

    // ── Inject search input ─────────────────────────────────────────────────

    var wrapper = document.createElement('div');
    wrapper.className = 'bgeo-faq-search';

    var input = document.createElement('input');
    input.type        = 'search';
    input.placeholder = 'Search FAQ…';
    input.className   = 'bgeo-faq-search__input';
    input.setAttribute('aria-label', 'Search FAQ');
    input.setAttribute('autocomplete', 'off');
    input.setAttribute('spellcheck', 'false');
    wrapper.appendChild(input);

    // Insert immediately after the <h1>
    var h1 = article.querySelector('h1');
    var anchor = h1 ? h1.nextSibling : article.firstChild;
    article.insertBefore(wrapper, anchor);

    // ── Filter logic ────────────────────────────────────────────────────────

    function filter(raw) {
      var q = raw.trim().toLowerCase();
      var sectionHasMatch = {};

      entries.forEach(function (entry) {
        var match = !q ||
          entry.question.indexOf(q) !== -1 ||
          entry.bodyText.indexOf(q) !== -1;

        var display = match ? '' : 'none';
        entry.elements.forEach(function (el) {
          el.style.display = display;
        });

        if (match) { sectionHasMatch[entry.section] = true; }
      });

      // Section headings: visible only when they have ≥1 matching entry
      Object.keys(sectionEls).forEach(function (name) {
        sectionEls[name].style.display = sectionHasMatch[name] ? '' : 'none';
      });

      // HR dividers: hide while filtering (clean look), restore when cleared
      article.querySelectorAll('hr').forEach(function (hr) {
        hr.style.display = q ? 'none' : '';
      });
    }

    var _searchTimer = null;
    input.addEventListener('input', function () {
      filter(input.value);
      clearTimeout(_searchTimer);
      var term = input.value.trim();
      if (term.length < 3) { return; }
      _searchTimer = setTimeout(function () {
        if (typeof gtag === 'function') {
          gtag('event', 'search', { search_term: term });
        }
      }, 800);
    });
  }

  window.addEventListener('load', initFaqSearch);
}());
