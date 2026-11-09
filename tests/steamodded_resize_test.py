#!/usr/bin/env python3
"""Regression guard for atomic Android game/stencil canvas resizing."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def require(text, fragment, label):
    if fragment not in text:
        raise SystemExit(f"FAIL: {label}: missing {fragment!r}")


def require_before(text, first, second, label):
    a = text.find(first)
    b = text.find(second)
    if a < 0 or b < 0 or a >= b:
        raise SystemExit(f"FAIL: {label}: required ordering is missing")


mobile = (ROOT / "patches/portrait-mobile/main.lua.patch").read_text(encoding="utf-8")
resize_start = mobile.find("+function love.resize(w, h)")
if resize_start < 0:
    raise SystemExit("FAIL: mobile love.resize wrapper not found")
resize_body = mobile[resize_start:]

require_before(
    resize_body,
    "+\tif G then G.CANV_SCALE = G.CANV_SCALE or 1 end",
    "+\tif love.system.getOS() == 'Android' and G and G.ROOM then",
    "CANV_SCALE must be initialized before Android resize deferral",
)
require_before(
    resize_body,
    "+\tif love.system.getOS() == 'Android' and G and G.ROOM then",
    "+\tif G and G.WINDOWTRANS then",
    "Android resize must defer publishing new dimensions until the stable resize",
)
require(
    mobile,
    "+local function portrait_sync_smods_stencil_canvas()",
    "stencil synchronization helper must exist",
)
require(
    mobile,
    "G.CANVAS:getWidth(), G.CANVAS:getHeight(),",
    "stencil canvas must use the exact game canvas pixel dimensions",
)
require(
    mobile,
    "SMODS.stencil_canvas = replacement",
    "Steamodded stencil canvas must be replaced after stable resize",
)
require(
    mobile,
    "+                portrait_sync_smods_stencil_canvas()",
    "stable deferred resize must synchronize the stencil canvas",
)
require(
    mobile,
    "+            portrait_sync_smods_stencil_canvas()",
    "first deferred canvas initialization must synchronize the stencil canvas",
)

desktop = (ROOT / "patches/portrait/main.lua.patch").read_text(encoding="utf-8")
resize_start = desktop.find(" function love.resize(w, h)")
if resize_start < 0:
    raise SystemExit("FAIL: desktop love.resize function not found")
resize_body = desktop[resize_start:]
require_before(
    resize_body,
    "+\tif G then G.CANV_SCALE = G.CANV_SCALE or 1 end",
    "+\tif G and G.WINDOWTRANS then",
    "desktop resize must initialize CANV_SCALE before returning to Steamodded",
)

print("PASS: Android resize keeps Steamodded's stencil canvas matched to G.CANVAS.")
