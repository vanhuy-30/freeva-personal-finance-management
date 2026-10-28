"""Renders canvas boards (docs/brand/canvas/*.dc.html) to PNG with headless Chrome.

Usage: python3 render.py docs/brand/canvas <out_dir> [Board ...]
Writes <out_dir>/design/<Board>.png (390 wide, no status bar).
"""
import json, re, subprocess, sys, os
src, out = sys.argv[1], sys.argv[2]
canvas = json.load(open(os.path.join(src, 'canvas.json')))
chrome = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
names = sys.argv[3:]
os.makedirs(os.path.join(out, 'html'), exist_ok=True)
os.makedirs(os.path.join(out, 'design'), exist_ok=True)
for name, b in canvas['boards'].items():
    if names and name.split('.')[0] not in names: continue
    if not names and (b.get('page') != 'p' or b['y'] < 2200): continue
    html = open(os.path.join(src, name)).read()
    html = html.replace('<script src="./support.js"></script>', '')
    html = re.sub(r'<script type="text/x-dc".*?</script>', '', html, flags=re.S)
    for t in ['x-dc', 'helmet']:
        html = re.sub(r'</?%s>' % t, '', html)
    p = os.path.join(out, 'html', name.replace('.dc.html', '.html'))
    open(p, 'w').write(html)
    png = os.path.join(out, 'design', name.replace('.dc.html', '.png'))
    subprocess.run([chrome, '--headless=new', '--hide-scrollbars', '--force-device-scale-factor=1',
        f'--window-size={b["w"]},{b["h"]}', '--virtual-time-budget=4000',
        f'--screenshot={png}', 'file://' + p], capture_output=True)
    print(name, b['w'], b['h'], b.get('title'))
