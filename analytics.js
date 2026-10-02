/**
 * PromptHQ : Google Analytics 4, même mécanique que le site BlueVisa (site/scripts/analytics.js).
 *
 * - Ne s'active qu'en production (prompthq.fr, www.prompthq.fr). Ailleurs (local, staging), rien n'est
 *   envoyé à Google : chaque appel est seulement affiché en console (`[GA4] …`) pour vérifier les événements.
 * - Chargement différé : le stub gtag() et dataLayer sont posés tout de suite, le vrai gtag.js (~180 Ko)
 *   n'est demandé qu'à la première interaction (pointerdown, scroll, keydown) ou 3,5 s après `load`.
 * - Identifiant de mesure : constante GA4_MEASUREMENT_ID ci-dessous (Google Analytics > Admin > Flux de
 *   données > Web > ID de mesure). Tant qu'il est vide, le script reste en mode console, même en production.
 *
 * Helpers exposés : window.trackEvent(name, params), window.trackCTA(name, location), window.trackFormSubmit(form, params).
 * Automatique : page_view (gtag), cta_click (délégué sur .btn, .btn-primary, [data-track-cta]), outbound_click (liens externes).
 */
(function () {
  'use strict';

  var GA4_MEASUREMENT_ID = 'G-56XBYLGXYR';

  var host = window.location.hostname;
  var isProduction = host === 'prompthq.fr' || host === 'www.prompthq.fr';
  var live = isProduction && !!GA4_MEASUREMENT_ID;

  // Partie du site : hall, learn ou studio, envoyée avec chaque événement
  var section = window.location.pathname.indexOf('/learn') === 0 ? 'learn'
    : window.location.pathname.indexOf('/studio') === 0 ? 'studio' : 'hall';

  if (!live) {
    window.gtag = function () { console.debug('[GA4]', Array.prototype.slice.call(arguments)); };
  } else {
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag('js', new Date());
    window.gtag('config', GA4_MEASUREMENT_ID, {
      send_page_view: true,
      anonymize_ip: true,
      page_location: window.location.href,
      site_section: section
    });

    var loaded = false;
    var interactions = ['pointerdown', 'scroll', 'keydown'];
    var fallback = null;
    var loadGtag = function () {
      if (loaded) return;
      loaded = true;
      interactions.forEach(function (evt) { window.removeEventListener(evt, loadGtag); });
      if (fallback) { clearTimeout(fallback); fallback = null; }
      var s = document.createElement('script');
      s.async = true;
      s.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA4_MEASUREMENT_ID;
      document.head.appendChild(s);
    };
    interactions.forEach(function (evt) { window.addEventListener(evt, loadGtag, { once: true, passive: true }); });
    if (document.readyState === 'complete') fallback = setTimeout(loadGtag, 3500);
    else window.addEventListener('load', function () { fallback = setTimeout(loadGtag, 3500); }, { once: true });
  }

  var base = function (params) {
    var p = { page_path: window.location.pathname, site_section: section, lang: document.documentElement.lang || 'fr' };
    for (var k in (params || {})) p[k] = params[k];
    return p;
  };

  /** Événement GA4 nommé, avec page_path, site_section et lang ajoutés automatiquement. */
  window.trackEvent = function (name, params) { window.gtag('event', name, base(params)); };

  /** Clic sur un appel à l'action. */
  window.trackCTA = function (ctaName, location) {
    window.trackEvent('cta_click', { cta_name: ctaName, cta_location: location || 'unknown' });
  };

  /** Envoi de formulaire (newsletter, contact studio). */
  window.trackFormSubmit = function (formName, params) {
    var p = { form_name: formName };
    for (var k in (params || {})) p[k] = params[k];
    window.trackEvent('form_submit', p);
  };

  // Clics CTA : délégué au document, donc valable aussi pour le contenu injecté après coup
  document.addEventListener('click', function (e) {
    if (!e.target || typeof e.target.closest !== 'function') return;
    var btn = e.target.closest('[data-track-cta], .btn-primary, .btn');
    if (!btn) return;
    var name = btn.dataset.trackCta || (btn.textContent || '').trim().toLowerCase().replace(/\s+/g, '_').substring(0, 50);
    var location = (btn.closest('section, header, footer, [data-section]') || {}).id
      || ((btn.closest('[data-section]') || {}).dataset || {}).section || 'unknown';
    window.trackCTA(name, location);
  });

  // Liens sortants (Discord, réseaux, partenaires)
  document.addEventListener('click', function (e) {
    if (!e.target || typeof e.target.closest !== 'function') return;
    var a = e.target.closest('a[href^="http"]');
    if (!a || a.hostname === host) return;
    window.trackEvent('outbound_click', { link_url: a.href, link_domain: a.hostname, link_text: (a.textContent || '').trim().substring(0, 100) });
  });
})();
