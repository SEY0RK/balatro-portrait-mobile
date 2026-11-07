"""Synthetic tests for the Fold6 SDLActivity orientation patch."""

import pathlib
import tempfile

import build


BASE = """.class public Lorg/libsdl/app/SDLActivity;
.super Landroid/app/Activity;
.source "SDLActivity.java"

.field private mSingleton:Lorg/libsdl/app/SDLActivity;

.method public setOrientationBis(IIZLjava/lang/String;)V
    .locals 0
    return-void
.end method
.end class
"""


def patch(source):
    with tempfile.TemporaryDirectory() as tmp:
        root = pathlib.Path(tmp)
        smali = root / "smali" / "org" / "libsdl" / "app" / "SDLActivity.smali"
        smali.parent.mkdir(parents=True)
        smali.write_text(source, encoding="utf-8")
        build._patch_sdl_portrait_orientation(tmp)
        first = smali.read_text(encoding="utf-8")
        build._patch_sdl_portrait_orientation(tmp)
        second = smali.read_text(encoding="utf-8")
        assert first == second, "orientation patch must be idempotent"
        return first


def main():
    result = patch(BASE)
    assert result.index('.source "SDLActivity.java"') < result.index(
        ".field private mBalatroCoverOrientation:I"
    ), "injected field must follow the class metadata"
    assert result.index(".field private mBalatroCoverOrientation:I") < result.index(
        ".field private mSingleton:"
    ), "injected field must precede existing fields"
    assert ".method public setOrientationBis(IIZLjava/lang/String;)V\n    .locals 2" in result
    assert "const/4 v1, 0x6" in result
    assert "const/4 v1, 0x7" in result
    assert "if-le p1, p2, :balatro_fold_cover_portrait" in result
    assert "smallestScreenWidthDp:I" in result
    assert ".method private balatroApplyFoldOrientation()V" in result
    assert ".method public onConfigurationChanged(Landroid/content/res/Configuration;)V" in result
    assert result.count("balatroApplyFoldOrientation()V") == 2

    existing_callback = BASE.replace(
        ".end class",
        """.method protected onConfigurationChanged(Landroid/content/res/Configuration;)V
    .locals 0
    invoke-super {p0, p1}, Landroid/app/Activity;->onConfigurationChanged(Landroid/content/res/Configuration;)V
    return-void
.end method
.end class""",
    )
    existing_result = patch(existing_callback)
    assert existing_result.count("onConfigurationChanged(Landroid/content/res/Configuration;)V") == 1
    assert existing_result.count("invoke-direct {p0}, Lorg/libsdl/app/SDLActivity;->balatroApplyFoldOrientation()V") == 1

    print("Fold6 orientation smali patch tests passed")


if __name__ == "__main__":
    main()
