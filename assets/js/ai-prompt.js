/* Collapsible "AI prompt" code blocks.
 *
 * Progressive enhancement for any heading tagged with `{: .ai-prompt }` in
 * markdown (via attr_list).  The code block that follows the heading is
 * collapsed by default and wrapped in a toolbar offering:
 *
 *   [✨ Copy AI Prompt]   — always visible, copies the whole block
 *   [Show prompt]         — toggles the block open / closed
 *
 * The prompt bodies are long (hundreds of lines), so hiding them by default
 * keeps the page navigable while the copy action — the thing most readers
 * actually want — stays one click away without expanding anything.
 *
 * Icons are built from the bundled Lucide (same approach as method-groups.js),
 * so this must load AFTER assets/js/lucide.min.js.
 */
(function () {
  'use strict';

  var COPY_LABEL = 'Copy AI Prompt';
  var COPIED_LABEL = 'Copied!';

  /* Convert kebab-case icon name to PascalCase for lucide.icons lookup. */
  function toPascalCase(name) {
    return name.replace(/(^|-)([a-z0-9])/g, function (_, __, c) { return c.toUpperCase(); });
  }

  /* Build a Lucide SVG element for a given icon name (kebab-case). */
  function buildIcon(iconName) {
    if (!iconName || typeof lucide === 'undefined') { return null; }
    var iconDef = lucide.icons && lucide.icons[toPascalCase(iconName)];
    if (!iconDef) { return null; }
    var svg = lucide.createElement(iconDef);
    svg.classList.add('bgeo-ai-icon');
    svg.setAttribute('aria-hidden', 'true');
    return svg;
  }

  function makeButton(cls, iconName, label) {
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = cls;
    var icon = buildIcon(iconName);
    if (icon) { btn.appendChild(icon); }
    var span = document.createElement('span');
    span.className = 'bgeo-ai-label';
    span.textContent = label;
    btn.appendChild(span);
    return btn;
  }

  /* Copy `text`, preferring the async clipboard API and falling back to the
   * legacy selection method when it is unavailable OR rejects — the async API
   * needs a secure context and transient user activation, neither of which is
   * guaranteed (non-secure-origin previews, denied permission). */
  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text).catch(function () {
        return legacyCopy(text);
      });
    }
    return legacyCopy(text);
  }

  function legacyCopy(text) {
    return new Promise(function (resolve, reject) {
      var ta = document.createElement('textarea');
      ta.value = text;
      ta.setAttribute('readonly', '');
      ta.style.position = 'fixed';
      ta.style.opacity = '0';
      document.body.appendChild(ta);
      ta.select();
      try {
        document.execCommand('copy') ? resolve() : reject(new Error('copy failed'));
      } catch (err) {
        reject(err);
      } finally {
        document.body.removeChild(ta);
      }
    });
  }

  function enhance(heading) {
    /* The code block is the next `.highlight` sibling after the heading —
     * skipping any intro prose between them. */
    var node = heading.nextElementSibling;
    while (node && !node.classList.contains('highlight')) {
      if (/^H[1-6]$/.test(node.tagName)) { return; }   // ran into the next section
      node = node.nextElementSibling;
    }
    if (!node || node.dataset.bgeoAiPrompt === '1') { return; }
    node.dataset.bgeoAiPrompt = '1';

    var code = node.querySelector('code');
    if (!code) { return; }

    var wrap = document.createElement('div');
    wrap.className = 'bgeo-ai-prompt';

    var bar = document.createElement('div');
    bar.className = 'bgeo-ai-prompt__bar';

    var copyBtn = makeButton('bgeo-ai-prompt__copy', 'sparkles', COPY_LABEL);
    var toggleBtn = makeButton('bgeo-ai-prompt__toggle', 'chevron-down', 'Show prompt');
    toggleBtn.setAttribute('aria-expanded', 'false');

    var body = document.createElement('div');
    body.className = 'bgeo-ai-prompt__body';
    body.hidden = true;

    node.parentNode.insertBefore(wrap, node);
    body.appendChild(node);
    bar.appendChild(copyBtn);
    bar.appendChild(toggleBtn);
    wrap.appendChild(bar);
    wrap.appendChild(body);

    toggleBtn.setAttribute('aria-controls', body.id || (body.id = 'bgeo-ai-body-' + Math.random().toString(36).slice(2)));

    toggleBtn.addEventListener('click', function () {
      var open = body.hidden;
      body.hidden = !open;
      toggleBtn.setAttribute('aria-expanded', String(open));
      toggleBtn.classList.toggle('is-open', open);
      toggleBtn.querySelector('.bgeo-ai-label').textContent = open ? 'Hide prompt' : 'Show prompt';
    });

    copyBtn.addEventListener('click', function () {
      /* `innerText` collapses to textContent when the element is not rendered,
       * so this works while the block is still collapsed. */
      copyText(code.innerText || code.textContent).then(function () {
        var label = copyBtn.querySelector('.bgeo-ai-label');
        if (copyBtn.classList.contains('is-copied')) { return; }
        copyBtn.classList.add('is-copied');
        label.textContent = COPIED_LABEL;
        setTimeout(function () {
          copyBtn.classList.remove('is-copied');
          label.textContent = COPY_LABEL;
        }, 2000);
      }).catch(function () { /* clipboard denied — leave the label alone */ });
    });
  }

  window.addEventListener('load', function () {
    var headings = document.querySelectorAll('.md-typeset .ai-prompt');
    Array.prototype.forEach.call(headings, enhance);
  });
}());
