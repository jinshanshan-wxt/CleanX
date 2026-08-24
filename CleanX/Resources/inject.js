// CleanX 注入脚本
// 功能：去广告、关键字屏蔽、主题/字体/强调色、隐藏各类模块、默认关注时间线、翻译按钮、抓取推文
(function () {
  'use strict';

  function escRegex(s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  function buildKeywordRegexes(keywords) {
    var out = [];
    (keywords || []).forEach(function (k) {
      if (!k) return;
      try { out.push(new RegExp(k, 'i')); }
      catch (e) { try { out.push(new RegExp(escRegex(k), 'i')); } catch (e2) {} }
    });
    return out;
  }

  function applySettings() {
    var s = window.__CLEANX__ || {};
    var t = s.theme;
    if (t) {
      document.documentElement.style.setProperty('background', t.background, 'important');
      document.body.style.setProperty('background', t.background, 'important');
      document.body.style.setProperty('color', t.text, 'important');
    }
    if (s.font) {
      document.body.style.setProperty('font-family', s.font, 'important');
    }
    if (s.accent) {
      document.documentElement.style.setProperty('--cx-accent', s.accent);
    }
    var d = document.documentElement;
    d.classList.toggle('cx-hide-sidebars', !!s.hideSidebars);
    d.classList.toggle('cx-hide-verified', !!s.hideVerified);
    d.classList.toggle('cx-hide-bookmark', !!s.hideBookmark);
    d.classList.toggle('cx-hide-views', !!s.hideViewCount);
    d.classList.toggle('cx-hide-spaces', !!s.hideSpaces);
    d.classList.toggle('cx-hide-chrome', !!s.hideChrome);

    window.__CLEANX__keywords = buildKeywordRegexes(s.keywords);
    window.__CLEANX__hideAds = s.hideAds !== false;
  }
  window.__CLEANX_applySettings = applySettings;

  function textOf(article) {
    var t = article.querySelector('[data-testid="tweetText"]');
    return t ? (t.textContent || '') : (article.textContent || '');
  }

  function isPromoted(article) {
    if (article.querySelector('[data-testid="placementTracking"]')) return true;
    var ctx = article.querySelector('[data-testid="socialContext"]');
    if (ctx) {
      var t = ctx.textContent || '';
      if (/\b(promoted|promote|sponsored|ad)\b|推广|赞助|广告/i.test(t)) return true;
    }
    return false;
  }

  function isInlineSuggestion(article) {
    var t = article.textContent || '';
    return /你可能喜欢|you might like|who to follow|promoted accounts/i.test(t);
  }

  function matchesKeyword(article) {
    var re = window.__CLEANX__keywords || [];
    if (!re.length) return false;
    return re.some(function (r) { return r.test(textOf(article)); });
  }

  function findHeadings(root) {
    var list = [];
    if (root.matches && root.matches('h1,h2,h3,[role="heading"]')) list.push(root);
    if (root.querySelectorAll) {
      list = list.concat(Array.prototype.slice.call(root.querySelectorAll('h1,h2,h3,[role="heading"]')));
    }
    return list;
  }

  function hideHeadingModules(root) {
    var s = window.__CLEANX__ || {};
    var reWtf = /who to follow|推荐关注|推荐用户|可能感兴趣/i;
    var rePremium = /subscribe to premium|订阅.*premium|premium.*订阅/i;
    findHeadings(root).forEach(function (h) {
      var t = h.textContent || '';
      var hit = false;
      if (s.hideWhoToFollow && reWtf.test(t)) hit = true;
      if (s.hidePremium && rePremium.test(t)) hit = true;
      if (!hit) return;
      var el = h;
      for (var i = 0; i < 6 && el; i++) {
        el = el.parentElement;
        if (!el) break;
        var tid = el.getAttribute ? el.getAttribute('data-testid') : null;
        if (el.tagName === 'SECTION' || tid === 'cellInnerDiv' || tid === 'UserCell') {
          el.style.display = 'none';
          el.dataset.cxHidden = 'module';
          break;
        }
      }
    });
  }

  function maybeClickFollowing() {
    var s = window.__CLEANX__ || {};
    if (!s.alwaysFollowing) return;
    var p = location.pathname;
    if (p !== '/home' && p !== '/') return;
    var tabs = document.querySelectorAll('[role="tab"]');
    for (var i = 0; i < tabs.length; i++) {
      if (/following|关注/i.test(tabs[i].textContent || '')) {
        tabs[i].click();
        return;
      }
    }
  }

  function addTranslateButton(article) {
    var textEl = article.querySelector('[data-testid="tweetText"]');
    if (!textEl || article.querySelector('.cx-translate')) return;
    var btn = document.createElement('div');
    btn.className = 'cx-translate';
    btn.textContent = '翻译';
    btn.style.cssText = 'cursor:pointer;color:var(--cx-accent,#1d9bf0);font-size:13px;line-height:1;margin-top:8px;user-select:none;-webkit-user-select:none;';
    var id = 't' + Date.now().toString(36) + Math.random().toString(36).slice(2, 8);
    btn.addEventListener('click', function () {
      if (btn.dataset.done === '1') return;
      btn.textContent = '翻译中…';
      window.__CLEANX__pending = window.__CLEANX__pending || {};
      window.__CLEANX__pending[id] = btn;
      var txt = textEl.textContent || '';
      if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.cleanx) {
        window.webkit.messageHandlers.cleanx.postMessage({ type: 'translate', id: id, text: txt });
      } else {
        btn.textContent = '当前环境不支持翻译';
        btn.dataset.done = '1';
      }
    });
    textEl.parentElement.insertBefore(btn, textEl.nextSibling);
  }

  window.__CLEANX_showTranslation = function (id, text, ok) {
    var btn = (window.__CLEANX__pending || {})[id];
    if (!btn) return;
    delete window.__CLEANX__pending[id];
    if (!ok) { btn.textContent = text || '翻译失败'; btn.dataset.done = '1'; return; }
    var box = document.createElement('div');
    box.className = 'cx-translation';
    box.style.cssText = 'margin-top:6px;padding:8px 10px;background:rgba(29,155,240,.10);border-left:3px solid var(--cx-accent,#1d9bf0);border-radius:6px;font-size:14px;line-height:1.45;white-space:pre-wrap;word-break:break-word;';
    box.textContent = text;
    btn.replaceWith(box);
  };

  function processArticle(article) {
    if (article.dataset.cxDone === '1') return;
    article.dataset.cxDone = '1';
    if (window.__CLEANX__hideAds && (isPromoted(article) || isInlineSuggestion(article))) {
      article.style.display = 'none';
      article.dataset.cxHidden = 'ad';
      return;
    }
    if (matchesKeyword(article)) {
      article.style.display = 'none';
      article.dataset.cxHidden = 'keyword';
      return;
    }
    addTranslateButton(article);
  }

  function scan(root) {
    if (root.matches && root.matches('article')) processArticle(root);
    if (root.querySelectorAll) root.querySelectorAll('article').forEach(processArticle);
    hideHeadingModules(root);
  }

  // 原生模式抓取：把当前可见推文导出为 JSON
  window.__CLEANX_scrape = function () {
    var out = [];
    document.querySelectorAll('article[data-testid="tweet"]').forEach(function (a) {
      var textEl = a.querySelector('[data-testid="tweetText"]');
      if (!textEl) return;
      var nameEl = a.querySelector('[data-testid="User-Name"]');
      var img = a.querySelector('img[src*="profile_images"], img[src*="pbs.twimg.com/profile"]');
      var timeEl = a.querySelector('time');
      var nm = nameEl ? (nameEl.textContent || '') : '';
      var parts = nm.split('@');
      var authorName = (parts[0] || '').trim();
      var handlePart = parts.length > 1 ? parts[1].split('·')[0].trim() : '';
      out.push({
        id: 't' + out.length + '_' + Math.random().toString(36).slice(2, 8),
        text: textEl.textContent,
        authorName: authorName,
        authorHandle: handlePart ? '@' + handlePart : '',
        avatarURL: img ? img.src : null,
        timestamp: timeEl ? timeEl.getAttribute('datetime') : null
      });
    });
    return JSON.stringify(out);
  };

  function start() {
    applySettings();
    var obs = new MutationObserver(function (muts) {
      for (var i = 0; i < muts.length; i++) {
        var added = muts[i].addedNodes;
        for (var j = 0; j < added.length; j++) {
          if (added[j].nodeType === 1) scan(added[j]);
        }
      }
    });
    obs.observe(document.documentElement, { childList: true, subtree: true });
    scan(document);
    maybeClickFollowing();
    setTimeout(maybeClickFollowing, 1500);

    // 兜底：每 2 秒清一遍漏网的广告
    setInterval(function () {
      if (!window.__CLEANX__hideAds) return;
      document.querySelectorAll('[data-testid="placementTracking"]').forEach(function (el) {
        var a = el.closest('article') || el.parentElement;
        if (a) { a.style.display = 'none'; a.dataset.cxHidden = 'ad'; }
      });
    }, 2000);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
