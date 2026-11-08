#!/usr/bin/env python3
"""Regression guard for Steamodded's love.resize stencil-canvas initialization."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def require_before(text, first, second, label):
    a = text.find(first)
    b = text.find(second)
    if a < 0 or b < 0 or a >= b:
        raise SystemExit(f"FAIL: {label}: required initialization is missing or occurs too late")


mobile = (ROOT / "patches/portrait-mobile/main.lua.patch").read_text(encoding="utf-8")
require_before(
    mobile,
    "+\t\tG.WINDOWTRANS.real_window_w = w",
    "+\tif not G.ROOM then G.PORTRAIT_RESIZE_PENDING",
    "deferred Android resize must initialize real dimensions before returning",
)
resize_start = mobile.find("+function love.resize(w, h)")
if resize_start < 0:
    raise SystemExit("FAIL: mobile love.resize wrapper not found")
resize_body = mobile[resize_start:]
require_before(
    resize_body,
    "+\t\tG.WINDOWTRANS.real_window_w = w",
    "+\tif love.system.getOS() == 'Android' and G and G.ROOM then",
    "Steamodded wrapper must see current dimensions before Android resize deferral",
)

desktop = (ROOT / "patches/portrait/main.lua.patch").read_text(encoding="utf-8")
resize_start = desktop.find(" function love.resize(w, h)")
if resize_start < 0:
    raise SystemExit("FAIL: desktop love.resize function not found")
resize_body = desktop[resize_start:]
require_before(
    resize_body,
    "+\t\tG.WINDOWTRANS.real_window_w = w",
    "+\tif not G or not G.ROOM then",
    "desktop early return must initialize real dimensions",
)

print("PASS: real_window_w/h are initialized before Steamodded's resize wrapper allocates its stencil canvas.")
