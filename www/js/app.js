/* mcmc3r Bench client behaviour: navigation, language, theme, copy, toast. */
(function () {
  "use strict";

  var I18N = window.MCMC3R_I18N || { en: {}, zh: {} };
  var initial = window.__MCMC3R_INITIAL || { theme: "light", lang: "en" };
  var current = { theme: initial.theme === "dark" ? "dark" : "light",
                  lang: initial.lang === "zh" ? "zh" : "en" };
  var validPages = ["calibration", "mcmc", "marginal", "help", "about"];
  var reducedMotion = window.matchMedia &&
    window.matchMedia("(prefers-reduced-motion: reduce)").matches;

  function dict(lang) {
    return I18N[lang] || I18N.en || {};
  }

  function t(key, lang) {
    var d = dict(lang || current.lang);
    return d[key] || (I18N.en || {})[key] || key;
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
      if (d[key]) el.textContent = d[key];
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
    updateThemeUI();
    localizeFileInputs();
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
    document.documentElement.classList.toggle("theme-dark", current.theme === "dark");
    var meta = document.querySelector('meta[name="theme-color"]');
    if (meta) meta.setAttribute("content", current.theme === "dark" ? "#0B1220" : "#F7F9FB");
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
    if (options.push !== false) {
      try { history.replaceState(null, "", "#" + page); } catch (e) {}
    }
    sendInput("active_tab", page);
    var live = document.getElementById("page-live");
    if (live) live.textContent = t("nav." + page, current.lang);
    if (options.scroll !== false) {
      try {
        window.scrollTo({ top: 0, behavior: reducedMotion ? "auto" : "smooth" });
      } catch (e) { window.scrollTo(0, 0); }
    }
  }

  function showToast(message, type) {
    if (!message) return;
    var region = document.getElementById("toast-region");
    if (!region) return;
    var toast = document.createElement("div");
    toast.className = "app-toast" + (type ? " toast-" + type : "");
    toast.setAttribute("role", "status");
    toast.textContent = message;
    region.appendChild(toast);
    window.setTimeout(function () {
      if (toast.parentNode) toast.parentNode.removeChild(toast);
    }, 3200);
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

  document.addEventListener("DOMContentLoaded", function () {
    setTheme(current.theme, false);
    applyI18n(current.lang);
    localizeFileInputs();
    var hash = (window.location.hash || "").replace("#", "");
    var page = validPages.indexOf(hash) >= 0 ? hash : "calibration";
    showPage(page, { push: false, scroll: false, focus: false });
    // Shiny may connect before or after this script; retry briefly so the
    // server always receives the client-side language/theme decision.
    var attempts = 0;
    var timer = window.setInterval(function () {
      attempts += 1;
      if (pushInitialState() || attempts > 40) window.clearInterval(timer);
    }, 100);
  });

  document.addEventListener("shiny:connected", function () {
    pushInitialState();
    localizeFileInputs();
  });

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
