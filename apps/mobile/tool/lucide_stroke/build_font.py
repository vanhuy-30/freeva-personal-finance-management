"""Builds the Lucide icon font at the design's stroke weight.

The canvas draws Lucide icons at stroke 1.75 (24 px grid); the package fonts
only ship 1.55 and 2.0. This script strokes the original Lucide SVGs with
Skia and writes a TrueType font with the package's codepoints, so
`FreevaIcons` can mirror `LucideIcons` one to one.

Usage (offline tool, not part of the app build):
  python3 -m venv .venv && .venv/bin/pip install fonttools skia-python
  npm pack lucide-static@<version> && tar xzf lucide-static-<version>.tgz
  .venv/bin/python build_font.py package/icons <codepoints.json> \
      ../../assets/fonts/Lucide175.ttf 1.75
The version must match the bundled `lucide_icons_flutter` (see its CHANGELOG).
"""

import json
import os
import re
import sys
import xml.etree.ElementTree as ET

import skia
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.cu2quPen import Cu2QuPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen

UPM = 1000
FALLBACKS = []
NUM = re.compile(r"[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")
CMD = re.compile(r"[MmLlHhVvCcSsQqTtAaZz]|[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")


def _arc_flags(tokens, i):
    # Arc flags may be written without separators ("a1 1 0 011 1").
    out = []
    while len(out) < 2:
        t = tokens[i]
        if t in ("0", "1"):
            out.append(t == "1")
            i += 1
        elif re.fullmatch(r"[01][01]?\d*\.?\d*", t):
            out.append(t[0] == "1")
            tokens[i] = t[1:]
            if tokens[i] == "":
                i += 1
        else:
            raise ValueError(f"bad arc flag {t!r}")
    return out, i


def parse_path(d):
    tokens = CMD.findall(d)
    p = skia.Path()
    i, cmd = 0, None
    cx = cy = sx = sy = 0.0
    last_ctrl = None
    last_cmd = None

    def num():
        nonlocal i
        v = float(tokens[i])
        i += 1
        return v

    while i < len(tokens):
        if re.fullmatch(r"[A-Za-z]", tokens[i]):
            cmd = tokens[i]
            i += 1
        rel = cmd.islower()
        c = cmd.upper()
        ox, oy = (cx, cy) if rel else (0.0, 0.0)
        if c == "Z":
            p.close()
            cx, cy = sx, sy
            last_ctrl, last_cmd = None, c
            continue
        if c == "M":
            cx, cy = ox + num(), oy + num()
            p.moveTo(cx, cy)
            sx, sy = cx, cy
            cmd = "l" if rel else "L"
            last_ctrl, last_cmd = None, "M"
            continue
        if c == "L":
            cx, cy = ox + num(), oy + num()
            p.lineTo(cx, cy)
            last_ctrl = None
        elif c == "H":
            cx = ox + num()
            p.lineTo(cx, cy)
            last_ctrl = None
        elif c == "V":
            cy = oy + num()
            p.lineTo(cx, cy)
            last_ctrl = None
        elif c == "C":
            x1, y1, x2, y2 = ox + num(), oy + num(), ox + num(), oy + num()
            cx, cy = ox + num(), oy + num()
            p.cubicTo(x1, y1, x2, y2, cx, cy)
            last_ctrl = (x2, y2)
        elif c == "S":
            if last_cmd in ("C", "S") and last_ctrl:
                x1, y1 = 2 * cx - last_ctrl[0], 2 * cy - last_ctrl[1]
            else:
                x1, y1 = cx, cy
            x2, y2 = ox + num(), oy + num()
            cx, cy = ox + num(), oy + num()
            p.cubicTo(x1, y1, x2, y2, cx, cy)
            last_ctrl = (x2, y2)
        elif c == "Q":
            x1, y1 = ox + num(), oy + num()
            cx, cy = ox + num(), oy + num()
            p.quadTo(x1, y1, cx, cy)
            last_ctrl = (x1, y1)
        elif c == "T":
            if last_cmd in ("Q", "T") and last_ctrl:
                x1, y1 = 2 * cx - last_ctrl[0], 2 * cy - last_ctrl[1]
            else:
                x1, y1 = cx, cy
            cx, cy = ox + num(), oy + num()
            p.quadTo(x1, y1, cx, cy)
            last_ctrl = (x1, y1)
        elif c == "A":
            rx, ry, rot = num(), num(), num()
            (large, sweep), i = _arc_flags(tokens, i)
            cx, cy = ox + num(), oy + num()
            p.arcTo(
                rx, ry, rot,
                skia.Path.kLarge_ArcSize if large else skia.Path.kSmall_ArcSize,
                skia.PathDirection.kCW if sweep else skia.PathDirection.kCCW,
                cx, cy,
            )
            last_ctrl = None
        last_cmd = c
    return p


def f(el, name, default=0.0):
    v = el.get(name)
    return float(v) if v is not None else default


def element_path(el):
    tag = el.tag.split("}")[-1]
    if tag == "path":
        return parse_path(el.get("d"))
    if tag == "circle":
        return skia.Path.Circle(f(el, "cx"), f(el, "cy"), f(el, "r"))
    if tag == "ellipse":
        cx, cy, rx, ry = f(el, "cx"), f(el, "cy"), f(el, "rx"), f(el, "ry")
        return skia.Path.Oval(skia.Rect.MakeLTRB(cx - rx, cy - ry, cx + rx, cy + ry))
    if tag == "rect":
        x, y, w, h = f(el, "x"), f(el, "y"), f(el, "width"), f(el, "height")
        rx = el.get("rx")
        ry = el.get("ry")
        rx = float(rx) if rx is not None else (float(ry) if ry is not None else 0.0)
        ry = float(ry) if ry is not None else rx
        p = skia.Path()
        p.addRRect(skia.RRect.MakeRectXY(skia.Rect.MakeXYWH(x, y, w, h), rx, ry))
        return p
    if tag == "line":
        p = skia.Path()
        p.moveTo(f(el, "x1"), f(el, "y1"))
        p.lineTo(f(el, "x2"), f(el, "y2"))
        return p
    if tag in ("polyline", "polygon"):
        pts = [float(n) for n in NUM.findall(el.get("points"))]
        p = skia.Path()
        p.moveTo(pts[0], pts[1])
        for k in range(2, len(pts), 2):
            p.lineTo(pts[k], pts[k + 1])
        if tag == "polygon":
            p.close()
        return p
    return None


def icon_outline(svg_file, stroke):
    root = ET.parse(svg_file).getroot()
    stroke_paint = skia.Paint(
        Style=skia.Paint.kStroke_Style,
        StrokeWidth=stroke,
        StrokeCap=skia.Paint.kRound_Cap,
        StrokeJoin=skia.Paint.kRound_Join,
        AntiAlias=True,
    )
    parts = []
    for el in root.iter():
        p = element_path(el)
        if p is None:
            continue
        fill = el.get("fill")
        if fill and fill != "none":
            parts.append(p)
        outline = skia.Path()
        # Resolution scale 50 keeps curves smooth at the 1000 upm size.
        stroke_paint.getFillPath(p, outline, None, 50.0)
        parts.append(outline)
    # Union one part at a time (OpBuilder merges touching holes into one
    # contour and leaves seams). A part whose union fails stays as an
    # overlapping contour, which still fills under the nonzero rule.
    acc = skia.Path()
    loose = []
    for part in parts:
        try:
            acc = skia.Op(acc, part, skia.kUnion_PathOp)
        except RuntimeError:
            loose.append(part)
    if loose:
        FALLBACKS.append(os.path.basename(svg_file))
    out = nonzero(acc)
    for part in loose:
        out.addPath(part)
    return out


def _contours(path):
    out, cur = [], None
    it = skia.Path.Iter(path, False)
    while True:
        verb, pts = it.next()
        if verb == skia.Path.kDone_Verb:
            break
        if verb == skia.Path.kMove_Verb:
            cur = skia.Path()
            out.append(cur)
            cur.moveTo(pts[0])
        elif verb == skia.Path.kLine_Verb:
            cur.lineTo(pts[1])
        elif verb == skia.Path.kQuad_Verb:
            cur.quadTo(pts[1], pts[2])
        elif verb == skia.Path.kConic_Verb:
            cur.conicTo(pts[1], pts[2], it.conicWeight())
        elif verb == skia.Path.kCubic_Verb:
            cur.cubicTo(pts[1], pts[2], pts[3])
        elif verb == skia.Path.kClose_Verb:
            cur.close()
    return [c for c in out if c.countVerbs() > 1]


def _area(contour):
    pts = contour.getPoints(contour.countPoints())
    return sum(
        pts[i].x() * pts[(i + 1) % len(pts)].y() - pts[(i + 1) % len(pts)].x() * pts[i].y()
        for i in range(len(pts))
    )


def nonzero(path):
    """Re-orients an even-odd union so it fills the same under nonzero:
    contours nested an even number of times run one way, holes the other.
    (skia.AsWinding gets some nested cases wrong.)"""
    out = skia.Path()
    for c in _contours(path):
        if _filled_on_left(path, c):
            out.addPath(c)
        else:
            out.reverseAddPath(c)
    return out


def _filled_on_left(path, contour):
    # Probe just beside a point on the contour; the side the union fills
    # tells which way the contour must run.
    measure = skia.PathMeasure(contour, True)
    length = measure.getLength()
    votes = 0
    for frac in (0.17, 0.5, 0.83):
        pos, tan = measure.getPosTan(length * frac)
        # Left of travel in y-down coordinates.
        nx, ny = tan.y(), -tan.x()
        eps = 0.02
        left = path.contains(pos.x() + nx * eps, pos.y() + ny * eps)
        right = path.contains(pos.x() - nx * eps, pos.y() - ny * eps)
        if left != right:
            votes += 1 if left else -1
    return votes >= 0


def draw(path, pen):
    it = skia.Path.Iter(path, False)
    open_contour = False
    while True:
        verb, pts = it.next()
        if verb == skia.Path.kDone_Verb:
            break
        if verb == skia.Path.kMove_Verb:
            if open_contour:
                pen.closePath()
            pen.moveTo((pts[0].x(), pts[0].y()))
            open_contour = True
        elif verb == skia.Path.kLine_Verb:
            pen.lineTo((pts[1].x(), pts[1].y()))
        elif verb == skia.Path.kQuad_Verb:
            pen.qCurveTo((pts[1].x(), pts[1].y()), (pts[2].x(), pts[2].y()))
        elif verb == skia.Path.kConic_Verb:
            quads = skia.Path.ConvertConicToQuads(pts[0], pts[1], pts[2], it.conicWeight(), 2)
            for k in range(1, len(quads), 2):
                pen.qCurveTo((quads[k].x(), quads[k].y()), (quads[k + 1].x(), quads[k + 1].y()))
        elif verb == skia.Path.kCubic_Verb:
            pen.curveTo(
                (pts[1].x(), pts[1].y()), (pts[2].x(), pts[2].y()), (pts[3].x(), pts[3].y())
            )
        elif verb == skia.Path.kClose_Verb:
            pen.closePath()
            open_contour = False
    if open_contour:
        pen.closePath()


def main():
    icons_dir, codepoints_file, out, stroke = sys.argv[1], sys.argv[2], sys.argv[3], float(sys.argv[4])
    codepoints = json.load(open(codepoints_file))
    glyph_order = [".notdef"]
    glyphs = {".notdef": TTGlyphPen(None).glyph()}
    cmap = {}
    missing = []
    scale = UPM / 24.0
    for name, cp in sorted(codepoints.items(), key=lambda kv: kv[1]):
        if cp in cmap:
            continue
        svg = os.path.join(icons_dir, name + ".svg")
        if not os.path.exists(svg):
            missing.append(name)
            continue
        outline = icon_outline(svg, stroke)
        tt = TTGlyphPen(None)
        # SVG y runs down; font y runs up with the icon filling 0..UPM.
        pen = TransformPen(Cu2QuPen(tt, 1.0, reverse_direction=True), (scale, 0, 0, -scale, 0, UPM))
        draw(outline, pen)
        gname = "u%04X" % cp
        glyph_order.append(gname)
        glyphs[gname] = tt.glyph()
        cmap[cp] = gname

    fb = FontBuilder(UPM, isTTF=True)
    fb.setupGlyphOrder(glyph_order)
    fb.setupCharacterMap(cmap)
    fb.setupGlyf(glyphs)
    glyf = fb.font["glyf"]
    lsb = {}
    for g in glyph_order:
        glyf[g].recalcBounds(glyf)
        lsb[g] = getattr(glyf[g], "xMin", 0)
    fb.setupHorizontalMetrics({g: (UPM, lsb[g]) for g in glyph_order})
    fb.setupHorizontalHeader(ascent=UPM, descent=0)
    family = "Lucide175"
    fb.setupNameTable({"familyName": family, "styleName": "Regular"})
    fb.setupOS2(sTypoAscender=UPM, sTypoDescender=0, usWinAscent=UPM, usWinDescent=0)
    fb.setupPost()
    fb.save(out)
    print(f"{len(cmap)} glyphs, stroke {stroke}, missing svg: {missing[:10]}{'…' if len(missing) > 10 else ''} ({len(missing)}); no union: {FALLBACKS}")


if __name__ == "__main__":
    main()
