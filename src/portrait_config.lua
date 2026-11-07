PORTRAIT_CONFIG = {
    -- Single source of truth for the mod version: build.py parses it from
    -- here, and the Zygisk packaging refuses to ship a module.prop that
    -- disagrees with it. Bump this, module.prop and the CHANGELOG together.
    version = "1.0.1",
    scale_factor = 0.63,
    hud_top_space = 13,
    bottom_margin = 0.35,
    splash_scale_mult = 10 / 13,
    card_scale = 0.8,
    button = {
        width = 4,
        height = 2,
        text_scale = 0.8,
        width_landscape = 3.2,
        height_landscape = 1.3,
        text_scale_landscape = 0.45,
    },
    blind = {
        scale = 0.34,
        dim = 1.0,
        scale_landscape = 0.4,
        dim_landscape = 1.5,
    },
    row_sizes = {3, 4, 4},
    row_sizes_landscape = {5, 6},
    tab_breakpoints = {
        rows_5_6 = 3,
        rows_7_plus = 4,
    },
    challenge_page_size = 5,
    challenge_page_size_landscape = 10,
    jokers_y = 11,
    anti_jitter_threshold = 3.5,
    fps_cap = 'auto', -- 'auto' = match display refresh rate (90/120 Hz), or a number like 60
    disable_touch_tilt = true, -- kill the cursor-lean tilt on touch (root fix for sheared-card warp)
    score_text_mult = 1.3, -- portrait multiplier for floating score/attention popups
    deck_position = 'shelf', -- 'shelf' (top row, default) or 'bottom_right' (experimental)
    gestures = {
        enabled = true,
        min_swipe = 1.4, -- min vertical travel in game units to count as a flick
        max_dx_ratio = 0.6, -- horizontal drift allowed relative to vertical travel
        max_time = 0.45, -- max press-to-release seconds for a flick
        group_follow = true, -- selected cards visually follow a vertical drag together
    },
    swipe_only = {
        -- Global scale boost is disabled (1.0): changing TILESCALE mid-session
        -- desynced every position computed before the change (shop layouts,
        -- the boot splash, card area widths). The mode's value is the removed
        -- buttons and the lower hand. Set below 1.0 at your own risk.
        scale_mult = 1.0,
        hand_base_offset = 2.3, -- bottom space when only the sort row remains
        hand_card_scale = 1.15, -- the hand's cards take the room the buttons left
    },
    -- Per layout style (see portrait_layout()); Classic uses the values above.
    -- hand_base_offset: room under the hand for that style's button bar;
    -- swipe_hand_base_offset: the same in Swipe Only mode, with its thin row.
    layouts = {
        one_thumb = { hand_base_offset = 3.1, swipe_hand_base_offset = 1.6 },
        focus = { hand_base_offset = 2.3, swipe_hand_base_offset = 1.6 },
    },
    hand_preview = {
        enabled = true,
        scale = 0.55,
        y_offset = -1.15, -- distance above the hand area
    },
    joker_slots = {
        enabled = true,
        alpha = 0.16, -- outline opacity for empty joker/consumable slots
        slot_scale = 0.94, -- slot size vs card size; shared by the outline AND the
                           -- card placement so held cards center exactly on slots
    },
    -- Top inset kept clear of the notch / Dynamic Island / display cutout, in
    -- room tiles. On iOS this is only a FLOOR: the real per-device safe-area
    -- inset is read at runtime (see get_mobile_safe_area_top) so a bigger island
    -- (iPhone 14 Pro / 15 / 16) gets pushed down enough. Android keeps this exact
    -- tuned value to avoid regressing the many devices already dialed in.
    safe_area_y = 0.85,
    -- Extra breathing gap (room tiles) added under the *measured* iOS inset only.
    -- Bump this a touch if the score still hugs the island on some device.
    safe_area_extra_ios = 0.0,
    -- Extra bottom gap (room tiles) kept above the home indicator, iOS only.
    -- Bump this if the menu / corner buttons still crowd the swipe bar.
    safe_area_bottom_extra_ios = 0.0,
    -- The same breathing room at the bottom of the title screen on Android, in
    -- room tiles. It cannot be measured there the way it is on iOS: LOVE reads
    -- the Android safe area from the display cutout, which covers the notch and
    -- says nothing about the gesture bar, and the game runs immersive so the
    -- bar is hidden anyway. Without it the menu panel sits flush against the
    -- bottom edge of the screen. Measured against this phone's gesture inset
    -- (64px at density 640, so 16dp, about half a tile) with a little over it.
    menu_bottom_gap_android = 1.15,
    tooltip_screen_padding = 0.12,
    -- Gap in room tiles between a card and its tooltip on touch. Large enough
    -- that a thumb on the card does not cover the text; raise it if a bigger
    -- hand still reaches the popup.
    tooltip_card_gap = 0.9,
    tooltip_touch_gap = 1.6,
    -- How far a selected booster-pack card lifts (fraction of card height) so its
    -- USE button has clear room to appear beneath it instead of overlapping art.
    pack_highlight_lift = 0.4,
    -- How far the hand row sits above its anchor during a booster (card heights).
    -- Raised above the 1.8 desktop default so a lifted pack card clears the hand.
    pack_hand_lift = 2.2,
    -- How far a focused shop card lifts (fraction of card height) so its Buy/Open
    -- button is revealed above the shop panel instead of tucking under it.
    shop_highlight_lift = 0.45,
    main_menu = {
        row_width = 5.55, -- Play button width; the other rows match it
        row_gap = 0.34,   -- space between the middle buttons
        row_height = 1.25,
        x_offset_base = 0.1,
        x_offset_plus = 0.2,
        y_offset_base = -1.55,
        corner_y_offset = -2.15,
        -- Extra lift (room tiles) for the two bottom corner buttons on iOS.
        -- Rounded display corners are not part of the safe area iOS reports,
        -- so a box that clears the home indicator can still reach the curve:
        -- measured off the #45 screenshot, the profile box sat 4.5pt from the
        -- left edge with the corner arc cutting 2.5pt in at that height, about
        -- 2pt of daylight. Lifting the pair clear of the arc costs nothing
        -- else. Android has no such report and keeps 0.
        corner_lift_ios = 0.4,
        -- Horizontal half of the same nudge, in room tiles. Lifting alone tops
        -- out at the 4pt the box already keeps from the side edge, so the pair
        -- also steps inward, away from the arc. There is ~23 tiles-worth of
        -- daylight to the menu column at this width, so this stays clear of it.
        corner_inset_ios = 0.25,
        -- Smallest gap (room tiles) a corner box keeps from the menu column.
        -- The inset above is cut back, down to zero, to keep this (#48).
        corner_clearance = 0.15,
        -- The menu column ends this far above the bottom of the screen, in room
        -- tiles, measured at 390x844. The lift below is the device's own bottom
        -- inset minus this, so the panel finishes level with the safe area and
        -- the home indicator gets the strip to itself instead of sitting on the
        -- panel (#45).
        menu_gap_tiles = 0.26,
    },
    -- Steamodded's newer New Run screen does not fit a phone, so portrait turns
    -- its "vanilla run select" option on the first time it sees the setting.
    -- Set this to false to leave the option alone entirely.
    smods_vanilla_run_select = true,
    -- Height of one mod row in the Steamodded list, measured on the rig at
    -- 390x844. Room tiles, so it holds at any resolution, and a box is one line
    -- tall whatever the mod is called.
    mod_list_row_h = 1.6,
    -- Mods shown per page on a phone. Has to divide the number Steamodded pages
    -- by (below) so a page of ours never straddles two of theirs. Six keeps the
    -- window short enough that its back bar stays well clear of the home
    -- indicator; the rest of the mods are one page turn away.
    mod_list_page_size = 6,
    -- Mods per page upstream. Steamodded's own number, used to find which of
    -- its pages one of ours sits in.
    mod_list_per_page = 12,
    -- Room tiles taken off the mod window so its frame is visible rather than
    -- flush with the screen edges. Measured on the rig at 390x844: the window
    -- adds 1.14 tiles of padding and emboss around whatever its content asks
    -- for, so this is that plus roughly half a tile of daylight each side.
    mod_list_margin = 2.1,
    view_deck_scale = 0.8,
    game_over_scale = 1.2,
    game_over_scale_landscape = 1.5,
    tag_align = {
        first_x_left = -0.2,
        first_x_right = 0.2,
        width = 0.9, -- measured tag UIBox width in room tiles
        screen_margin = 0.1,
    },
    usable_w_factor = 0.96,
    hand_screen_padding = 0.28,
    hand_base_offset = 3.1,
    discard_x_offset = 0.3,
    mobile_ui = {
        hud_scale_tall = 0.39,
        hud_scale_normal = 0.42,
        hud_scale_short = 0.46,
        hud_panel_minw = 8.4,
        hud_top_right_minw = 4.22,
        hud_score_minw = 4.1,
        hud_chip_box_minw = 2.95,
        hud_chip_label_minw = 1.18,
        hud_current_hand_minw = 4.1,
        hud_hand_meter_minw = 1.88,
        hud_money_minw = 3.05,
        hud_spacing = 0.07,
        hud_stat_pad = 0.035,
        hud_stat_minw = 1.16,
        hud_stat_label_scale = 0.68,
        hud_stat_count_scale = 1.72,
        hud_stats_gap = 0.1,
        hud_blind_minw = 3.62,
        hud_blind_minh = 3.12,
        hud_blind_body_minh = 1.92,
        hud_blind_dim = 0.82,
        hud_blind_name_h = 0.46,
        hud_blind_name_minw = 2.38,
        hud_blind_name_scale = 1.42,
        hud_blind_body_pad = 0.018,
        hud_blind_body_maxw = 3.12,
        hud_blind_lower_pad = 0.02,
        hud_blind_score_minw = 2.15,
        hud_blind_score_maxw = 2.05,
        hud_blind_score_label_scale = 0.29,
        hud_blind_reward_scale = 0.29,
        hud_blind_dollar_scale = 0.4,
        hud_blind_line_h = 0.24,
        hud_blind_debuff_scale = 0.88,
        hud_blind_chip_row_h = 0.48,
        hud_blind_reward_h = 0.34,
        hud_button_minw = 1.95,
        hud_button_minh = 0.78,
        card_button_mult = 1.4, -- portrait size multiplier for Use/Sell buttons on cards
        run_setup_back_desc_scale = 0.72,
        run_setup_back_min_dims = 0.76,
        run_setup_back_desc_h = 1.9,
        blind_choice = {
            prompt_pad = 0.05,
            prompt_scale_1 = 0.72,
            prompt_scale_2 = 0.8,
            choice_pad = 0.02,
            wrapper_pad = 0.012,
            wrapper_inner_pad = 0.018,
            panel_pad = 0.018,
            inner_pad = 0.026,
            button_pad = 0.018,
            button_scale = 0.62,
            name_scale = 0.62,
            desc_scale = 0.46,
            score_label_scale = 0.42,
            reward_scale = 0.46,
            chip_size = 1.6,
            score_minw = 2.95,
            text_maxw = 2.75,
            tag_pad = 0.012,
            tag_button_pad = 0.018,
            tag_skip_scale = 0.6,
            tag_reward_scale = 0.5,
        },
        collection_blinds = {
            chip_size = 1.15,
            cell_pad = 0.06,
            ante_minw = 0.55,
            base_minw = 2.5,
            text_scale = 0.36,
            box_pad = 0.05,
        },
        shop_sign = {
            w = 2.85,
            h = 1.43,
            panel_w = 3.18,
            panel_h = 1.95,
            text_scale = 0.34,
        },
    },
}

function get_portrait_scale(w, h)
    local aspect = h / w
    local s
    if aspect > 2.2 then
        s = 0.58
    elseif aspect > 1.8 then
        s = 0.63
    elseif aspect > 1.5 then
        s = 0.70
    else
        s = 0.80
    end
    -- Swipe Only mode: no Play/Discard buttons, so scale the whole UI up to
    -- fill the freed space (smaller divisor = bigger UI). Reads the session-
    -- latched flag, never the live setting, so layout stays consistent.
    if G and G.F_SWIPE_ONLY and PORTRAIT_CONFIG.swipe_only then
        s = s * (PORTRAIT_CONFIG.swipe_only.scale_mult or 0.92)
    end
    return s
end

-- Top inset (in room tiles) that keeps the HUD clear of a notch / Dynamic Island
-- / display cutout. Off-mobile it is 0. On Android it returns the tuned static
-- value unchanged. On iOS it converts the device's *real* top safe-area inset
-- (love.window.getSafeArea, in DPI-scaled pixels) into room tiles and uses that,
-- so an iPhone with a tall Dynamic Island gets pushed down enough instead of
-- relying on one hard-coded guess. The static value stays as a floor, and every
-- lookup is guarded so a missing API or a zero inset just falls back to it.
-- Must be called after G.TILESCALE is set for the current frame.
function get_mobile_safe_area_top(os_name)
    os_name = os_name or (love.system and love.system.getOS and love.system.getOS())
    if os_name ~= 'Android' and os_name ~= 'iOS' then return 0 end

    local fallback = (PORTRAIT_CONFIG and PORTRAIT_CONFIG.safe_area_y) or 0.85
    if os_name ~= 'iOS' then return fallback end

    if not (love.window and love.window.getSafeArea
            and G and G.TILESCALE and G.TILESIZE
            and G.TILESCALE > 0 and G.TILESIZE > 0) then
        return fallback
    end

    local ok, _sx, sy = pcall(love.window.getSafeArea)
    if not ok or type(sy) ~= 'number' or sy <= 0 then
        return fallback
    end

    -- px -> room tiles, the same conversion used for room width/height.
    local inset_tiles = sy / (G.TILESCALE * G.TILESIZE)
    inset_tiles = inset_tiles + ((PORTRAIT_CONFIG and PORTRAIT_CONFIG.safe_area_extra_ios) or 0)
    return math.max(inset_tiles, fallback)
end

-- Tiles to trim off the room HEIGHT so bottom-anchored UI stays on screen.
-- The room is shifted down by the top inset but has always kept its full
-- window height, so it overshoots the physical bottom by that same inset.
-- Every bottom offset (main-menu buttons, corner buttons, the hand) was tuned
-- on Android with the static 0.85-tile overshoot baked in, so Android trims
-- nothing and keeps its dialed-in look. On iOS the measured island inset is
-- ~2 tiles and the home indicator adds a bottom inset on top of that, which
-- is what clipped the title-screen buttons (#35): trim the overshoot beyond
-- the tuned floor plus the real bottom inset, so the Android-tuned bottom
-- spacing is reproduced relative to the iOS safe-area bottom edge instead of
-- a point below the screen. Falls back to 0 (old behaviour) whenever the
-- safe-area API is unavailable. Must be called after G.TILESCALE is set.
function get_mobile_room_bottom_trim(os_name, safe_top)
    os_name = os_name or (love.system and love.system.getOS and love.system.getOS())
    if os_name ~= 'iOS' then return 0 end

    local floor_inset = (PORTRAIT_CONFIG and PORTRAIT_CONFIG.safe_area_y) or 0.85
    local trim = math.max((safe_top or 0) - floor_inset, 0)

    if not (love.window and love.window.getSafeArea
            and love.graphics and love.graphics.getHeight
            and G and G.TILESCALE and G.TILESIZE
            and G.TILESCALE > 0 and G.TILESIZE > 0) then
        return trim
    end

    local ok, _sx, sy, _sw, sh = pcall(love.window.getSafeArea)
    if not ok or type(sy) ~= 'number' or type(sh) ~= 'number' then
        return trim
    end

    local bottom_px = love.graphics.getHeight() - (sy + sh)
    if bottom_px > 0 then
        trim = trim + bottom_px / (G.TILESCALE * G.TILESIZE)
    end
    trim = trim + ((PORTRAIT_CONFIG and PORTRAIT_CONFIG.safe_area_bottom_extra_ios) or 0)
    return math.max(trim, 0)
end

-- How far to nudge the main-menu corner buttons (profile on the left, language
-- on the right) away from the corner, in room tiles: up first, then inward.
-- iOS reports the home indicator in its safe area but not the rounded display
-- corners, so those two boxes can clear the swipe bar and still graze the curve
-- (#45). Returns lift, inset. Applied on iOS only, and only on a device that
-- reports a bottom inset, which is the same set of devices that has the
-- rounded corners. Everything else, every Android phone included, gets 0, 0.
function get_portrait_corner_nudge(os_name)
    os_name = os_name or (love.system and love.system.getOS and love.system.getOS())
    if os_name ~= 'iOS' and os_name ~= 'Android' then return 0, 0 end

    local menu = PORTRAIT_CONFIG and PORTRAIT_CONFIG.main_menu
    local lift = (menu and menu.corner_lift_ios) or 0
    local inset = (menu and menu.corner_inset_ios) or 0
    if lift <= 0 and inset <= 0 then return 0, 0 end

    -- Android phones have the same rounded display corners but report nothing
    -- about them, so they get the same nudge on the same flat terms.
    if os_name == 'Android' then return lift, inset end

    if not (love.window and love.window.getSafeArea
            and love.graphics and love.graphics.getHeight) then
        return 0, 0
    end

    local ok, _sx, sy, _sw, sh = pcall(love.window.getSafeArea)
    if not ok or type(sy) ~= 'number' or type(sh) ~= 'number' then return 0, 0 end
    if love.graphics.getHeight() - (sy + sh) <= 0 then return 0, 0 end

    return lift, inset
end

-- Lift for the main menu column in room tiles, so its bottom edge finishes at
-- the safe-area bottom rather than under the home indicator. Derived from the
-- inset the device reports, so a phone with a taller bar lifts further and a
-- device with no bar lifts not at all. iOS only, like the corner nudge.
function get_portrait_menu_lift(os_name)
    os_name = os_name or (love.system and love.system.getOS and love.system.getOS())
    if os_name == 'Android' then
        return math.max(0, (PORTRAIT_CONFIG and PORTRAIT_CONFIG.menu_bottom_gap_android) or 0)
    end
    if os_name ~= 'iOS' then return 0 end

    if not (love.window and love.window.getSafeArea
            and love.graphics and love.graphics.getHeight
            and G and G.TILESCALE and G.TILESIZE
            and G.TILESCALE > 0 and G.TILESIZE > 0) then
        return 0
    end

    local ok, _sx, sy, _sw, sh = pcall(love.window.getSafeArea)
    if not ok or type(sy) ~= 'number' or type(sh) ~= 'number' then return 0 end

    local bottom_px = love.graphics.getHeight() - (sy + sh)
    if bottom_px <= 0 then return 0 end

    local menu = PORTRAIT_CONFIG and PORTRAIT_CONFIG.main_menu
    local gap = (menu and menu.menu_gap_tiles) or 0
    return math.max(0, bottom_px / (G.TILESCALE * G.TILESIZE) - gap)
end

-- Plain-text device/layout report shown in Options -> Diagnostics and copied
-- to the clipboard from there. This exists because the project is developed
-- without an iOS device: a pasted report turns "the buttons look off" into
-- exact inset and tile numbers. Every probe is guarded so a partial LOVE API
-- (or being called before boot finishes) degrades to "?" instead of erroring.
function portrait_diagnostics_report()
    local lines = {}
    local function add(label, value)
        lines[#lines + 1] = label .. ": " .. tostring(value == nil and "?" or value)
    end
    local function fmt(n) return type(n) == "number" and string.format("%.2f", n) or "?" end

    add("Portrait mod", PORTRAIT_CONFIG and PORTRAIT_CONFIG.version)
    add("Game version", G and G.VERSION)
    local os_name = love.system and love.system.getOS and love.system.getOS()
    add("OS", os_name)
    if love.getVersion then
        local maj, min, rev = love.getVersion()
        add("LOVE", maj .. "." .. min .. "." .. rev)
    end
    if love.graphics and love.graphics.getWidth then
        add("Window", love.graphics.getWidth() .. "x" .. love.graphics.getHeight())
    end
    -- Reported refresh rate and the cap the loop is actually using. The two
    -- disagreeing is the difference between "the panel is 60" and "we are
    -- capping ourselves at 60", which is not something a frame counter alone
    -- can tell apart (#45).
    local ok_mode, _mw, _mh, mode_flags = pcall(love.window.getMode)
    add("Refresh rate", ok_mode and mode_flags and mode_flags.refreshrate or "?")
    add("FPS cap", (G and G.FPS_CAP) or (PORTRAIT_CONFIG and PORTRAIT_CONFIG.fps_cap) or "?")
    if love.window and love.window.getDPIScale then
        add("DPI scale", love.window.getDPIScale())
    end
    if love.window and love.window.getSafeArea then
        local ok, sx, sy, sw, sh = pcall(love.window.getSafeArea)
        if ok and type(sy) == "number" then
            add("Safe area px", "x=" .. sx .. " y=" .. sy .. " w=" .. sw .. " h=" .. sh)
        end
    end
    if G then
        add("Tile scale", fmt(G.TILESCALE))
        if G.ROOM and G.ROOM.T then
            add("Room tiles", "w=" .. fmt(G.ROOM.T.w) .. " h=" .. fmt(G.ROOM.T.h) .. " y=" .. fmt(G.ROOM.T.y))
        end
        if G.HUD and G.HUD.T and G.ROOM and G.ROOM.T then
            add("HUD box", "x=" .. fmt(G.HUD.T.x) .. " y=" .. fmt(G.HUD.T.y) .. " w=" .. fmt(G.HUD.T.w) .. " h=" .. fmt(G.HUD.T.h))
            add("HUD center", fmt(G.HUD.T.x + G.HUD.T.w/2) .. " / room " .. fmt(G.ROOM.T.x + G.ROOM.T.w/2))
            add("HUD VT x", G.HUD.VT and fmt(G.HUD.VT.x) or "?")
            add("HUD position passes", tostring(G.HUD._portrait_position_passes or 0))
            add("HUD last target x", G.HUD._portrait_position_last_x and fmt(G.HUD._portrait_position_last_x) or "not-run")
            add("HUD role x", G.HUD.role and fmt(G.HUD.role.offset and G.HUD.role.offset.x) or "?")
            add("HUD role type", G.HUD.role and G.HUD.role.role_type or "?")
            local major = G.HUD.config and G.HUD.config.major
            add("HUD anchor", major == G.ROOM_ATTACH and "ROOM_ATTACH" or major == G.ROOM and "ROOM_NODE" or major == G.HUD and "SELF" or major and "OTHER" or "NONE")
            add("HUD role major", G.HUD.role and G.HUD.role.major and (G.HUD.role.major == G.ROOM_ATTACH and "ROOM_ATTACH" or G.HUD.role.major == G.ROOM and "ROOM_NODE" or "OTHER") or "NONE")
            if major and major.T then add("HUD major rect", "x=" .. fmt(major.T.x) .. " w=" .. fmt(major.T.w)) end
            add("HUD target x", fmt(G.ROOM.T.x + (G.ROOM.T.w - G.HUD.T.w) / 2))
            add("HUD align", G.HUD.alignment and tostring(G.HUD.alignment.type) or "?")
        end
        add("Portrait", G.F_PORTRAIT_LAYOUT and "yes" or "no")
        add("Swipe only", G.F_SWIPE_ONLY and "yes" or "no")
    end
    local top_ok, top = pcall(get_mobile_safe_area_top, os_name)
    add("Safe top (tiles)", top_ok and fmt(top) or "?")
    local trim_ok, trim = pcall(get_mobile_room_bottom_trim, os_name, top_ok and top or 0)
    add("Bottom trim (tiles)", trim_ok and fmt(trim) or "?")
    local zygisk_ok, shaders = pcall(require, "portrait_shaders")
    if zygisk_ok and type(shaders) == "table" then
        local n = 0
        if shaders.replace then for _ in pairs(shaders.replace) do n = n + 1 end end
        add("Build", "zygisk (readabletro shaders: " .. n .. ")")
    else
        add("Build", "bundled (build.py)")
    end
    local switch_metrics = PORTRAIT_SWITCH_METRICS
    if switch_metrics then
        add("Switch snapshot ms", switch_metrics.snapshot_ms and fmt(switch_metrics.snapshot_ms) or "pending")
        add("Switch settings save ms", switch_metrics.settings_save_ms and fmt(switch_metrics.settings_save_ms) or "pending")
        add("Switch orientation ms", switch_metrics.orientation_request_ms and fmt(switch_metrics.orientation_request_ms) or "pending")
        add("Switch surface wait ms", switch_metrics.surface_wait_ms and fmt(switch_metrics.surface_wait_ms) or "pending")
        add("Switch pre-transition ms", switch_metrics.pre_transition_ms and fmt(switch_metrics.pre_transition_ms) or "pending")
        add("Switch queue wait ms", switch_metrics.queue_to_start_run_ms and fmt(switch_metrics.queue_to_start_run_ms) or "pending")
        add("Switch start_run ms", switch_metrics.game_start_run_ms and fmt(switch_metrics.game_start_run_ms) or "pending")
        add("Switch total ms", switch_metrics.first_frame_total_ms and fmt(switch_metrics.first_frame_total_ms) or "pending")
        if switch_metrics.failed_stage then add("Switch failed stage", tostring(switch_metrics.failed_stage)) end
    end
    if love.timer and love.timer.getFPS then
        add("FPS", love.timer.getFPS())
    end
    return table.concat(lines, "\n")
end

-- Steamodded builds every Collection card page through one helper, sized for a
-- desktop room. On a phone the outer cards end up cut off by the screen edge
-- (#42). The helper already takes size multipliers, so portrait feeds it ones
-- derived from the live room width instead of rewriting Steamodded's layout.
-- Idempotent, a no-op without Steamodded, and it leaves pages that already fit
-- exactly as Steamodded built them.
function portrait_hook_smods_collection()
    if not (G and G.F_PORTRAIT_LAYOUT) then return end
    if not (SMODS and type(SMODS.card_collection_UIBox) == 'function') then return end
    if SMODS.portrait_collection_hooked then return end

    local smods_card_collection_UIBox = SMODS.card_collection_UIBox
    SMODS.card_collection_UIBox = function(_pool, rows, args)
        args = args or {}
        local widest = 0
        for _, count in ipairs(rows or {}) do
            if type(count) == 'number' and count > widest then widest = count end
        end
        local card_w = G.CARD_W or 0
        local room_w = (G.ROOM and G.ROOM.T and G.ROOM.T.w) or 0

        if G.F_PORTRAIT_LAYOUT and widest > 0 and card_w > 0 and room_w > 0 then
            -- Steamodded sizes each row as (w_mod*columns + 0.25) cards wide, so
            -- solve that for the width the room can actually show. Pages that
            -- already fit are left alone; the ones that do not (more columns than
            -- the mod's own five, or a page asking for oversized cards like the
            -- booster packs) are scaled down by the ratio they overshoot by, which
            -- keeps the page's own proportions intact.
            local usable = room_w - 1.5
            local max_w_mod = ((usable/card_w) - 0.25)/widest
            local base_w_mod = args.w_mod or 1
            if max_w_mod > 0 and base_w_mod > max_w_mod then
                local shrink = max_w_mod/base_w_mod
                args.w_mod = base_w_mod*shrink
                -- The cards have to come down with the row or they overlap in it.
                args.card_scale = (args.card_scale or 1)*shrink
                args.h_mod = (args.h_mod or 1)*shrink
            end
        end
        return smods_card_collection_UIBox(_pool, rows, args)
    end
    SMODS.portrait_collection_hooked = true

    -- The grouped consumables page asks for 11.5 tiles of width, more than a
    -- 360 dp room once its frame is added: clamped to what the room shows.
    if type(create_UIBox_your_collection_consumables) == 'function' then
        local smods_consumables = create_UIBox_your_collection_consumables
        create_UIBox_your_collection_consumables = function(...)
            local t = smods_consumables(...)
            local max_w = ((G.ROOM and G.ROOM.T and G.ROOM.T.w) or 11.6) - 1.5
            local function clamp(node)
                if type(node) ~= 'table' then return end
                if node.config and node.config.minw and node.config.minw > max_w then node.config.minw = max_w end
                for _, child in pairs(node.nodes or {}) do clamp(child) end
            end
            if G.F_PORTRAIT_LAYOUT then clamp(t) end
            return t
        end
    end

    -- Steamodded draws the blind collection itself: five 1.55-wide slots a row,
    -- every other row pushed 0.5 aside, beside its ante table, which came to
    -- about 12.8 tiles and ran off both edges of a phone. Where the room is
    -- narrower than that, the slots close up to 1.32 (the blind chips are 1.3),
    -- the stagger to 0.2 and the ante table's score column to 2.0: the page as
    -- Steamodded lays it out, just tighter.
    if type(create_UIBox_your_collection_blinds) == 'function' then
        local smods_blinds = create_UIBox_your_collection_blinds
        create_UIBox_your_collection_blinds = function(...)
            local t = smods_blinds(...)
            local room_w = (G.ROOM and G.ROOM.T and G.ROOM.T.w) or 0
            if G.F_PORTRAIT_LAYOUT and room_w > 0 and room_w < 13 and G.your_collection then
                for _, area in ipairs(G.your_collection) do
                    local cols = area.config and area.config.card_limit
                    if cols and area.T.w > cols * 1.32 then area.T.w = cols * 1.32 end
                end
                local function close_up(node)
                    if type(node) ~= 'table' then return end
                    if node.n == G.UIT.B and node.config and node.config.w == 0.5 and node.config.h == 0.2 then
                        node.config.w = 0.2
                    end
                    -- The ante table's score column, sized for desktop text.
                    if node.config and node.config.align == "cr" and node.config.minw == 2.8 then
                        node.config.minw = 2.0
                        node.config.maxw = 2.0 -- ante 13's 47,000,000,000 sets the width otherwise
                    end
                    for _, child in pairs(node.nodes or {}) do close_up(child) end
                end
                close_up(t)
            end
            return t
        end
    end
end

-- Steamodded appends its MODS button to the main menu panel and restyles that
-- panel on the way past, which left the button hanging beside the menu with the
-- rest of it knocked out of line (#44). Takes the finished definition, lifts the
-- button out and seats it next to Options and Quit at their size, and puts the
-- panel's own styling back. Runs only when that button is actually there, so a
-- build without Steamodded keeps the menu exactly as it was.
-- Steamodded's mod list is laid out for a desktop window: three boxes to a row,
-- a pane asking for a fixed 17 tiles of width and a list area with a fixed 5
-- tiles of height. On a phone the row ran off both edges with the last mod's
-- toggle out of reach, and the pane's frame sat off screen entirely (#45).
--
-- Three things are done to it, all measured rather than guessed, because a mod
-- box is as wide as its name, author and version make it:
--   * every box gets its own row, which is the narrowest the list can be laid
--     out and so the only arrangement that survives a long mod name,
--   * anything asking for more width than the room has is clamped to the room,
--     which brings the pane's frame back on screen,
--   * the list area is grown to whatever the rows actually measure once they
--     are built, since Steamodded attaches them as a child UIBox that does not
--     resize its host, so a page of them simply drew over the header and pager.
-- Pagination, ordering and the boxes themselves stay Steamodded's, so this
-- holds across its releases. Idempotent, and a no-op without it or in landscape.
-- Steamodded's mod list is laid out for a desktop window: twelve mods a page,
-- three to a row, a pane asking for a fixed 17 tiles of width and a list area
-- with a fixed 5 tiles of height. On a phone the rows ran off both edges with
-- the last mod's toggle out of reach, and the pane's frame sat off screen
-- entirely (#45).
--
-- Rather than squeeze twelve desktop-sized rows onto a phone, the page is made
-- smaller and the pager it already draws does the rest:
--   * one mod per row, which is the narrowest the list goes and so the only
--     arrangement a long mod name cannot break,
--   * a page holds mod_list_page_size of them instead of twelve, so the window
--     is a fixed, comfortable height with its back bar well clear of the home
--     indicator, whatever the mod count,
--   * the page selector is rebuilt for the new page count, so every mod is
--     still reachable, one page turn away,
--   * anything asking for more width than the room has is clamped to it, which
--     brings the pane's frame back on screen.
-- The boxes, their order and the page mechanism stay Steamodded's, so this
-- holds across its releases. Idempotent, and a no-op without it or in landscape.
function portrait_hook_smods_mod_list()
    if not (G and G.F_PORTRAIT_LAYOUT) then return end
    if not (SMODS and SMODS.GUI and type(SMODS.GUI.dynamicModListContent) == 'function') then return end
    if SMODS.portrait_mod_list_hooked then return end

    -- Our page size has to divide Steamodded's, so a page of ours never
    -- straddles two of theirs and can always be cut out of one build.
    local function page_size()
        local cfg = PORTRAIT_CONFIG or {}
        local upstream = cfg.mod_list_per_page or 12
        local size = cfg.mod_list_page_size or 6
        if size < 1 or upstream % size ~= 0 then return upstream, upstream end
        return size, upstream
    end

    local function page_count()
        local size = page_size()
        local total = #((SMODS and SMODS.mod_list) or {})
        return math.max(1, math.ceil(total/size)), size, total
    end

    local function page_label(index, count)
        return (localize and localize('k_page') or 'Page') .. ' ' .. index .. '/' .. count
    end

    -- Rebuild the page selector for our page count. Steamodded hands the cycle
    -- an option list and gets the chosen index back, so swapping the list is
    -- all it takes for the same control to page through our smaller pages.
    if type(SMODS.GUI.createOptionSelector) == 'function' then
        local smods_selector = SMODS.GUI.createOptionSelector
        SMODS.GUI.createOptionSelector = function(args)
            if G.F_PORTRAIT_LAYOUT and type(args) == 'table' and args.opt_callback == 'update_mod_list' then
                local count = page_count()
                local current = math.min(math.max(SMODS.portrait_mod_page or 1, 1), count)
                SMODS.portrait_mod_page = current
                local options = {}
                for i = 1, count do options[i] = page_label(i, count) end
                args.options = options
                args.current_option = options[current]
            end
            return smods_selector(args)
        end
    end

    if type(SMODS.GUI.staticModListContent) == 'function' then
        local smods_static = SMODS.GUI.staticModListContent
        SMODS.GUI.staticModListContent = function(...)
            local pane = smods_static(...)
            local cfg = PORTRAIT_CONFIG or {}
            local room = G.F_PORTRAIT_LAYOUT and G.ROOM and G.ROOM.T
            if not (room and room.w and room.w > 0) then return pane end

            local usable = room.w - (cfg.mod_list_margin or 2.1)
            local size = page_size()
            local list_h = size*(cfg.mod_list_row_h or 1.6)

            local seen = {}
            local function fit(node)
                if type(node) ~= 'table' or seen[node] then return end
                seen[node] = true
                local config = node.config
                if type(config) == 'table' then
                    -- The pane asks for a fixed 17 tiles, which put its frame
                    -- off both edges of a phone screen.
                    if type(config.minw) == 'number' and config.minw > usable then config.minw = usable end
                    if type(config.maxw) == 'number' and config.maxw > usable then config.maxw = usable end

                    -- Steamodded hangs the rows off this node as a child UIBox,
                    -- which does not resize its host, so the host is given the
                    -- height a full page of rows takes. Fixed, so the window is
                    -- the same size whether you have three mods or thirty.
                    local holds_list = false
                    for _, child in ipairs(node.nodes or {}) do
                        if type(child) == 'table' and child.config and child.config.id == 'modsList' then
                            holds_list = true
                        end
                    end
                    if holds_list and type(config.minh) == 'number' and list_h > config.minh then
                        config.minh = list_h
                    end
                end
                for _, child in ipairs(node.nodes or {}) do fit(child) end
            end
            fit(pane)
            return pane
        end
    end

    local smods_mod_list = SMODS.GUI.dynamicModListContent
    SMODS.GUI.dynamicModListContent = function(page)
        if not G.F_PORTRAIT_LAYOUT then return smods_mod_list(page) end

        local count, size, total = page_count()
        local index = math.min(math.max(tonumber(page) or SMODS.portrait_mod_page or 1, 1), count)
        SMODS.portrait_mod_page = index

        -- Build the Steamodded page our slice sits in, then cut the slice out.
        local _, upstream = page_size()
        local first = (index - 1)*size + 1
        local upstream_page = math.floor((first - 1)/upstream) + 1
        local pane = smods_mod_list(upstream_page)
        if not (pane and type(pane.nodes) == 'table') then return pane end

        local entries, template = {}, nil
        for _, row in ipairs(pane.nodes) do
            if type(row) ~= 'table' or type(row.nodes) ~= 'table' then return pane end
            template = template or row
            for _, entry in ipairs(row.nodes) do entries[#entries + 1] = entry end
        end
        if not template or #entries == 0 then return pane end

        local offset = first - (upstream_page - 1)*upstream
        local last = math.min(offset + size - 1, #entries, total - (upstream_page - 1)*upstream)

        local rows = {}
        for i = offset, last do
            if entries[i] then
                -- Fresh config per row: UIBox writes layout results back into
                -- it, so the split rows cannot share one table.
                local config = {}
                for k, v in pairs(template.config or {}) do config[k] = v end
                rows[#rows + 1] = {n = template.n, config = config, nodes = {entries[i]}}
            end
        end
        if #rows > 0 then pane.nodes = rows end
        return pane
    end
    SMODS.portrait_mod_list_hooked = true
end

-- Recent Steamodded replaced the New Run screen with a wide deck grid and a
-- panel beside it, laid out for a desktop window: on a phone it runs off both
-- edges and the Select button with it, so a deck cannot be picked at all (#47).
-- Steamodded keeps the old screen behind its own "vanilla run select" option,
-- and that one is the layout portrait is already built around, so on a phone it
-- is the default. Only set when the option has never been chosen, so anyone who
-- turns it off in Steamodded's own settings keeps their choice.
-- Steamodded's own run select (used whenever a mod adds a page to it, which
-- Cryptid does, whatever the vanilla toggle says) is a desktop layout: a
-- 5-wide grid of decks with the preview beside it and one long nav row, about
-- 14 tiles across. On a phone the grid gets as many columns as the room fits
-- (the page holds that many fewer, Steamodded pages the rest), the preview
-- goes under the grid, and the nav row becomes two: page buttons and Quick
-- Start, then the seed. Steamodded builds and drives the page as ever.
function portrait_hook_smods_run_select()
    if not (G and G.F_PORTRAIT_LAYOUT) then return end
    if not (SMODS and SMODS.RunSelect and SMODS.RunSelect.Functions and SMODS.RunSelect.Pages) then return end
    local F = SMODS.RunSelect.Functions
    if F.portrait_hooked or not (F.create_page and F.nav_bar) then return end
    F.portrait_hooked = true

    local function fit_grid(page_def)
        if not (page_def and page_def.grid_size) or page_def.portrait_fitted then return end
        page_def.portrait_fitted = true
        local card_w = (page_def.sprite_size and page_def.sprite_size.w) or G.CARD_W
        local cols = math.max(1, math.floor(((G.ROOM and G.ROOM.T.w or 11.6) - 1.2) / (card_w + 0.12)))
        if page_def.grid_size[2] > cols then
            page_def.grid_size = {page_def.grid_size[1], cols}
            page_def.amount = page_def.grid_size[1] * cols
        end
    end

    local create_page = F.create_page
    F.create_page = function(key, ...)
        fit_grid(SMODS.RunSelect.Pages[key])
        local t = create_page(key, ...)
        if G.F_PORTRAIT_LAYOUT and t and t.nodes and #t.nodes == 2 then
            t.config = t.config or {}
            t.config.align = 'tm'
            t.nodes = {
                {n = G.UIT.R, config = {align = 'cm'}, nodes = {t.nodes[1]}},
                {n = G.UIT.R, config = {align = 'cm'}, nodes = {t.nodes[2]}},
            }
        end
        return t
    end

    local function holds(node, test)
        if type(node) ~= 'table' then return false end
        if node.config and test(node.config) then return true end
        for _, child in pairs(node.nodes or {}) do
            if holds(child, test) then return true end
        end
        return false
    end
    local nav_bar = F.nav_bar
    F.nav_bar = function(...)
        local t = nav_bar(...)
        if not (G.F_PORTRAIT_LAYOUT and t and t.nodes) then return t end
        local pager, rest = {}, {}
        for _, child in ipairs(t.nodes) do
            local is_pager = holds(child, function(c)
                return c.id == 'previous_selection' or c.id == 'next_selection' or c.button == 'run_select_quick_start'
            end)
            table.insert(is_pager and pager or rest, child)
        end
        if #pager > 0 and #rest > 0 then
            t.nodes = {
                {n = G.UIT.R, config = {align = 'cm', padding = 0.05}, nodes = pager},
                {n = G.UIT.R, config = {align = 'cm', padding = 0.05}, nodes = rest},
            }
        end
        return t
    end
end

function portrait_default_smods_run_select()
    if not (G and G.F_PORTRAIT_LAYOUT) then return end
    if not (SMODS and type(SMODS.config) == 'table') then return end
    if PORTRAIT_CONFIG and PORTRAIT_CONFIG.smods_vanilla_run_select == false then return end
    if SMODS.config.vanilla_run_select == nil then
        SMODS.config.vanilla_run_select = true
    end
end

function portrait_adopt_mods_button(definition)
    if not (G and G.F_PORTRAIT_LAYOUT and definition and definition.nodes) then return definition end

    -- The MODS button is the way into the mod list, so hook it while we are here.
    if portrait_hook_smods_mod_list then portrait_hook_smods_mod_list() end
    if portrait_default_smods_run_select then portrait_default_smods_run_select() end
    if portrait_hook_smods_run_select then portrait_hook_smods_run_select() end

    -- UIBox_button wraps the real button one level down: the id and height live
    -- on that child, and the width lives on its label rows.
    local function button_id(node)
        local inner = node and node.nodes and node.nodes[1]
        return inner and inner.config and inner.config.id
    end
    local function size_button(node, width, height)
        local inner = node and node.nodes and node.nodes[1]
        if not inner then return end
        if height and inner.config then inner.config.minh = height end
        for _, label_row in ipairs(inner.nodes or {}) do
            if label_row.config then
                label_row.config.minw = width
                label_row.config.maxw = width - 0.2
            end
        end
    end

    local outer = definition.nodes[1]
    local panel = outer and outer.nodes and outer.nodes[1]
    if not (panel and panel.nodes) then return definition end

    local mods_index, mods_node
    for i, child in ipairs(panel.nodes) do
        if button_id(child) == 'mods_button' then mods_index, mods_node = i, child end
    end
    if not mods_node then return definition end

    table.remove(panel.nodes, mods_index)
    panel.config = {align = "cm", padding = 0.15, r = 2, emboss = 0.1, colour = G.C.L_BLACK, mid = true}

    local column = panel.nodes[1]
    local rows = column and column.nodes
    local button_row = rows and rows[2]
    if not (button_row and button_row.nodes) then
        table.insert(panel.nodes, mods_node)
        return definition
    end

    table.insert(button_row.nodes, mods_node)

    -- Line every row up on the Play button's width. Left alone, the extra button
    -- made the middle row wider than the rows above and below it and the panel
    -- grew dead corners (#44). The middle buttons share that width whatever
    -- their number: a phone build hides Quit, so it is two there and three here.
    local menu = PORTRAIT_CONFIG.main_menu or {}
    local menu_w = menu.row_width or 5.55
    local gap = menu.row_gap or 0.34
    local count = #button_row.nodes
    if count > 0 then
        local each = (menu_w - gap*(count - 1))/count
        for _, button in ipairs(button_row.nodes) do
            size_button(button, each, menu.row_height or 1.25)
        end
    end

    local collection_row = rows[3]
    size_button(collection_row and collection_row.nodes and collection_row.nodes[1], menu_w, 1.55)

    return definition
end

-- Where the first HUD tag hangs off the joker row. That row nearly fills a
-- portrait screen, so the fixed side offset put the tag a third of its width
-- past the edge (#44). This keeps the same placement but pulls it back until it
-- sits inside the room. Returns the alignment and offset for the tag UIBox.
function get_portrait_first_tag_align()
    local pc = (PORTRAIT_CONFIG and PORTRAIT_CONFIG.tag_align) or {}
    local left_side = (G.SETTINGS.play_main_hand == 1)
    local align = left_side and 'bl' or 'br'
    local offset_x = left_side and (pc.first_x_left or -0.2) or (pc.first_x_right or 0.2)

    -- Tag sprite plus the UIBox padding around it, in room tiles.
    local tag_w = pc.width or 0.9
    local margin = pc.screen_margin or 0.1

    if G.jokers and G.jokers.T and G.ROOM and G.ROOM.T and G.ROOM.T.w then
        if left_side then
            local left_edge = G.jokers.T.x - tag_w + offset_x
            if left_edge < margin then offset_x = offset_x + (margin - left_edge) end
        else
            local right_edge = G.jokers.T.x + G.jokers.T.w + offset_x + tag_w
            local limit = G.ROOM.T.w - margin
            if right_edge > limit then offset_x = offset_x - (right_edge - limit) end
        end
    end

    return align, {x = offset_x, y = 0}
end

-- Some vanilla windows are laid out for a desktop-width room and run off the
-- sides of a phone screen (#42: Credits, Language, Card Stats). Given a window's
-- natural width in room tiles, this returns the multiplier that makes it fit the
-- current room with a margin, or 1 when it already fits. Reading the live room
-- width keeps it correct on every aspect ratio instead of one tuned device.
function get_portrait_fit_scale(nominal_w, margin)
    if not (G and G.F_PORTRAIT_LAYOUT and G.ROOM and G.ROOM.T and G.ROOM.T.w) then return 1 end
    if type(nominal_w) ~= 'number' or nominal_w <= 0 then return 1 end
    local usable = G.ROOM.T.w - (margin or 1.0)
    if usable <= 0 then return 1 end
    return math.min(1, usable/nominal_w)
end

-- Flattens one blind description line into plain text.
-- Vanilla stores loc_debuff_lines as strings, but Steamodded rewrites
-- Blind:set_text so the same table holds parsed localization nodes instead.
-- The HUD renders those lines through a plain text node, which would print
-- "table: 0x..." for a node table (#42), so anything that needs a string goes
-- through here first. Mirrors the assembly the blind popup already does.
function portrait_flatten_blind_line(line, vars)
    if type(line) == 'string' then return line end
    if type(line) ~= 'table' then return '' end

    local assembled = ''
    for _, part in ipairs(line) do
        if type(part) == 'string' then
            assembled = assembled..part
        elseif type(part) == 'table' and part.strings then
            for _, subpart in ipairs(part.strings) do
                if type(subpart) == 'string' then
                    assembled = assembled..subpart
                else
                    local var_value = vars and subpart and vars[tonumber(subpart[1])]
                    assembled = assembled..tostring(var_value or '')
                end
            end
        end
    end
    return assembled
end

--Highest a run panel (blind select, round end, shop) may put its top edge:
--just under the joker shelf. The shelf sits at a fixed jokers_y while those
--panels hang a fixed distance above the hand, so on a short room (tablets,
--16:10) they met: the shelf's card area is drawn over them and took the taps
--meant for Cash Out, Next Round, Reroll and the shop's jokers. nil outside a
--portrait run.
function portrait_shelf_floor()
    if not (G and G.F_PORTRAIT_LAYOUT and G.jokers and G.jokers.T) then return nil end
    return G.jokers.T.y + G.jokers.T.h + (PORTRAIT_CONFIG.panel_shelf_gap or 0.4)
end

--Layout styles, picked in Options > Settings > Game > Layout and applied on
--the spot, mid-run too. Classic is the portrait layout as it has always been;
--One-Thumb and Focus have their own HUD, blind panel and button bar, built in
--portrait_layouts.lua (which describes them).
PORTRAIT_LAYOUTS = {'classic', 'one_thumb', 'focus'}
PORTRAIT_LAYOUT_NAMES = {'Classic', 'One-Thumb', 'Focus'}

-- The app remains physically portrait; this selects the game's internal layout.
PORTRAIT_DISPLAY_MODES = {'Portrait', 'Original Landscape'}

-- Options > Graphics. The first follows fps_cap above; a lower cap is what saves
-- battery, since every frame runs the background and CRT shaders over the screen.
PORTRAIT_FPS_NAMES = {'Screen', '60', '30'}
PORTRAIT_FPS_CAPS = {false, 60, 30}

function portrait_layout()
    if not (G and G.F_PORTRAIT_LAYOUT) then return 'classic' end
    local i = G.SETTINGS and G.SETTINGS.portrait_layout or 1
    return PORTRAIT_LAYOUTS[i] or 'classic'
end

--Bottom space reserved under the hand: smaller in Swipe Only mode, where only
--the compact sort row remains below the cards, larger for One-Thumb's two
--rows of buttons.
function get_hand_base_offset()
    local layout = PORTRAIT_CONFIG.layouts and PORTRAIT_CONFIG.layouts[portrait_layout()]
    if G and G.F_SWIPE_ONLY and PORTRAIT_CONFIG.swipe_only then
        return layout and layout.swipe_hand_base_offset or PORTRAIT_CONFIG.swipe_only.hand_base_offset or PORTRAIT_CONFIG.hand_base_offset
    end
    return layout and layout.hand_base_offset or PORTRAIT_CONFIG.hand_base_offset
end

--How much larger the hand's cards are drawn: Swipe Only gives them the room
--Play and Discard had. They ease back to size on leaving the hand.
function portrait_hand_scale()
    if G and G.F_PORTRAIT_LAYOUT and G.F_SWIPE_ONLY and PORTRAIT_CONFIG.swipe_only then
        return PORTRAIT_CONFIG.swipe_only.hand_card_scale or 1
    end
    return 1
end

function apply_portrait_tooltip_fit(config)
    if config and G and G.F_PORTRAIT_LAYOUT then
        if config.can_collide == nil then config.can_collide = false end
        if config.can_drag == nil then config.can_drag = false end
        if config.fit_to_room == nil then config.fit_to_room = true end
        if config.fit_to_room then
            config.lr_clamp = false
        elseif config.lr_clamp == nil then
            config.lr_clamp = true
        end
        -- Popups are already placed above or below their card depending on where
        -- that card sits, so pushing them clear of the finger on top of that only
        -- made them jump around as the touch moved (#44). Off unless a caller
        -- explicitly asks for it.
        if config.touch_above_cursor == nil then config.touch_above_cursor = false end
        if config.snap_to_fit == nil then config.snap_to_fit = true end
    end

    return config
end

function prepare_portrait_popup_fit(box)
    if not (G and G.F_PORTRAIT_LAYOUT and box) then return end

    if box.config then
        apply_portrait_tooltip_fit(box.config)
    end
    if box.states then
        if box.states.collide then box.states.collide.can = false end
        if box.states.drag then box.states.drag.can = false end
    end

    if box.align_to_major then box:align_to_major() end
    if box.fit_to_room then box:fit_to_room() end
    if box.hard_set_VT then box:hard_set_VT() end
    if box.UIRoot and box.UIRoot.initialize_VT then
        box.UIRoot:initialize_VT(true)
    end
end

--Menus are built for a landscape screen: the collection's five-card rows and
--its editions and boosters pages came out wider than a 20:9 phone and ran off
--both edges. Once a menu is built it is measured and squeezed until it keeps
--OVERLAY_MARGIN clear on each side: the frame's padding first, then its card
--rows (a title row spreads its cards over whatever width it gets), then the
--minimum widths of everything in it. Mods' menus go through the same path.
local OVERLAY_MARGIN = 0.25

local function overlay_width(box)
    local w = 0
    for _, c in ipairs(box.UIRoot.children or {}) do
        if c.T then w = math.max(w, c.T.w) end
    end
    return w
end

--Tab pages and other boxes hung inside the menu are walked too; their roots go
--into `nested`, innermost first, so they can be recalculated before the menu.
local function each_overlay_node(node, fn, nested)
    fn(node)
    for _, c in ipairs(node.children or {}) do each_overlay_node(c, fn, nested) end
    local obj = node.UIT == G.UIT.O and node.config.object
    if obj and obj.UIRoot and obj.recalculate then
        each_overlay_node(obj.UIRoot, fn, nested)
        if nested then nested[#nested+1] = obj end
    end
end

--The room starts below the top of the screen, so a menu tall enough to fill it
--(Cryptid's run setup on a tablet) ends past the bottom edge. Such a menu goes
--up by what it is over, as far as the top leaves room.
local function lift_overlay(box)
    local panel = box.UIRoot.children[1]
    if box.role.major ~= G.ROOM_ATTACH or not (panel and panel.T) then return end
    local centre = G.ROOM_ATTACH.T.y + G.ROOM_ATTACH.T.h/2
    local top = centre + panel.T.y - (box.T.y + box.T.h/2)
    local over = top + panel.T.h - (portrait_screen_bottom() - OVERLAY_MARGIN)
    local room = top + G.ROOM.T.y - OVERLAY_MARGIN
    box.alignment.offset.y = -math.max(0, math.min(over, room))
    box:align_to_major()
end

local function fit_overlay_width(box)
    local avail = love.graphics.getWidth()/(G.TILESCALE*G.TILESIZE) - 2*OVERLAY_MARGIN
    local function over() return overlay_width(box) - avail end
    if over() <= 0.01 then return end

    local panel = box.UIRoot.config.portrait_frame and box.UIRoot.children[1]
    if panel then
        local frame = panel.children and panel.children[1]
        local inner = frame and frame.children and frame.children[1]
        panel.config.padding = math.min(panel.config.padding or 0.07, 0.04)
        if frame then frame.config.padding = math.min(frame.config.padding or 0.2, 0.08) end
        if inner then inner.config.padding = math.min(inner.config.padding or 0.2, 0.08) end
        box:recalculate()
        if over() <= 0.01 then return end
    end

    local areas, widest = {}, 0
    each_overlay_node(box.UIRoot, function(node)
        local obj = node.UIT == G.UIT.O and node.config.object
        if obj and obj.is and obj:is(CardArea) and obj.T then
            areas[#areas+1] = obj
            widest = math.max(widest, obj.T.w)
        end
    end)
    if #areas > 0 then
        local target = widest - over()
        for _, a in ipairs(areas) do a.T.w = math.min(a.T.w, target) end
        box:recalculate()
    end

    for _ = 1, 4 do
        local excess = over()
        if excess <= 0.01 then return end
        local f = avail/(avail + excess)
        local nested = {}
        each_overlay_node(box.UIRoot, function(node)
            if node ~= box.UIRoot and node.config.minw and node.config.minw > 0.5 then
                node.config.minw = node.config.minw*f
            end
        end, nested)
        for _, b in ipairs(nested) do b:recalculate() end
        box:recalculate()
    end
end

function portrait_fit_overlay(box)
    if not (G and G.F_PORTRAIT_LAYOUT and box and box.UIRoot and G.TILESCALE and G.TILESIZE) then return end
    fit_overlay_width(box)
    lift_overlay(box)
end

function get_portrait_room_fit_delta(box, opts)
    opts = opts or {}

    if not (G and G.F_PORTRAIT_LAYOUT and G.ROOM and G.ROOM.T and box and box.T) then
        return 0, 0
    end

    local room_w = G.ROOM.T.w or 0
    local room_h = G.ROOM.T.h or 0
    if room_w <= 0 or room_h <= 0 then return 0, 0 end

    local padding = opts.screen_padding or (PORTRAIT_CONFIG and PORTRAIT_CONFIG.tooltip_screen_padding) or 0.12
    local left = padding
    local top = padding
    local right = math.max(left, room_w - padding)
    local bottom = math.max(top, room_h - padding)
    local min_x = box.T.x
    local min_y = box.T.y
    local max_x = box.T.x + box.T.w
    local max_y = box.T.y + box.T.h
    local dx = 0
    local dy = 0

    if opts.touch_above_cursor and G.CONTROLLER and G.CONTROLLER.HID and G.CONTROLLER.HID.touch and G.CONTROLLER.cursor_position and G.TILESCALE and G.TILESIZE then
        local touch_gap = opts.touch_gap or (PORTRAIT_CONFIG and PORTRAIT_CONFIG.tooltip_touch_gap) or 1.25
        local cursor_y = G.CONTROLLER.cursor_position.y / (G.TILESCALE * G.TILESIZE) - (G.ROOM.T.y or 0)
        local desired_bottom = cursor_y - touch_gap
        if max_y + dy > desired_bottom then
            dy = desired_bottom - max_y
        end
    end

    if box.T.w >= (right - left) then
        dx = left - min_x
    else
        if min_x + dx < left then dx = left - min_x end
        if max_x + dx > right then dx = right - max_x end
    end

    if box.T.h >= (bottom - top) then
        dy = top - min_y
    else
        if min_y + dy < top then dy = top - min_y end
        if max_y + dy > bottom then dy = bottom - max_y end
    end

    return dx, dy
end

function fit_portrait_side_tooltip(box, parent)
    if not (G and G.F_PORTRAIT_LAYOUT and G.ROOM and G.ROOM.T and box and box.T and parent) then return end

    local padding = (PORTRAIT_CONFIG and PORTRAIT_CONFIG.tooltip_screen_padding) or 0.12
    if box.T.x < padding then
        box:set_alignment({
            major = parent,
            type = 'cr',
            bond = 'Strong',
            offset = {x = 0.03, y = 0},
            lr_clamp = false
        })
        box:align_to_major()
    end

    box.config.fit_to_room = true
    box.config.lr_clamp = false
    box.config.touch_above_cursor = false
    box.config.screen_padding = padding
    if box.fit_to_room then box:fit_to_room() end
    if prepare_portrait_popup_fit then
        prepare_portrait_popup_fit(box)
    elseif box.UIRoot and box.UIRoot.initialize_VT then
        box.UIRoot:initialize_VT()
    end
end

function get_portrait_side_tooltip_config(parent)
    local align = 'cl'
    local offset = {x = -0.03, y = 0}
    if G and G.F_PORTRAIT_LAYOUT and G.ROOM and G.ROOM.T and parent and parent.T then
        local parent_cx = parent.T.x + parent.T.w/2
        if parent_cx < G.ROOM.T.w/2 then
            align = 'cr'
            offset = {x = 0.03, y = 0}
        end
    end
    return align, offset
end

-- Edge-aware popup config for sprites that anchor their tooltip above/below
-- themselves (HUD tags, blind tags, etc.). Unlike fit_to_room, the horizontal
-- offset is derived deterministically from the sprite's own screen position, so
-- a static sprite near the right/left edge gets pulled back on-screen on the
-- first frame instead of relying on the popup's width being measured. fit_to_room
-- stays enabled as a backstop. `opts.half_w` is the assumed popup half-width in
-- tiles; `opts.margin` is the gap kept from the screen edge.
function get_portrait_top_popup_config(sprite, opts)
    opts = opts or {}
    local parent = opts.parent or sprite

    if not (G and G.F_PORTRAIT_LAYOUT and G.ROOM and G.ROOM.T and sprite and sprite.T) then
        -- Landscape / fallback: original side placement
        return {align = 'cl', offset = {x = -0.1, y = 0}, parent = parent}
    end

    local room_w = G.ROOM.T.w or 20
    local room_h = G.ROOM.T.h or 20
    local half_w = opts.half_w or 2.4
    local margin = opts.margin or 0.2

    local sprite_cx = sprite.T.x + sprite.T.w/2
    local sprite_cy = sprite.T.y + sprite.T.h/2

    -- Drop the popup toward screen center: below when the sprite sits in the top
    -- half, above when it sits in the bottom half, so it never runs off the top.
    local dir = (sprite_cy > room_h*0.5) and 'tm' or 'bm'
    local off_y = (dir == 'tm') and (opts.offset_y_tm or -0.2) or (opts.offset_y_bm or 0.1)

    -- Push the centered popup back inside the screen when the sprite is near an edge.
    local offset_x = 0
    if sprite_cx - half_w < margin then
        offset_x = (margin + half_w) - sprite_cx
    elseif sprite_cx + half_w > room_w - margin then
        offset_x = (room_w - margin - half_w) - sprite_cx
    end

    return {
        major = parent,
        parent = parent,
        type = dir,
        offset = {x = offset_x, y = off_y},
        fit_to_room = true,
        snap_to_fit = true,
        can_drag = false,
    }
end
