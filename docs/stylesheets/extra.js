/* GateKeeper — MkDocs Material extra JS
   1. Scroll progress bar
   2. IntersectionObserver fade-in-up (.gk-animate)
   3. STL 3D viewer (Three.js) per .gk-3d-card
*/

(function () {
  "use strict";

  /* ── 1. Scroll progress bar ── */
  function initScrollProgress() {
    var bar = document.createElement("div");
    bar.className = "gk-scroll-progress";
    document.body.appendChild(bar);
    window.addEventListener("scroll", function () {
      var scrollTop = window.scrollY || document.documentElement.scrollTop;
      var docHeight = document.documentElement.scrollHeight - document.documentElement.clientHeight;
      bar.style.width = (docHeight > 0 ? (scrollTop / docHeight) * 100 : 0) + "%";
    }, { passive: true });
  }

  /* ── 2. IntersectionObserver ── */
  function initScrollAnimations() {
    if (!("IntersectionObserver" in window)) {
      document.querySelectorAll(".gk-animate").forEach(function (el) { el.classList.add("gk-visible"); });
      return;
    }
    var observer = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (entry.isIntersecting) { entry.target.classList.add("gk-visible"); observer.unobserve(entry.target); }
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -40px 0px" });
    document.querySelectorAll(".gk-animate").forEach(function (el) { observer.observe(el); });
  }

  /* ── 3. STL Viewer con Three.js ── */
  function loadThreeJS(callback) {
    if (window.THREE) { callback(); return; }
    var scriptThree = document.createElement("script");
    scriptThree.src = "https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js";
    scriptThree.onload = function () {
      var scriptLoader = document.createElement("script");
      scriptLoader.src = "https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/loaders/STLLoader.js";
      scriptLoader.onload = function () {
        var scriptOrbit = document.createElement("script");
        scriptOrbit.src = "https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js";
        scriptOrbit.onload = callback;
        document.head.appendChild(scriptOrbit);
      };
      document.head.appendChild(scriptLoader);
    };
    document.head.appendChild(scriptThree);
  }

  function initSTLViewer(canvas, stlUrl) {
    var THREE = window.THREE;
    var width = canvas.clientWidth || 280;
    var height = canvas.clientHeight || 280;

    var renderer = new THREE.WebGLRenderer({ canvas: canvas, antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setSize(width, height);
    renderer.shadowMap.enabled = true;

    var scene = new THREE.Scene();
    var camera = new THREE.PerspectiveCamera(45, width / height, 0.1, 1000);

    // Illuminazione
    var ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
    scene.add(ambientLight);
    var dirLight = new THREE.DirectionalLight(0x00767a, 1.0);
    dirLight.position.set(5, 10, 5);
    scene.add(dirLight);
    var dirLight2 = new THREE.DirectionalLight(0xffa400, 0.4);
    dirLight2.position.set(-5, -5, -5);
    scene.add(dirLight2);

    // OrbitControls
    var controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.08;
    controls.autoRotate = true;
    controls.autoRotateSpeed = 1.2;

    var loader = new THREE.STLLoader();
    loader.load(stlUrl, function (geometry) {
      geometry.computeBoundingBox();
      var bbox = geometry.boundingBox;
      var center = new THREE.Vector3();
      bbox.getCenter(center);
      geometry.translate(-center.x, -center.y, -center.z);
      var size = new THREE.Vector3();
      bbox.getSize(size);
      var maxDim = Math.max(size.x, size.y, size.z);
      var scale = 3.5 / maxDim;
      geometry.scale(scale, scale, scale);

      var material = new THREE.MeshPhongMaterial({
        color: 0x00767a,
        specular: 0x333333,
        shininess: 40,
        transparent: true,
        opacity: 0.92
      });
      var mesh = new THREE.Mesh(geometry, material);
      scene.add(mesh);

      camera.position.set(0, 2, 5);
      camera.lookAt(0, 0, 0);
      controls.update();
    }, undefined, function (err) {
      console.warn("[GK 3D] Impossibile caricare STL:", stlUrl, err);
    });

    function animate() {
      requestAnimationFrame(animate);
      controls.update();
      renderer.render(scene, camera);
    }
    animate();

    // Resize
    var resizeObs = new ResizeObserver(function () {
      var w = canvas.clientWidth;
      var h = canvas.clientHeight;
      renderer.setSize(w, h);
      camera.aspect = w / h;
      camera.updateProjectionMatrix();
    });
    resizeObs.observe(canvas);
  }

  function initAll3DViewers() {
    var canvases = document.querySelectorAll("canvas[data-stl]");
    if (canvases.length === 0) return;
    loadThreeJS(function () {
      canvases.forEach(function (canvas) {
        initSTLViewer(canvas, canvas.getAttribute("data-stl"));
      });
    });
  }

  /* ── 4. Disabilita autocomplete del browser sulla searchbar ──
     Il browser nativo sovrappone i suggerimenti al testo digitato.
     Impostiamo autocomplete="off" e spellcheck="false" sull'input. */
  function fixSearchAutocomplete() {
    var inputs = document.querySelectorAll(
      ".md-search__input, [data-md-component='search'] input"
    );
    inputs.forEach(function (input) {
      input.setAttribute("autocomplete", "off");
      input.setAttribute("autocorrect", "off");
      input.setAttribute("autocapitalize", "none");
      input.setAttribute("spellcheck", "false");
    });
  }

  /* ── Init ── */
  function onPageLoad() {
    initScrollAnimations();
    initAll3DViewers();
    fixSearchAutocomplete();
  }

  document.addEventListener("DOMContentLoaded", function () {
    initScrollProgress();
    initScrollAnimations();
    initAll3DViewers();
    fixSearchAutocomplete();
  });

  document.addEventListener("DOMContentSwitch", onPageLoad);
  if (typeof document$ !== "undefined" && document$.subscribe) {
    document$.subscribe(onPageLoad);
  }
})();
