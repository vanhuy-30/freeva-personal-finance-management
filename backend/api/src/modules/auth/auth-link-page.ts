export type AuthLinkKind = 'verify-email' | 'reset-password';

/** Same scheme the mobile app registers; keep in sync with iOS Info.plist and AndroidManifest. */
const APP_SCHEME = 'freeva';

/**
 * Content-Security-Policy for the link pages. Helmet's default would block the inline script, so the
 * page gets its own policy: only this response's nonce may run, and the only network target is the
 * API on the same origin.
 */
export function authLinkCsp(nonce: string): string {
  return [
    "default-src 'none'",
    `script-src 'nonce-${nonce}'`,
    `style-src 'nonce-${nonce}'`,
    "connect-src 'self'",
    "form-action 'none'",
    "base-uri 'none'",
    "frame-ancestors 'none'",
  ].join('; ');
}

const STYLE = `
:root{color-scheme:light dark;--bg:#f6f7f9;--card:#fff;--text:#14181f;--muted:#5b6472;--line:#e3e6eb;--accent:#2563eb;--accent-text:#fff;--ok:#1f8a5b;--bad:#c2410c}
@media (prefers-color-scheme:dark){:root{--bg:#0e1116;--card:#171b22;--text:#eef1f5;--muted:#9aa4b2;--line:#262c36;--accent:#4f83f1;--accent-text:#0b1020;--ok:#43b98a;--bad:#f0884a}}
*{box-sizing:border-box}
body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;padding:16px;background:var(--bg);color:var(--text);font:16px/1.5 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
main{width:100%;max-width:420px;background:var(--card);border:1px solid var(--line);border-radius:16px;padding:28px 24px;text-align:center}
.brand{font-weight:700;letter-spacing:.02em;color:var(--accent);margin:0 0 16px}
h1{font-size:22px;line-height:1.3;margin:0 0 8px}
p{margin:0 0 20px;color:var(--muted)}
section[hidden],p[hidden]{display:none}
.hint{margin:16px 0 0}
.btn{display:block;width:100%;min-height:48px;padding:12px 16px;border:0;border-radius:12px;background:var(--accent);color:var(--accent-text);font:inherit;font-weight:600;text-decoration:none;cursor:pointer}
.btn[disabled]{opacity:.6;cursor:default}
.ok h1{color:var(--ok)}
.bad h1{color:var(--bad)}
`;

const SCRIPT = `
(function(){
  // A different fragment in the same tab does not reload the page; start over so state matches the link.
  window.addEventListener('hashchange', function(){ location.reload(); });
  var kind = document.body.getAttribute('data-kind');
  var scheme = document.body.getAttribute('data-scheme');
  var hash = (location.hash || '').replace(/^#/, '');
  var token = new URLSearchParams(hash).get('token');
  token = token ? token.toLowerCase() : '';
  var valid = /^[a-f0-9]{64}$/.test(token);
  function show(name){
    var all = document.querySelectorAll('section[data-state]');
    for (var i = 0; i < all.length; i++) {
      all[i].hidden = all[i].getAttribute('data-state') !== name;
    }
  }
  if (!valid) { show('invalid'); return; }

  if (kind === 'reset-password') {
    var open = document.getElementById('open-app');
    open.setAttribute('href', scheme + '://reset-password?token=' + encodeURIComponent(token));
    open.addEventListener('click', function(){
      setTimeout(function(){
        if (!document.hidden) document.getElementById('no-app').hidden = false;
      }, 1800);
    });
    show('idle');
    return;
  }

  var confirmBtn = document.getElementById('confirm');
  var busy = false;
  function verify(){
    if (busy) return;
    busy = true;
    confirmBtn.disabled = true;
    show('busy');
    fetch('/api/v1/auth/verify-email', {
      method: 'POST',
      headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({token: token}),
      cache: 'no-store',
      credentials: 'omit',
      referrerPolicy: 'no-referrer'
    }).then(function(res){
      busy = false;
      confirmBtn.disabled = false;
      if (res.status === 204) show('done');
      else if (res.status === 400) show('expired');
      else if (res.status === 429) show('limited');
      else show('error');
    }).catch(function(){
      busy = false;
      confirmBtn.disabled = false;
      show('error');
    });
  }
  confirmBtn.addEventListener('click', verify);
  var retries = document.querySelectorAll('[data-retry]');
  for (var j = 0; j < retries.length; j++) retries[j].addEventListener('click', verify);
  show('idle');
})();
`;

const VERIFY_SECTIONS = `
<section data-state="idle" hidden>
  <h1>Xác nhận email</h1>
  <p>Bấm nút bên dưới để xác nhận email cho tài khoản Freeva của bạn.</p>
  <button id="confirm" class="btn" type="button">Xác nhận email</button>
</section>
<section data-state="busy" hidden>
  <h1>Đang xác nhận…</h1>
  <p>Vui lòng chờ trong giây lát.</p>
</section>
<section data-state="done" class="ok" hidden>
  <h1>Email đã được xác nhận</h1>
  <p>Bạn có thể quay lại ứng dụng Freeva và tiếp tục.</p>
</section>
<section data-state="expired" class="bad" hidden>
  <h1>Link đã hết hạn hoặc đã dùng</h1>
  <p>Mở ứng dụng Freeva và chọn gửi lại email xác nhận để nhận link mới.</p>
</section>
<section data-state="limited" class="bad" hidden>
  <h1>Thử quá nhiều lần</h1>
  <p>Hãy chờ vài phút rồi thử lại.</p>
  <button class="btn" type="button" data-retry>Thử lại</button>
</section>
<section data-state="error" class="bad" hidden>
  <h1>Chưa xác nhận được</h1>
  <p>Có lỗi kết nối hoặc máy chủ. Hãy thử lại sau ít phút.</p>
  <button class="btn" type="button" data-retry>Thử lại</button>
</section>`;

const RESET_SECTIONS = `
<section data-state="idle" hidden>
  <h1>Đặt lại mật khẩu</h1>
  <p>Mở ứng dụng Freeva trên điện thoại này để đặt mật khẩu mới.</p>
  <a id="open-app" class="btn" href="#">Mở Freeva</a>
  <p id="no-app" class="hint" hidden>Chưa mở được? Hãy cài ứng dụng Freeva, hoặc mở lại link trong email trên điện thoại đã cài Freeva.</p>
</section>`;

const INVALID_SECTION = `
<section data-state="invalid" class="bad" hidden>
  <h1>Link không hợp lệ</h1>
  <p>Link bị thiếu hoặc không đúng. Hãy mở lại link trong email, hoặc yêu cầu gửi email mới trong ứng dụng Freeva.</p>
</section>`;

/**
 * Static HTML for the email link pages. No value from the request ever reaches the markup: the
 * token lives in the URL fragment and is read only by the script in the browser.
 */
export function renderAuthLinkPage(kind: AuthLinkKind, nonce: string): string {
  const title = kind === 'verify-email' ? 'Xác nhận email' : 'Đặt lại mật khẩu';
  const sections = kind === 'verify-email' ? VERIFY_SECTIONS : RESET_SECTIONS;
  return `<!doctype html>
<html lang="vi">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex, nofollow">
<meta name="referrer" content="no-referrer">
<title>${title} · Freeva</title>
<style nonce="${nonce}">${STYLE}</style>
</head>
<body data-kind="${kind}" data-scheme="${APP_SCHEME}">
<main>
<p class="brand">Freeva</p>
${sections}
${INVALID_SECTION}
<noscript><h1>Cần bật JavaScript</h1><p>Hãy bật JavaScript trong trình duyệt rồi mở lại link.</p></noscript>
</main>
<script nonce="${nonce}">${SCRIPT}</script>
</body>
</html>
`;
}
