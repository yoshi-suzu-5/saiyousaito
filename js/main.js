// ===========================
// ハンバーガーメニュー
// ===========================
const hamburger = document.getElementById('hamburger');
const mainNav = document.getElementById('mainNav');

if (hamburger && mainNav) {
  hamburger.addEventListener('click', () => {
    hamburger.classList.toggle('active');
    mainNav.classList.toggle('open');
  });

  // ナビリンククリックでメニューを閉じる
  mainNav.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      hamburger.classList.remove('active');
      mainNav.classList.remove('open');
    });
  });
}

// ===========================
// スクロール時ヘッダーシャドウ
// ===========================
const header = document.querySelector('.site-header');
if (header) {
  window.addEventListener('scroll', () => {
    if (window.scrollY > 10) {
      header.style.boxShadow = '0 4px 24px rgba(0,0,0,0.12)';
    } else {
      header.style.boxShadow = '0 2px 12px rgba(0,0,0,0.08)';
    }
  });
}

// ===========================
// スムーススクロール（ハッシュリンク）
// ===========================
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
  anchor.addEventListener('click', function (e) {
    const href = this.getAttribute('href');
    if (href === '#') return;
    const target = document.querySelector(href);
    if (target) {
      e.preventDefault();
      const offset = 80; // ヘッダーの高さ分
      const top = target.getBoundingClientRect().top + window.scrollY - offset;
      window.scrollTo({ top, behavior: 'smooth' });
    }
  });
});

// ===========================
// スクロールアニメーション（Intersection Observer）
// ===========================
const observerOptions = {
  threshold: 0.1,
  rootMargin: '0px 0px -40px 0px'
};

const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = '1';
      entry.target.style.transform = 'translateY(0)';
      observer.unobserve(entry.target);
    }
  });
}, observerOptions);

// アニメーション対象要素を設定
const animTargets = document.querySelectorAll(
  '.job-card, .appeal-item, .number-item, .flow-step, .persona-card, .hero-card, .other-job-link'
);

animTargets.forEach((el, index) => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(24px)';
  el.style.transition = `opacity 0.5s ease ${index * 0.05}s, transform 0.5s ease ${index * 0.05}s`;
  observer.observe(el);
});

// ===========================
// 数字カウントアップアニメーション
// ===========================
function animateCount(el, target, suffix) {
  const duration = 1500;
  const start = performance.now();

  function update(time) {
    const elapsed = time - start;
    const progress = Math.min(elapsed / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3); // ease-out cubic
    const current = Math.round(eased * target);

    // フォーマット（3桁区切り）
    el.textContent = current.toLocaleString('ja-JP') + suffix;

    if (progress < 1) {
      requestAnimationFrame(update);
    }
  }

  requestAnimationFrame(update);
}

// 数字要素を監視
const numberObserver = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      const el = entry.target;
      const raw = el.dataset.count;
      const suffix = el.dataset.suffix || '';
      if (raw) {
        animateCount(el, parseInt(raw, 10), suffix);
      }
      numberObserver.unobserve(el);
    }
  });
}, { threshold: 0.5 });

document.querySelectorAll('.number-value[data-count]').forEach(el => {
  numberObserver.observe(el);
});
