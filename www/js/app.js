/* mcmc3r Bench client behaviour: navigation, language, theme, copy, toast. */
(function () {
  "use strict";

  var I18N = window.MCMC3R_I18N || { en: {}, zh: {} };
  var initial = window.__MCMC3R_INITIAL || { theme: "light", lang: "en" };
  var current = { theme: initial.theme === "dark" ? "dark" : "light",
                  lang: initial.lang === "zh" ? "zh" : "en" };
  var validPages = ["calibration", "mcmc", "marginal", "help", "about"];
  var reducedMotionQuery = window.matchMedia &&
    window.matchMedia("(prefers-reduced-motion: reduce)");
  var reducedMotion = !!(reducedMotionQuery && reducedMotionQuery.matches);
  if (reducedMotionQuery) {
    var trackMotion = function (mq) { reducedMotion = mq.matches; };
    if (typeof reducedMotionQuery.addEventListener === "function") {
      reducedMotionQuery.addEventListener("change", trackMotion);
    } else if (typeof reducedMotionQuery.addListener === "function") {
      reducedMotionQuery.addListener(trackMotion);
    }
  }

  function dict(lang) {
    return I18N[lang] || I18N.en || {};
  }

  function interpolate(text, params) {
    if (!params) return text;
    return text.replace(/\{([a-zA-Z0-9_]+)\}/g, function (whole, name) {
      return Object.prototype.hasOwnProperty.call(params, name) ? params[name] : whole;
    });
  }

  function t(key, lang, params) {
    var d = dict(lang || current.lang);
    var text = d[key] || (I18N.en || {})[key] || key;
    return interpolate(text, params);
  }

  function sendInput(name, value) {
    if (window.Shiny && window.Shiny.setInputValue) {
      try {
        window.Shiny.setInputValue(name, value, { priority: "event" });
      } catch (e) { /* Shiny not ready yet */ }
    }
  }

  function pushInitialState() {
    if (!window.Shiny || !window.Shiny.shinyapp) return false;
    var connected = false;
    try { connected = window.Shiny.shinyapp.isConnected(); } catch (e) { connected = false; }
    if (!connected) return false;
    sendInput("lang", current.lang);
    sendInput("theme", current.theme);
    var page = document.querySelector(".page-section:not([hidden])");
    sendInput("active_tab", page ? page.getAttribute("data-page") : "calibration");
    return true;
  }

  function applyI18n(lang) {
    current.lang = lang === "zh" ? "zh" : "en";
    var d = dict(current.lang);
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      var key = el.getAttribute("data-i18n");
      if (!d[key]) return;
      var params = null;
      var raw = el.getAttribute("data-i18n-params");
      if (raw) { try { params = JSON.parse(raw); } catch (e) { params = null; } }
      el.textContent = interpolate(d[key], params);
    });
    document.querySelectorAll("[data-i18n-placeholder]").forEach(function (el) {
      var key = el.getAttribute("data-i18n-placeholder");
      var target = el.matches("input, textarea") ? el : el.querySelector("input, textarea");
      if (target && d[key]) target.setAttribute("placeholder", d[key]);
    });
    ["title", "aria-label"].forEach(function (attr) {
      document.querySelectorAll("[data-i18n-" + attr + "]").forEach(function (el) {
        var key = el.getAttribute("data-i18n-" + attr);
        if (d[key]) el.setAttribute(attr, d[key]);
      });
    });
    document.documentElement.lang = current.lang === "zh" ? "zh-CN" : "en";
    document.documentElement.dataset.lang = current.lang;
    document.title = d["app.title"] || document.title;
    document.querySelectorAll(".lang-btn").forEach(function (btn) {
      var active = btn.getAttribute("data-lang") === current.lang;
      btn.classList.toggle("active", active);
      btn.setAttribute("aria-pressed", active ? "true" : "false");
    });
    var crumb = document.getElementById("sub-nav-current");
    if (crumb) {
      var shown = document.querySelector(".page-section:not([hidden])");
      if (shown) crumb.textContent = t("nav." + shown.getAttribute("data-page"));
    }
    updateThemeUI();
    updateMenuUI();
    localizeFileInputs();
  }

  function menuOpen() {
    var header = document.querySelector(".app-header");
    return !!(header && header.classList.contains("nav-open"));
  }

  function setMenu(open) {
    var header = document.querySelector(".app-header");
    if (!header) return;
    header.classList.toggle("nav-open", !!open);
    updateMenuUI();
    if (open) {
      var first = document.querySelector(".app-nav .nav-btn");
      if (first) first.focus();
    }
  }

  function updateMenuUI() {
    var btn = document.getElementById("nav-toggle");
    if (!btn) return;
    var open = menuOpen();
    btn.setAttribute("aria-expanded", open ? "true" : "false");
    btn.setAttribute("aria-label",
      t(open ? "common.close_menu" : "common.menu", current.lang));
  }

  function updateThemeUI() {
    var dark = current.theme === "dark";
    var btn = document.getElementById("theme-toggle");
    if (!btn) return;
    var label = btn.querySelector(".theme-label");
    var key = dark ? "theme.light" : "theme.dark";
    if (label) {
      label.setAttribute("data-i18n", key);
      label.textContent = t(key, current.lang);
    }
    btn.setAttribute("aria-label",
      t(dark ? "theme.switch_to_light" : "theme.switch_to_dark", current.lang));
    btn.setAttribute("aria-pressed", dark ? "true" : "false");
  }

  function setTheme(theme, persist) {
    current.theme = theme === "dark" ? "dark" : "light";
    document.documentElement.setAttribute("data-bs-theme", current.theme);
    document.documentElement.dataset.theme = current.theme;
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute("content", current.theme === "dark" ? "#000000" : "#F5F5F7");
    if (persist !== false) {
      try { localStorage.setItem("mcmc3r-bench-theme", current.theme); } catch (e) {}
    }
    updateThemeUI();
    sendInput("theme", current.theme);
  }

  function setLang(lang, persist) {
    current.lang = lang === "zh" ? "zh" : "en";
    if (persist !== false) {
      try { localStorage.setItem("mcmc3r-bench-lang", current.lang); } catch (e) {}
    }
    closeHelp();
    applyI18n(current.lang);
    sendInput("lang", current.lang);
  }

  function localizeFileInputs() {
    var d = dict(current.lang);
    document.querySelectorAll(".input-group-btn .btn").forEach(function (btn) {
      var input = btn.querySelector('input[type="file"]');
      Array.prototype.slice.call(btn.childNodes).forEach(function (node) {
        if (node.nodeType === 3) btn.removeChild(node);
      });
      if (input && d["common.browse"]) {
        btn.insertBefore(document.createTextNode(d["common.browse"]), input);
      }
    });
    document.querySelectorAll('.input-group input[type="text"]').forEach(function (input) {
      if (!input.value && d["common.no_file"]) {
        input.setAttribute("placeholder", d["common.no_file"]);
      }
    });
  }

  function showPage(page, options) {
    options = options || {};
    if (validPages.indexOf(page) < 0) page = "calibration";
    document.querySelectorAll(".page-section").forEach(function (section) {
      if (section.getAttribute("data-page") === page) {
        section.removeAttribute("hidden");
      } else {
        section.setAttribute("hidden", "");
      }
    });
    document.querySelectorAll(".nav-btn").forEach(function (btn) {
      var active = btn.getAttribute("data-nav") === page;
      btn.classList.toggle("active", active);
      btn.setAttribute("aria-current", active ? "page" : "false");
    });
    if (options.push === "replace") {
      try { history.replaceState(null, "", "#" + page); } catch (e) {}
    } else if (options.push !== false) {
      // pushState keeps the tab history walkable; replaceState made every
      // in-app page switch unaddressable, so Back left the session entirely.
      if (("#" + page) !== window.location.hash) {
        try { history.pushState(null, "", "#" + page); } catch (e) {}
      }
    }
    setMenu(false);
    sendInput("active_tab", page);
    var live = document.getElementById("page-live");
    if (live) live.textContent = t("nav." + page, current.lang);
    var crumb = document.getElementById("sub-nav-current");
    if (crumb) crumb.textContent = t("nav." + page, current.lang);
    if (options.scroll !== false) {
      try {
        window.scrollTo({ top: 0, behavior: reducedMotion ? "auto" : "smooth" });
      } catch (e) { window.scrollTo(0, 0); }
    }
    if (options.focus !== false) {
      var activeSection = document.querySelector(".page-section:not([hidden])");
      var target = activeSection &&
        (activeSection.querySelector(".page-title") || activeSection);
      if (target) {
        target.setAttribute("tabindex", "-1");
        try { target.focus({ preventScroll: true }); } catch (e) { target.focus(); }
      }
    }
    scheduleRefresh();
  }

  var TOAST_ICONS = {
    error: ["\u26a0", "toast.error"],
    warn: ["\u25b2", "toast.warn"],
    "": ["\u2713", "toast.info"]
  };

  function dismissToast(toast) {
    if (toast && toast.parentNode) toast.parentNode.removeChild(toast);
  }

  function showToast(message, type) {
    if (!message) return;
    var region = document.getElementById("toast-region");
    if (!region) return;
    var kind = type === "error" || type === "warn" ? type : "";
    var toast = document.createElement("div");
    toast.className = "app-toast" + (kind ? " toast-" + kind : "");
    toast.setAttribute("role", kind ? "alert" : "status");

    // The 6px dot alone is colour-only status; add a glyph and a word.
    var label = document.createElement("span");
    label.className = "app-toast-label";
    label.textContent = t(TOAST_ICONS[kind][1]) + ": " + message;
    toast.appendChild(label);

    var close = document.createElement("button");
    close.type = "button";
    close.className = "app-toast-close";
    close.setAttribute("aria-label", t("common.close"));
    close.textContent = "\u00d7";
    close.addEventListener("click", function () { dismissToast(toast); });
    toast.appendChild(close);

    region.appendChild(toast);

    // Errors need reading time and a pause affordance; a fixed 3.2s window is
    // too short to act on "could not copy to clipboard".
    var life = kind === "error" ? 9000 : 4500;
    var remaining = life, started = Date.now(), timer = null;
    function arm() {
      started = Date.now();
      timer = window.setTimeout(function () { dismissToast(toast); }, remaining);
    }
    function hold() {
      if (!timer) return;
      window.clearTimeout(timer); timer = null;
      remaining -= Date.now() - started;
      if (remaining < 0) remaining = 0;
    }
    toast.addEventListener("mouseenter", hold);
    toast.addEventListener("focusin", hold);
    toast.addEventListener("mouseleave", arm);
    toast.addEventListener("focusout", arm);
    arm();
  }

  var helpPopover = null;

  function closeHelp() {
    if (helpPopover) {
      helpPopover.remove();
      helpPopover = null;
    }
    document.querySelectorAll('.help-tip[aria-expanded="true"]').forEach(function (tip) {
      tip.setAttribute("aria-expanded", "false");
      tip.removeAttribute("aria-describedby");
    });
  }

  function positionHelp(tip, el) {
    var rect = tip.getBoundingClientRect();
    var width = Math.min(300, window.innerWidth - 24);
    el.style.width = width + "px";
    el.style.left = Math.max(12,
      Math.min(window.innerWidth - width - 12,
               rect.left + rect.width / 2 - width / 2)) + "px";
    el.style.top = "0px";
    var height = el.offsetHeight;
    var top = rect.bottom + 8;
    if (top + height > window.innerHeight - 12) {
      top = Math.max(12, rect.top - height - 8);
    }
    el.style.top = top + "px";
  }

  function toggleHelp(tip) {
    if (helpPopover && helpPopover.dataset.helpFor === tip.getAttribute("aria-label")) {
      closeHelp();
      return;
    }
    closeHelp();
    var text = tip.getAttribute("aria-label");
    if (!text) return;
    var el = document.createElement("div");
    el.className = "help-tip-popover";
    el.id = "help-tip-popover";
    el.setAttribute("role", "tooltip");
    el.dataset.helpFor = text;
    el.textContent = text;
    document.body.appendChild(el);
    positionHelp(tip, el);
    tip.setAttribute("aria-expanded", "true");
    tip.setAttribute("aria-describedby", el.id);
    helpPopover = el;
  }

  var refreshTimer = null;

  function refreshDynamicA11y() {
    document.querySelectorAll(".dataTables_wrapper").forEach(function (wrapper) {
      var body = wrapper.querySelector(".dataTables_scrollBody");
      var overflow = !!(body && body.clientWidth > 0 &&
        body.scrollWidth > body.clientWidth + 1);
      if (body && overflow && !body.hasAttribute("tabindex")) {
        body.setAttribute("tabindex", "0");
      }
      var hint = wrapper.nextElementSibling;
      if (!hint || !hint.classList.contains("table-scroll-hint")) {
        hint = document.createElement("p");
        hint.className = "table-scroll-hint";
        hint.setAttribute("data-i18n", "common.table_scroll");
        hint.textContent = t("common.table_scroll");
        wrapper.insertAdjacentElement("afterend", hint);
      }
      hint.classList.toggle("is-visible", overflow);
    });
    document.querySelectorAll(".table-scroll-hint").forEach(function (hint) {
      var prev = hint.previousElementSibling;
      if (!prev || !prev.classList.contains("dataTables_wrapper")) hint.remove();
    });
    document.querySelectorAll('.plot-wrap[data-plot-alt] img').forEach(function (img) {
      var wrapper = img.closest(".plot-wrap");
      var alt = wrapper && wrapper.getAttribute("data-plot-alt");
      if (alt && img.getAttribute("alt") !== alt) img.setAttribute("alt", alt);
    });
  }

  function scheduleRefresh() {
    window.clearTimeout(refreshTimer);
    refreshTimer = window.setTimeout(refreshDynamicA11y, 120);
  }

  function copyText(text) {
    if (!text) return;
    if (navigator.clipboard && window.isSecureContext) {
      navigator.clipboard.writeText(text).then(function () {
        showToast(t("toast.copied"));
      }).catch(function () {
        fallbackCopy(text);
      });
    } else {
      fallbackCopy(text);
    }
  }

  function fallbackCopy(text) {
    var area = document.createElement("textarea");
    area.value = text;
    area.setAttribute("readonly", "");
    area.style.position = "fixed";
    area.style.left = "-9999px";
    document.body.appendChild(area);
    area.select();
    var ok = false;
    try { ok = document.execCommand("copy"); } catch (e) { ok = false; }
    document.body.removeChild(area);
    showToast(t(ok ? "toast.copied" : "toast.copy_failed"), ok ? "" : "error");
  }

  document.addEventListener("click", function (event) {
    var helpTip = event.target.closest(".help-tip");
    if (helpTip) {
      event.preventDefault();
      event.stopPropagation();
      toggleHelp(helpTip);
      return;
    }
    var nav = event.target.closest("[data-nav]");
    if (nav) {
      event.preventDefault();
      showPage(nav.getAttribute("data-nav"));
      return;
    }
    var langBtn = event.target.closest(".lang-btn[data-lang]");
    if (langBtn) {
      event.preventDefault();
      setLang(langBtn.getAttribute("data-lang"));
      showToast(t("toast.lang_changed"));
      return;
    }
    if (event.target.closest("#theme-toggle")) {
      event.preventDefault();
      setTheme(current.theme === "dark" ? "light" : "dark");
      showToast(t("toast.theme_changed"));
      return;
    }
    if (event.target.closest("#nav-toggle")) {
      event.preventDefault();
      setMenu(!menuOpen());
      return;
    }
    if (menuOpen() && !event.target.closest(".app-header")) {
      setMenu(false);
    }
    closeHelp();
    var copyTarget = event.target.closest("[data-copy-target]");
    if (copyTarget) {
      event.preventDefault();
      var target = document.querySelector(copyTarget.getAttribute("data-copy-target"));
      copyText(target ? target.textContent : "");
      return;
    }
    var copyInline = event.target.closest("[data-copy-text]");
    if (copyInline) {
      event.preventDefault();
      copyText(copyInline.getAttribute("data-copy-text"));
    }
  });

  document.addEventListener("keydown", function (event) {
    var tip = event.target.closest && event.target.closest(".help-tip");
    if (tip && (event.key === "Enter" || event.key === " " ||
                event.key === "Spacebar")) {
      event.preventDefault();
      toggleHelp(tip);
      return;
    }
    if (event.key === "Escape") {
      closeHelp();
      if (menuOpen()) {
        setMenu(false);
        var btn = document.getElementById("nav-toggle");
        if (btn) btn.focus();
      }
    }
  });

  document.addEventListener("focusout", function (event) {
    if (event.target.closest && event.target.closest(".help-tip")) {
      window.setTimeout(function () {
        if (!document.activeElement ||
            !document.activeElement.closest(".help-tip")) {
          closeHelp();
        }
      }, 0);
    }
  });

  window.addEventListener("scroll", closeHelp, { passive: true });
  window.addEventListener("resize", function () {
    closeHelp();
    scheduleRefresh();
  });

  document.addEventListener("DOMContentLoaded", function () {
    setTheme(current.theme, false);
    applyI18n(current.lang);
    updateMenuUI();
    localizeFileInputs();
    var skip = document.querySelector(".skip-link");
    if (skip) {
      skip.addEventListener("click", function () {
        var main = document.getElementById("main");
        if (main) {
          window.setTimeout(function () {
            try { main.focus({ preventScroll: true }); } catch (e) { main.focus(); }
          }, 0);
        }
      });
    }
    var hash = (window.location.hash || "").replace("#", "");
    var page = validPages.indexOf(hash) >= 0 ? hash : "calibration";
    showPage(page, { push: "replace", scroll: false, focus: false });
    scheduleRefresh();
    // Shiny may connect before or after this script; retry briefly so the
    // server always receives the client-side language/theme decision.
    var attempts = 0;
    var timer = window.setInterval(function () {
      attempts += 1;
      if (pushInitialState() || attempts > 40) window.clearInterval(timer);
    }, 100);
  });

  window.addEventListener("popstate", function () {
    var page = (window.location.hash || "").replace("#", "");
    if (validPages.indexOf(page) >= 0) {
      showPage(page, { push: false, scroll: false, focus: false });
    }
  });

  window.addEventListener("hashchange", function () {
    var page = (window.location.hash || "").replace("#", "");
    if (validPages.indexOf(page) >= 0) {
      showPage(page, { push: false, scroll: false, focus: false });
    }
  });

  document.addEventListener("shiny:connected", function () {
    pushInitialState();
    localizeFileInputs();
    scheduleRefresh();
  });

  if (window.MutationObserver && document.body) {
    new MutationObserver(scheduleRefresh).observe(document.body, {
      childList: true,
      subtree: true
    });
  }

  if (window.Shiny) {
    window.Shiny.addCustomMessageHandler("toast", function (msg) {
      showToast(msg && msg.message, msg && msg.type);
    });
    window.Shiny.addCustomMessageHandler("reset-input", function (id) {
      var el = document.getElementById(id);
      if (!el) return;
      var file = el.matches('input[type="file"]') ? el : el.querySelector('input[type="file"]');
      if (file) file.value = "";
      var text = el.matches('input[type="text"]') ? el : el.querySelector('input[type="text"]');
      if (text) text.value = "";
      sendInput(id, null);
      localizeFileInputs();
    });
    window.Shiny.addCustomMessageHandler("apply-lang", function (lang) {
      setLang(lang, false);
    });
    window.Shiny.addCustomMessageHandler("apply-theme", function (theme) {
      setTheme(theme, false);
    });
    window.Shiny.addCustomMessageHandler("run-state", function (msg) {
      if (!msg || !msg.id) return;
      var el = document.getElementById(msg.id);
      if (!el) return;
      if (msg.running) {
        el.disabled = true;
        el.classList.add("is-running");
        el.setAttribute("aria-busy", "true");
      } else {
        el.disabled = false;
        el.classList.remove("is-running");
        el.removeAttribute("aria-busy");
      }
    });
  }

  window.MCMC3R = {
    setLang: setLang,
    setTheme: setTheme,
    showPage: showPage,
    toast: showToast
  };
})();
