// Progressive enhancement for the static site. No framework, no build step.
// Hooks are opted into with data-hook attributes, mirroring the markup the
// views already emit.
(function () {
  function scrollspy(nav) {
    const links = new Map();
    nav.querySelectorAll('a[href^="/#"]').forEach((a) => {
      const id = a.getAttribute("href").slice(2);
      if (id) links.set(id, a);
    });
    if (links.size === 0) return;

    let active = null;
    const setActive = (id) => {
      if (active === id) return;
      if (active) links.get(active)?.classList.remove("nav-active");
      active = id;
      if (id) links.get(id)?.classList.add("nav-active");
    };

    const visible = new Map();
    const observer = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (e.isIntersecting) visible.set(e.target.id, e.intersectionRatio);
          else visible.delete(e.target.id);
        }
        let best = null;
        let bestRatio = 0;
        for (const [id, ratio] of visible) {
          if (ratio > bestRatio) {
            best = id;
            bestRatio = ratio;
          }
        }
        setActive(best);
      },
      { threshold: [0, 0.25, 0.5, 0.75, 1] }
    );

    for (const id of links.keys()) {
      const section = document.getElementById(id);
      if (section) observer.observe(section);
    }
  }

  function preserveScroll(el) {
    const key = "az-scroll:" + (el.dataset.scrollKey || el.id || "default");
    const saved = sessionStorage.getItem(key);
    if (saved !== null) el.scrollTop = parseInt(saved, 10) || 0;
    window.addEventListener("beforeunload", () => {
      sessionStorage.setItem(key, el.scrollTop.toString());
    });
  }

  function init() {
    document.querySelectorAll('[data-hook="Scrollspy"]').forEach(scrollspy);
    document.querySelectorAll('[data-hook="PreserveScroll"]').forEach(preserveScroll);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
