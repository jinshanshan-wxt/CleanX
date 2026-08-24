// CleanX 注入脚本 —— 在 x.com 页面上执行
// 功能：隐藏广告/推广、关键字屏蔽、主题应用、翻译按钮
(function () {
  'use strict';

  function escRegex(s) {
    return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  }

  function buildKeywordRegexes(keywords) {
    var out = [];
    (keywords || []).forEach(function (k) {
      if (!k) return;
      // 优先当作正则使用；解析失败则当作普通文本匹配
      try {
        out.push(new RegExp(k, 'i'));
      } catch (e) {
        try { out.push(new RegExp(escRegex(k), 'i')); } catch (e2) {}
      }
    });
    return out;
  }

  // 读取 window.__CLEANX__ 并应用到页面（主题 + 侧栏 + 关键字）
  function applySettings() {
    var s = window.__CLEANX__ || {};
    var t = s.theme;
    if (t) {
      document.documentElement.style.setProperty('background', t.background, 'important');
      document.body.style.setProperty('background', t.background, 'important');
      document.body.style.setProperty('color', t.text, 'important');
    }
    document.documentElement.classList.toggle('cx-hide-sidebars', !!s.hideSidebars);
    window.__CLEANX__keywords = buildKeywordRegexes(s.keywords);
    window.__CLEANX__hideAds = s.hideAds !== false;
  }
  window.__CLEANX_applySettings = applySettings;

  function textOf(article) {
    var t = article.querySelector('[data-testid="tweetText"]');
    return t ? (t.textContent || '') : (article.textContent || '');
  }

  function isPromoted(article) {
    // 1) 官方投放标记元素
    if (article.querySelector('[data-testid="placementTracking"]')) return true;
    // 2) 社交上下文里的 "Promoted / Ad / 推广 / 赞助"
    var ctx = article.querySelector('[data-testid="socialContext"]');
    if (ctx) {
      var t = ctx.textContent || '';
      if (/\b(promoted|promote|sponsored|ad)\b|推广|赞助|广告/i.test(t)) return true;
    }
    return false;
  }

  function isInlineSuggestion(article) {
    // 时间线里内嵌的 "你可能喜欢 / Who to follow" 推荐块
    var t = article.textContent || '';
    return /你可能喜欢|you might like|who to follow|promoted accounts/i.test(t);
  }

  function matchesKeyword(article) {
    var re = window.__CLEANX__keywords || [];
    if (!re.length) return false;
    var txt = textOf(article);
    return re.some(function (r) { return r.test(txt); });
  }

  function addTranslateButton(article) {
    var textEl = article.querySelector('[data-testid="tweetText"]');
    if (!textEl || article.querySelector('.cx-translate')) return;

    var btn = document.createElement('div');
    btn.className = 'cx-translate';
    btn.textContent = '翻译';
    btn.style.cssText = 'cursor:pointer;color:#1d9bf0;font-size:13px;line-height:1;margin-top:8px;user-select:none;-webkit-user-select:none;';

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

  // 原生端回调：把翻译结果显示在按钮位置
  window.__CLEANX_showTranslation = function (id, text, ok) {
    var btn = (window.__CLEANX__pending || {})[id];
    if (!btn) return;
    delete window.__CLEANX__pending[id];

    if (!ok) {
      btn.textContent = text || '翻译失败';
      btn.dataset.done = '1';
      return;
    }

    var box = document.createElement('div');
    box.className = 'cx-translation';
    box.style.cssText = 'margin-top:6px;padding:8px 10px;background:rgba(29,155,240,.10);border-left:3px solid #1d9bf0;border-radius:6px;font-size:14px;line-height:1.45;white-space:pre-wrap;word-break:break-word;';
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
  }

  function start() {
    applySettings();
    var obs = new MutationObserver(function (muts) {
      for (var i = 0; i < muts.length; i++) {
        var added = muts[i].addedNodes;
        for (var j = 0; j < added.length; j++) {
          var n = added[j];
          if (n.nodeType === 1) scan(n);
        }
      }
    });
    obs.observe(document.documentElement, { childList: true, subtree: true });
    scan(document);
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
