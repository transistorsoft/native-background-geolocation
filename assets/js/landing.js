/* Landing page scripts.
 *
 * 1. Clear stored platform preference — root is the neutral state.
 * 2. Persist chosen platform when a platform card is clicked.
 */
(function () {
  'use strict';

  try { localStorage.removeItem('bgeo-platform'); } catch (_) {}

  document.addEventListener('click', function (e) {
    var card = e.target.closest('[data-platform]');
    if (!card) return;
    try { localStorage.setItem('bgeo-platform', card.dataset.platform); } catch (_) {}
  });
}());
