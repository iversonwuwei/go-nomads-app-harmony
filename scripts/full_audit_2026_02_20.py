import json
import re
from pathlib import Path

ROOT = Path('/Users/walden/Workspaces/WaldenProjects/go-nomads-project/go-nomads-app-harmony/go_nomads_app/src/main/ets')
PAGES = sorted(list((ROOT / 'pages').glob('*.ets')) + list((ROOT / 'pages/tabs').glob('*.ets')))

result: dict = {
    'total_page_files': len(PAGES),
    'page_files': [str(p.relative_to(ROOT)) for p in PAGES],
}

markers = ['TODO', 'FIXME', '即将上线', 'Placeholder', 'placeholder', 'mock']
marker_hits = []
for page in PAGES:
    lines = page.read_text().splitlines()
    for i, line in enumerate(lines, 1):
        for marker in markers:
            if marker in line:
                marker_hits.append({
                    'file': str(page.relative_to(ROOT)),
                    'line': i,
                    'marker': marker,
                    'text': line.strip()[:200],
                })
result['marker_hits'] = marker_hits

submit_audit = []
for page in PAGES:
    text = page.read_text()
    has_submit_or_save = bool(
        re.search(r'async\s+submit\s*\(', text)
        or re.search(r'\bsubmit\s*\(\)\s*:\s*void', text)
        or re.search(r'async\s+save\s*\(', text)
        or re.search(r'\bsave\s*\(\)\s*:\s*Promise', text)
    )
    if has_submit_or_save:
        has_state = ('isSubmitting' in text) or ('isSaving' in text)
        has_guard = ('if (this.isSubmitting)' in text) or ('if (this.isSaving)' in text)
        submit_audit.append({
            'file': str(page.relative_to(ROOT)),
            'has_state': has_state,
            'has_guard': has_guard,
        })
result['submit_audit'] = submit_audit

async_without_try = []
async_sig = re.compile(r'async\s+([A-Za-z_][A-Za-z0-9_]*)\s*\([^\)]*\)\s*:\s*[^\{]+\{')
for page in PAGES:
    text = page.read_text()
    for m in async_sig.finditer(text):
        name = m.group(1)
        line = text[:m.start()].count('\n') + 1
        open_idx = text.find('{', m.end() - 1)
        if open_idx < 0:
            continue
        balance = 0
        close_idx = open_idx
        for idx in range(open_idx, len(text)):
            ch = text[idx]
            if ch == '{':
                balance += 1
            elif ch == '}':
                balance -= 1
                if balance == 0:
                    close_idx = idx
                    break
        body = text[open_idx + 1:close_idx]
        if 'await ' in body and 'try {' not in body and 'try{' not in body:
            async_without_try.append({
                'file': str(page.relative_to(ROOT)),
                'method': name,
                'line': line,
            })
result['async_without_try'] = async_without_try

onclick_potential_async = []
onclick_pat = re.compile(r'\.onClick\(\(\)\s*=>\s*\{([^}]*)\}\)', re.S)
for page in PAGES:
    text = page.read_text()
    for m in onclick_pat.finditer(text):
        block = m.group(1)
        if 'await ' in block:
            continue
        if any(k in block for k in ['submit(', 'load', 'toggle', 'save(', 'copy', 'generate']):
            if re.search(r'\b[A-Za-z_][A-Za-z0-9_]*\([^\)]*\);', block):
                line = text[:m.start()].count('\n') + 1
                onclick_potential_async.append({
                    'file': str(page.relative_to(ROOT)),
                    'line': line,
                    'snippet': ' '.join(block.strip().split())[:200],
                })
result['onclick_potential_async'] = onclick_potential_async

raw_path = Path('/Users/walden/Workspaces/WaldenProjects/go-nomads-project/go-nomads-app-harmony/AUDIT_RAW_2026-02-20.json')
raw_path.write_text(json.dumps(result, ensure_ascii=False, indent=2))

summary = {
    'total_page_files': result['total_page_files'],
    'marker_hits': len(result['marker_hits']),
    'submit_functions': len(result['submit_audit']),
    'submit_missing_guard': len([x for x in result['submit_audit'] if not (x['has_state'] and x['has_guard'])]),
    'async_without_try': len(result['async_without_try']),
    'onclick_potential_async': len(result['onclick_potential_async']),
    'raw_report': str(raw_path),
}

summary_path = Path('/Users/walden/Workspaces/WaldenProjects/go-nomads-project/go-nomads-app-harmony/AUDIT_SUMMARY_2026-02-20.json')
summary_path.write_text(json.dumps(summary, ensure_ascii=False, indent=2))

print('RAW', raw_path)
print('SUMMARY', summary_path)
print(json.dumps(summary, ensure_ascii=False))
