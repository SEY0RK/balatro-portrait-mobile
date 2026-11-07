"""Static regression checks for the Fold6 cover-display transition sequence."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
layout = (ROOT / "src" / "portrait_layouts.lua").read_text(encoding="utf-8")
callbacks = (ROOT / "patches" / "portrait-mobile" / "functions" / "button_callbacks.lua.patch").read_text(encoding="utf-8")
config = (ROOT / "src" / "portrait_config.lua").read_text(encoding="utf-8")

assert "local PORTRAIT_WIPE_LEAD_SECONDS = 1.05" in layout
begin = layout.index("function portrait_begin_android_layout_transition")
restart = layout.index("local function portrait_restart_scene_under_existing_wipe")
restart_end = layout.index("--Re-enter the active run through Balatro's native load-from-save path.", restart)
begin_body = layout[begin:restart]
restart_body = layout[restart:restart_end]

# The original wipe starts before the delayed SDL window operation.
assert begin_body.index("G.FUNCS.wipe_on") < begin_body.index("delay = PORTRAIT_WIPE_LEAD_SECONDS")
assert begin_body.index("delay = PORTRAIT_WIPE_LEAD_SECONDS") < begin_body.index("portrait_request_android_orientation(mode)")
assert "metrics.wipe_lead_ms" in begin_body

# Once the new surface is stable, use the vanilla run deletion/restoration order
# but do not create a second wipe. The existing wipe is released only afterward.
assert "G.FUNCS.wipe_on" not in restart_body
assert restart_body.index("G:delete_run()") < restart_body.index("G:start_run(args)")
assert restart_body.index("G:start_run(args)") < restart_body.index("G.FUNCS.wipe_off()")
assert "from_portrait_layout = true" in restart_body

# The resize gate must not advance before the delayed orientation request.
update_start = layout.index("local pending_layout = G.PORTRAIT_LAYOUT_RELOAD_PENDING")
update_end = layout.index("-- A Fold6 cover/inner transition", update_start)
update_body = layout[update_start:update_end]
assert "pending_layout.orientation_requested" in update_body
assert "pending_layout.stable_frames >= 2" in update_body
assert "portrait_restart_scene_under_existing_wipe(pending_layout)" in update_body
assert "portrait_abort_android_layout_transition" in update_body

# The setting callback delegates cover-display changes to the transition helper.
assert "portrait_begin_android_layout_transition(snapshot, new_value, previous_value)" in callbacks
assert "Switch wipe lead ms" in config

print("Portrait transition sequencing tests passed")
