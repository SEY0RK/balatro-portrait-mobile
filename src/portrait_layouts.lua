--Layout styles beyond Classic (Options > Settings > Game > Layout, see
--portrait_layout in portrait_config.lua), applied on the spot, mid-run too.
--
--Both styles follow the same rules, which is what keeps them tidy:
--  * One column. The HUD, both card shelves, the hand, the score line and the
--    buttons share one width W and one left edge (portrait_frame).
--  * Three text sizes: labels (L), values (V), and the large numbers the game
--    sizes itself (round score, chips x mult, the blind's target).
--  * One surface: dark rounded panels on the felt, tiles in the blind colour.
--  * The space a tall phone leaves over is shared out evenly between the card
--    shelves and the stage (portrait_place_areas), never left in one hole.
--
--  One-Thumb  A short HUD (blind, round score, ante, round, money). Above the
--             hand, a score line: hands left, the hand you are playing with
--             its chips x mult, discards left. Under the hand, Discard and
--             Play as the two biggest targets, Options and Sort below them.
--  Focus      A full-width HUD read top to bottom: the blind and its target,
--             the round score with a bar filling towards the target, the hand
--             with chips x mult, then the five run stats. Nothing repeats it
--             above the cards; one flat bar under the hand.
--
--Every builder keeps the element ids the game and Steamodded look up
--(hand_chips, chip_UI_count, row_blind, row_blind_bottom, run_info_button,
--HUD_blind_count, ...). Elements One-Thumb moves into its score line are found
--through G.HUD as before (see UIBox:get_UIE_by_ID below).

local L_BASE, V_BASE = 0.44, 0.62
local L, V = L_BASE, V_BASE
local EN_K = 1 -- see fit_label_scale
local DOCK_H = 1.46 -- the hand's name over its chips x mult
local DOCK_COMPACT_H = 1.2 -- the same, no taller than the tiles (a short room)
local DOCK_GAP = 0.95 -- room for a selected card's lift between hand and score line

--Labels are sized for the English font. A language whose font draws a
--shorter line (Russian's Noto: a tenth shorter) gets its labels grown to
--match, never shrunk.
--The sizes themselves are set for the game's pixel font (m6x11, whose line
--is as tall as its point size). Readabletro swaps in TypoQuik, whose line is
--28% taller: labels, values and the score line's text (EN_K) are scaled back
--to the pixel font's line, so the HUD keeps the height it was laid out for
--(on a tablet the taller HUD pushed the joker shelf onto the score line).
local PIXEL_LINE = 1.0 * 0.83 -- m6x11: height per point x its TEXT_HEIGHT_SCALE
local function fit_label_scale()
  local en, font = G.LANGUAGES['en-us'].font, G.LANG and G.LANG.font
  if not (font and font.FONT and en and en.FONT) then return end
  local function line(f) return f.FONT:getHeight() * f.FONTSCALE * f.TEXT_HEIGHT_SCALE end
  EN_K = 1
  if en.render_scale and en.render_scale > 0 then
    local per_point = en.FONT:getHeight() / en.render_scale * en.TEXT_HEIGHT_SCALE
    -- Only a clearly taller font; the pixel font itself stays at exactly 1.
    if per_point > PIXEL_LINE * 1.05 then EN_K = math.max(0.75, PIXEL_LINE / per_point) end
  end
  L = L_BASE * EN_K * math.max(1, math.min(1.2, line(en) / line(font)))
  V = V_BASE * EN_K
end

--Where every builder starts: the frame, and the label size for the language.
function portrait_frame()
  fit_label_scale()
  local rw = (G.ROOM and G.ROOM.T and G.ROOM.T.w) or 11.6
  local W = math.min(rw - 0.5, 11.4)
  return (rw - W) / 2, W
end

--Re-lays out the box an element is in, once that box is built. The game
--runs element funcs during the box's first layout too; a relayout from there
--initialised its elements twice, so they stayed in G.MOVEABLES after the box
--was removed and kept moving (and crashed, once what they hung off was gone).
function portrait_relayout(e)
  if e.T and e.UIBox and e.UIBox.UIRoot and e.UIBox.UIRoot.T then e.UIBox:recalculate() end
end

local function en_font() return G.LANGUAGES['en-us'].font end
local function light() return G.C.UI.TEXT_LIGHT end

local function text(str, scale, colour)
  return {n=G.UIT.T, config={text = str, scale = scale, colour = colour or light(), shadow = true}}
end

--DynaText applies maxw once, when it is made. A counter that grows later
--(money in the billions, naneinf, a long boss name) would push its tile and
--the whole HUD past the frame, so the counters here shrink to fit_w as they
--grow and return to their size when they shorten.
local function fit_dynatext(e)
  local obj = e.config.object
  if not (obj and obj.config and obj.config.W and obj.scale and obj.scale > 0 and e.config.fit_w) then return end
  local base = e.config.fit_base or obj.scale
  e.config.fit_base = base
  local natural = obj.config.W * base / obj.scale
  local want = natural > e.config.fit_w and base * e.config.fit_w / natural or base
  if math.abs(want - obj.scale) > 0.002 then
    obj.scale = want
    obj:update_text(true)
    obj.T.w, obj.T.h = obj.config.W, obj.config.H
    obj:align_letters()
    -- Lay the box out again only when the text's width really moved: with
    -- Talisman's big numbers the game re-sets these counters every frame, and
    -- a relayout of the whole HUD each frame slowed play to a crawl.
    if not e.config.fit_last_w or math.abs(e.config.fit_last_w - obj.config.W) > 0.01 then
      e.config.fit_last_w = obj.config.W
      portrait_relayout(e)
    end
  end
end
G.FUNCS.portrait_fit_text = fit_dynatext

--The game's own counter funcs size their text on every change; these run
--them first and fit what they made.
--With fixed, the text keeps its own size and only the fit shrinks it. The
--game shrinks these for its own narrow panel: chips and mult by their digits
--(99,999,999,999 to a third), a hand's name by its length in bytes, three per
--character in Japanese or Chinese ("ストレートフラッシュ" to a third too).
local function fitted(func, fixed)
  return function(e)
    local obj = e.config.object
    local before = obj and obj.scale
    if fixed and obj and not e.config.own_scale then e.config.own_scale = obj.scale end
    G.FUNCS[func](e)
    if obj and obj.scale ~= before then
      e.config.fit_base = fixed and e.config.own_scale or obj.scale
    end
    fit_dynatext(e)
  end
end
G.FUNCS.portrait_hand_chip_UI_set = fitted('hand_chip_UI_set', true)

--The round score is the number the whole round is about; these styles show
--it larger than chip_UI_set's size (config.scale_mult), sized the same way,
--and never wider than config.fit_w: the digit count alone did not hold it
--with Readabletro's wider digits (99,999,999,999 ran off the screen).
G.FUNCS.portrait_chip_UI_set = function(e)
  local before = G.GAME.chips_text
  G.FUNCS.chip_UI_set(e)
  if G.GAME.chips_text ~= before or not e.config.scaled then
    local scale = math.min(0.8, scale_number(G.GAME.chips, 1.1)) * (e.config.scale_mult or 1) * EN_K
    if e.config.fit_w then
      local font = (e.config.lang or G.LANG).font
      local w = font.FONT:getWidth(tostring(G.GAME.chips_text)) * font.squish * font.FONTSCALE / G.TILESIZE
      if w > 0 then scale = math.min(scale, e.config.fit_w / w) end
    end
    e.config.scaled = true
    if math.abs(scale - (e.config.scale or 0)) > 0.002 then
      e.config.scale = scale
      portrait_relayout(e)
    else
      e.config.scale = scale
    end
  end
end
G.FUNCS.portrait_hand_mult_UI_set = fitted('hand_mult_UI_set', true)
G.FUNCS.portrait_hand_text_UI_set = fitted('hand_text_UI_set', true)
-- Fixed too: at the game's size the total grew the score line into the played cards.
G.FUNCS.portrait_hand_chip_total_UI_set = fitted('hand_chip_total_UI_set', true)

local function count_text(ref_table, ref_value, colour, scale, id, prefix, fit_w)
  return {n=G.UIT.O, config={id = id, func = 'portrait_fit_text', fit_w = fit_w or 1.3, object = DynaText({string = {{ref_table = ref_table, ref_value = ref_value, prefix = prefix}}, font = en_font(), colours = {colour}, shadow = true, scale = scale})}}
end

local function stake_icon(size)
  return {n=G.UIT.O, config={w = size, h = size, object = get_stake_sprite(G.GAME.stake or 1, size), hover = true, can_collide = false}}
end

local function hgap(w) return {n=G.UIT.C, config={minw = w}, nodes={}} end
local function vgap(h) return {n=G.UIT.R, config={minh = h}, nodes={}} end

--Width a label takes in the current language's font, in room units.
local function text_w(str, scale)
  local font = G.LANG.font
  return font.FONT:getWidth(str) * font.squish * scale * font.FONTSCALE / G.TILESIZE
end

portrait_text_w = text_w

--A label wider than w goes on two lines rather than shrinking to nothing:
--split at the space nearest its middle ("Mise initiale", "Сортировать
--руку"), or, for one long word ("Weggooimogelijkheden"), hyphenated near its
--middle. What still overflows a line is shrunk by the row's maxw.
function portrait_label_lines(str, w, scale)
  if text_w(str, scale) <= w then return {str} end
  local best, best_d
  for pos in str:gmatch('()%s') do
    local d = math.abs(pos - #str / 2)
    if not best_d or d < best_d then best, best_d = pos, d end
  end
  if best then return {str:sub(1, best - 1), str:sub(best + 1)} end
  -- One word a little too long only shrinks a little; a hyphen is for the
  -- really long ones.
  if text_w(str, scale) <= w * 1.35 then return {str} end
  local chars = {}
  for _, c in utf8.chars(str) do chars[#chars + 1] = c end
  if #chars < 8 then return {str} end
  local half = math.floor(#chars / 2)
  return {table.concat(chars, '', 1, half) .. '-', table.concat(chars, '', half + 1)}
end

--The label itself when it fits on one line, else its lines (create_toggle
--takes either).
function portrait_label_text(str, w, scale)
  local lines = portrait_label_lines(str, w, scale)
  return #lines > 1 and lines or str
end

local function label_rows(str, w, scale, colour)
  local rows = {}
  for _, line in ipairs(portrait_label_lines(str, w, scale)) do
    rows[#rows + 1] = {n=G.UIT.R, config={align = "cm", maxw = w}, nodes={text(line, scale, colour)}}
  end
  return rows
end

local LINE_H = 0.4

--Label over value, in the blind colour. A row of tiles shares one height:
--tiles_h gives the height that fits the tallest label in it.
local function tile_lines(label, w)
  return label and #portrait_label_lines(label, w - 0.2, L) or 0
end

--Width a tile needs for its label at full size (on its lines, as split for w).
local function label_need(label, w)
  local need = 0
  for _, line in ipairs(portrait_label_lines(label, w - 0.2, L)) do need = math.max(need, text_w(line, L)) end
  return need + 0.25
end

local function tiles_h(specs)
  local lines = 0
  for _, sp in ipairs(specs) do lines = math.max(lines, tile_lines(sp[1], sp[2])) end
  return 0.6 + lines * LINE_H + 0.08
end

local function tile(id, label, value_nodes, w, h, value_id)
  local rows = label and label_rows(label, w - 0.2, L) or {}
  rows[#rows + 1] = {n=G.UIT.R, config={id = value_id, align = "cm", minh = 0.5}, nodes=value_nodes}
  -- minw is the inside; the padding brings the tile to exactly w.
  return {n=G.UIT.C, config={id = id, align = "cm", minw = w - 0.08, maxw = w - 0.08, minh = (h or 0.95) - 0.08, padding = 0.04, r = 0.1, colour = G.C.DYN_UI.BOSS_MAIN}, nodes=rows}
end

local function money_text(scale, maxw)
  return {n=G.UIT.O, config={id = 'dollar_text_UI', func = 'portrait_fit_text', fit_w = maxw, object = DynaText({string = {{ref_table = G.GAME, ref_value = 'dollars', prefix = localize('$')}}, maxw = maxw, colours = {G.C.MONEY}, font = en_font(), shadow = true, spacing = 2, bump = true, scale = scale})}}
end

local function ante_nodes()
  return {
    count_text(G.GAME.round_resets, 'ante', G.C.IMPORTANT, V, 'ante_UI_count', nil, 0.7),
    {n=G.UIT.T, config={text = "/", scale = L, colour = light(), shadow = true}},
    {n=G.UIT.T, config={ref_table = G.GAME, ref_value = 'win_ante', scale = L, colour = light(), shadow = true}},
  }
end

--Round score: label, then the number (chip_UI_set sizes it).
local function round_score(w, align)
  local label = localize('k_round')..' '..localize('k_lower_score')
  local label_w = 0
  for _, line in ipairs(portrait_label_lines(label, w * 0.45, L)) do label_w = math.max(label_w, text_w(line, L)) end
  return {n=G.UIT.R, config={id = 'row_dollars_chips', align = align or "cm", minw = w}, nodes={
    {n=G.UIT.C, config={align = "cm", padding = 0.04}, nodes=label_rows(label, w * 0.45, L)},
    {n=G.UIT.C, config={align = "cm", minh = 0.75, padding = 0.04}, nodes={
      stake_icon(0.5),
      hgap(0.08),
      {n=G.UIT.T, config={ref_table = G.GAME, ref_value = 'chips_text', lang = G.LANGUAGES['en-us'], scale = 1.0, colour = light(), id = 'chip_UI_count', func = 'portrait_chip_UI_set', scale_mult = 1.25, fit_w = w - math.min(label_w, w * 0.45) - 0.9, shadow = true}},
    }},
  }}
end

--Hand name and chips x mult. The ids are what scoring animates and lights.
--Stacked puts the name over the meters, both the full name_w wide; compact
--makes the two rows no taller than the tiles beside them (a short room).
local function hand_row(meter_w, name_w, stacked, compact)
  local ch = G.GAME.current_round.current_hand
  local function meter(side, colour, ref_value, id, area_id, func, flame_id)
    local flame = {n=G.UIT.O, config={func = 'flame_handler', no_role = true, id = flame_id, object = Moveable(0,0,0,0), w = 0, h = 0, _w = 2.5, _h = 2.5}}
    local value = {n=G.UIT.O, config={id = id, func = func, fit_w = meter_w - 0.25, object = DynaText({string = {{ref_table = ch, ref_value = ref_value}}, colours = {light()}, font = en_font(), shadow = true, float = true, scale = (compact and 0.7 or 0.9) * EN_K})}}
    local pad = {n=G.UIT.B, config={w = 0.1, h = 0.1}}
    return {n=G.UIT.C, config={align = side, minw = meter_w, minh = compact and 0.6 or 0.8, r = 0.1, colour = colour, id = area_id, emboss = 0.05}, nodes=
      side == "cr" and {flame, value, pad} or {flame, pad, value}}
  end
  -- The level ("lvl.99", "niveau 99") keeps its room beside the name.
  local name_fit = name_w - 0.2 - text_w(' '..localize('k_lvl')..'99', L)
  local name = {n=G.UIT.C, config={align = "cm", minw = name_w, maxw = name_w, minh = stacked and (compact and 0.42 or 0.5) or nil}, nodes={
    {n=G.UIT.O, config={id = 'hand_name', func = 'portrait_hand_text_UI_set', fit_w = name_fit, object = DynaText({string = {{ref_table = ch, ref_value = "handname_text"}}, colours = {light()}, shadow = true, float = true, scale = 0.6 * EN_K})}},
    {n=G.UIT.O, config={id = 'hand_chip_total', func = 'portrait_hand_chip_total_UI_set', fit_w = name_fit, object = DynaText({string = {{ref_table = ch, ref_value = "chip_total_text"}}, colours = {light()}, shadow = true, float = true, scale = 0.6 * EN_K})}},
    {n=G.UIT.T, config={ref_table = ch, ref_value = 'hand_level', scale = L, colour = light(), id = 'hand_level', shadow = true}},
  }}
  local meters = {
    meter("cr", G.C.UI_CHIPS, 'chip_text', 'hand_chips', 'hand_chip_area', 'portrait_hand_chip_UI_set', 'flame_chips'),
    {n=G.UIT.C, config={align = "cm", padding = 0.05}, nodes={
      {n=G.UIT.T, config={text = "X", lang = G.LANGUAGES['en-us'], scale = 0.8 * EN_K, colour = G.C.UI_MULT, shadow = true}},
    }},
    meter("cl", G.C.UI_MULT, 'mult_text', 'hand_mult', 'hand_mult_area', 'portrait_hand_mult_UI_set', 'flame_mult'),
  }
  if stacked then
    table.insert(meters, 3, hgap(0.06))
    table.insert(meters, 2, hgap(0.06))
    return {n=G.UIT.R, config={align = "cm"}, nodes={
      {n=G.UIT.C, config={align = "cm"}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={name}},
        {n=G.UIT.R, config={align = "cm"}, nodes=meters},
      }},
    }}
  end
  table.insert(meters, 1, name)
  return {n=G.UIT.R, config={align = "cm"}, nodes=meters}
end

--Plain-text mirror of the boss debuff lines, as in create_UIBox_HUD_blind.
local function debuff_rows(maxw)
  local lines = (G.GAME.blind and G.GAME.blind.loc_debuff_lines) or {}
  local mirror = {
    portrait_flatten_blind_line(lines[1], lines.vars),
    portrait_flatten_blind_line(lines[2], lines.vars),
  }
  return {n=G.UIT.R, config={align = "cm", id = 'HUD_blind_debuff'}, nodes={
    {n=G.UIT.R, config={align = "cm", minh = 0.3, maxw = maxw}, nodes={
      {n=G.UIT.T, config={ref_table = {val = ''}, ref_value = 'val', scale = 0.36, colour = light(), func = 'HUD_blind_debuff_prefix'}},
      {n=G.UIT.T, config={ref_table = mirror, ref_value = 1, scale = 0.36, colour = light(), id = 'HUD_blind_debuff_1'}},
    }},
    {n=G.UIT.R, config={align = "cm", minh = 0.3, maxw = maxw}, nodes={
      {n=G.UIT.T, config={ref_table = mirror, ref_value = 2, scale = 0.36, colour = light(), id = 'HUD_blind_debuff_2'}},
    }},
  }}
end

--Steamodded's badge naming the mod a blind comes from. Its patch adds this
--row to the vanilla blind panel; the portrait panels add it themselves.
--Empty, and no height, until a modded blind fills it.
--Height the blind's slot in the HUD keeps for that badge (Steamodded only).
function portrait_badge_room()
  return (G.FUNCS and G.FUNCS.HUD_blind_badge) and 0.45 or 0
end

function portrait_blind_badge_row()
  if not (G.FUNCS and G.FUNCS.HUD_blind_badge) then return nil end
  if portrait_wrap_smods_badge then portrait_wrap_smods_badge() end
  return {n=G.UIT.R, config={align = "cm", r = 0.1, id = 'HUD_blind_badge', func = 'HUD_blind_badge'}, nodes={}}
end

--The blind's target and reward. HUD_blind_reward expects the reward row to
--hold its label first and the amount second.
local function blind_target(w)
  return {n=G.UIT.C, config={align = "cm", minw = w}, nodes={
    {n=G.UIT.R, config={align = "cm"}, nodes={{n=G.UIT.C, config={align = "cm"}, nodes=label_rows(localize('ph_blind_score_at_least'), w, L)}}},
    {n=G.UIT.R, config={align = "cm", minh = 0.6}, nodes={
      stake_icon(0.45),
      hgap(0.08),
      {n=G.UIT.T, config={ref_table = G.GAME.blind, ref_value = 'chip_text', scale = 0.001, colour = G.C.RED, shadow = true, id = 'HUD_blind_count', func = 'blind_chip_UI_scale'}},
    }},
    {n=G.UIT.R, config={align = "cm", minh = 0.45, maxw = w, func = 'HUD_blind_reward'}, nodes={
      {n=G.UIT.T, config={text = localize('ph_blind_reward'), scale = L, colour = light()}},
      -- A long reward shrinks itself, not the row with "Récompense :" in it.
      {n=G.UIT.O, config={func = 'portrait_fit_text', fit_w = math.max(1.6, w - text_w(localize('ph_blind_reward'), L) - 0.1), object = DynaText({string = {{ref_table = G.GAME.current_round, ref_value = 'dollars_to_be_earned'}}, colours = {G.C.MONEY}, shadow = true, rotate = true, bump = true, silent = true, scale = 0.5}), id = 'dollars_to_be_earned'}},
    }},
  }}
end

local function blind_name(maxw, scale)
  return {n=G.UIT.O, config={func = 'portrait_fit_text', fit_w = maxw, object = DynaText({string = {{ref_table = G.GAME.blind, ref_value = 'loc_name'}}, colours = {light()}, shadow = true, rotate = true, silent = true, float = true, scale = scale, y_offset = -4, maxw = maxw}), id = 'HUD_blind_name'}}
end

local function run_info_button(w, h)
  return {n=G.UIT.R, config={id = 'run_info_container', align = "cm"}, nodes={
    {n=G.UIT.C, config={id = 'run_info_button', align = "cm", minw = w, maxw = w, minh = h, padding = 0.04, r = 0.1, hover = true, colour = G.C.GREY, button = "run_info", shadow = true}, nodes={
      {n=G.UIT.C, config={align = "cm", focus_args = {button = G.F_GUIDE and 'guide' or 'back', orientation = 'bm'}, func = 'set_button_pip'}, nodes=
        label_rows(localize('b_run_info_1')..' '..localize('b_run_info_2'), w - 0.2, L)}
    }}
  }}
end

local function options_button(w, h)
  return {n=G.UIT.R, config={id = 'options_container', align = "cm"}, nodes={
    {n=G.UIT.C, config={align = "cm", minw = w, maxw = w, minh = h, padding = 0.04, r = 0.1, hover = true, colour = G.C.GREY, button = "options", shadow = true}, nodes={
      {n=G.UIT.C, config={align = "cm", focus_args = {button = 'start', orientation = 'bm'}, func = 'set_button_pip'}, nodes=
        label_rows(localize('b_options'), w - 0.2, L)}
    }}
  }}
end

--The HUD's outer panel: exactly W wide, so its edges are the frame's.
local function hud_panel(W, nodes)
  return {n=G.UIT.ROOT, config={align = "cm", padding = 0, colour = G.C.CLEAR}, nodes={
    {n=G.UIT.R, config={align = "cm", minw = W, padding = 0.1, r = 0.14, colour = G.C.DYN_UI.BOSS_DARK, emboss = 0.05}, nodes=nodes},
  }}
end

-- ===========================================================================
-- One-Thumb
-- ===========================================================================

local THUMB_HUD_H = 2.95 -- room for a boss's two debuff lines

function create_UIBox_HUD_thumb()
  local _, W = portrait_frame()
  local inner = W - 0.2
  local blind_w = math.floor(inner * 0.55 * 100) / 100
  local right_w = inner - blind_w - 0.1
  -- The stats get a full-width row of their own, so labels as long as
  -- "Mise initiale" or "Apuesta inicial" have room. Money is the widest
  -- tile: it is the number that grows longest.
  local row_w = inner - 3 * 0.08
  local tw = math.floor(row_w * 0.22 * 100) / 100
  local info_w = math.floor(row_w * 0.24 * 100) / 100
  local money_w = row_w - 2 * tw - info_w
  local stats_h = tiles_h({{localize('k_ante'), tw}, {localize('k_round'), tw}})

  portrait_build_dock()

  return hud_panel(W, {
    {n=G.UIT.R, config={align = "cm"}, nodes={
      {n=G.UIT.C, config={align = "cm", id = 'row_blind', minw = blind_w, minh = THUMB_HUD_H + portrait_badge_room()}, nodes={
        {n=G.UIT.B, config={w = 0, h = THUMB_HUD_H + portrait_badge_room(), id = 'row_blind_bottom'}, nodes={}}
      }},
      hgap(0.1),
      {n=G.UIT.C, config={align = "cm", minw = right_w, minh = THUMB_HUD_H + portrait_badge_room(), r = 0.1, colour = G.C.DYN_UI.BOSS_MAIN}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={{n=G.UIT.C, config={align = "cm"}, nodes=label_rows(localize('k_round')..' '..localize('k_lower_score'), right_w - 0.2, L)}}},
        {n=G.UIT.R, config={id = 'row_dollars_chips', align = "cm", minh = 0.9}, nodes={
          stake_icon(0.55),
          hgap(0.08),
          {n=G.UIT.T, config={ref_table = G.GAME, ref_value = 'chips_text', lang = G.LANGUAGES['en-us'], scale = 1.15, colour = light(), id = 'chip_UI_count', func = 'portrait_chip_UI_set', scale_mult = 1.45, fit_w = right_w - 0.9, shadow = true}},
        }},
      }},
    }},
    vgap(0.08),
    {n=G.UIT.R, config={align = "cm"}, nodes={
      tile('hud_ante', localize('k_ante'), ante_nodes(), tw, stats_h), hgap(0.08),
      tile('hud_round', localize('k_round'), {count_text(G.GAME, 'round', G.C.IMPORTANT, V, 'round_UI_count')}, tw, stats_h, 'row_round_text'), hgap(0.08),
      tile(nil, nil, {money_text(V, money_w - 0.25)}, money_w, stats_h), hgap(0.08),
      {n=G.UIT.C, config={align = "cm"}, nodes={run_info_button(info_w, stats_h)}},
    }},
  })
end

function create_UIBox_HUD_blind_thumb()
  local _, W = portrait_frame()
  local w = math.floor((W - 0.2) * 0.55 * 100) / 100
  G.GAME.blind:change_dim(1.3, 1.3)
  return {n=G.UIT.ROOT, config={align = "cm", minw = w, minh = THUMB_HUD_H, r = 0.1, colour = G.C.CLEAR, padding = 0, func = 'HUD_blind_visible', id = 'HUD_blind'}, nodes={
    {n=G.UIT.R, config={align = "cm", minw = w, minh = 0.6, r = 0.1, emboss = 0.05, colour = G.C.DYN_UI.MAIN}, nodes={
      blind_name(w - 0.3, V),
    }},
    vgap(0.08),
    -- The boss's debuff under the chip and target, the panel's full width
    -- ("Toutes les cartes perdent leurs bonus" beside the chip was 6 px).
    {n=G.UIT.R, config={align = "cm", minw = w, minh = THUMB_HUD_H - 0.68, r = 0.1, colour = G.C.DYN_UI.DARK, padding = 0.05}, nodes={
      {n=G.UIT.C, config={align = "cm"}, nodes={
        {n=G.UIT.R, config={align = "cm"}, nodes={
          {n=G.UIT.C, config={align = "cm"}, nodes={{n=G.UIT.O, config={object = G.GAME.blind, draw_layer = 1}}}},
          hgap(0.08),
          {n=G.UIT.C, config={align = "cm"}, nodes={blind_target(w - 1.6)}},
        }},
        debuff_rows(w - 0.3),
      }},
    }},
    portrait_blind_badge_row(),
  }}
end

--Takes the score line down. Anything still bound to the box afterwards
--would keep moving it and, through it, the hand it hangs off, which crashes
--once that hand is gone (a new run): portrait_relayout fixed the one way that
--happened, and this sweep keeps any other from reaching the hand.
function portrait_remove_dock()
  local dock = G.HUD_dock
  if not dock then return end
  G.HUD_dock = nil
  dock:remove()
  for i = #G.MOVEABLES, 1, -1 do
    local m = G.MOVEABLES[i]
    if m.role and m.role.major == dock then table.remove(G.MOVEABLES, i) end
  end
end

--The score line above the hand. Its own box, so it stays up while the hand
--is played and scored (the button bar is taken down then).
function portrait_build_dock()
  portrait_remove_dock()
  if not G.hand then return end
  local _, W = portrait_frame()
  -- The side tiles grow (to 2.4) for a long label; the hand's name and its
  -- chips x mult, stacked, take the rest of the width. A short room (a
  -- tablet) has no height to spare, so there the two rows are compact: no
  -- taller than the tiles, its pixels large enough for the smaller text.
  local side = 1.55
  for _, label in ipairs({localize('k_hud_hands'), localize('k_hud_discards')}) do
    side = math.max(side, math.min(2.4, text_w(label, L) + 0.3, label_need(label, 2.4)))
  end
  local mid = W - 0.2 - 2 * side - 0.16
  local compact = G.ROOM.T.h < (PORTRAIT_CONFIG.short_room_h or 24)
  local dock_h = compact and DOCK_COMPACT_H or DOCK_H
  local meter_w = math.min(2.6, (mid - 0.1 - 0.75) / 2)
  local tiles = math.max(dock_h - 0.16, tiles_h({{localize('k_hud_hands'), side}, {localize('k_hud_discards'), side}}))
  G.HUD_dock = UIBox{
    definition = {n=G.UIT.ROOT, config={align = "cm", padding = 0, colour = G.C.CLEAR, func = 'portrait_dock_visible'}, nodes={
      {n=G.UIT.R, config={id = 'thumb_dock', align = "cm", minw = W, minh = dock_h, padding = 0.08, r = 0.14, colour = G.C.DYN_UI.BOSS_DARK, emboss = 0.05}, nodes={
        tile('hud_hands', localize('k_hud_hands'), {count_text(G.GAME.current_round, 'hands_left', G.C.BLUE, V, 'hand_UI_count')}, side, tiles),
        hgap(0.08),
        {n=G.UIT.C, config={id = 'hand_text_area', align = "cm", minw = mid, maxw = mid, minh = tiles, r = 0.1, colour = darken(G.C.BLACK, 0.1)}, nodes={
          hand_row(meter_w, mid - 0.1, true, compact),
        }},
        hgap(0.08),
        tile('hud_discards', localize('k_hud_discards'), {count_text(G.GAME.current_round, 'discards_left', G.C.RED, V, 'discard_UI_count')}, side, tiles),
      }},
    }},
    config = {align = 'tm', offset = {x = 0, y = -DOCK_GAP}, major = G.hand, bond = 'Weak'}
  }
  G.HUD_dock.states.collide.can = false
end

--Shown while there is a hand to play; the shop, blind select and packs use
--that part of the screen.
local DOCK_STATES = {'SELECTING_HAND', 'HAND_PLAYED', 'DRAW_TO_HAND', 'NEW_ROUND', 'PLAY_TAROT'}
G.FUNCS.portrait_dock_visible = function(e)
  local show = false
  for _, s in ipairs(DOCK_STATES) do
    if G.STATE == G.STATES[s] then show = true break end
  end
  e.UIBox.states.visible = show
end

--Elements One-Thumb keeps in its score line (hands, discards, the hand's
--chips x mult) are still found through G.HUD, where the game looks for them.
local uibox_get_UIE_by_ID = UIBox.get_UIE_by_ID
function UIBox:get_UIE_by_ID(id, node)
  local found = uibox_get_UIE_by_ID(self, id, node)
  if found == nil and node == nil and self == G.HUD and G.HUD_dock and not G.HUD_dock.REMOVED then
    found = uibox_get_UIE_by_ID(G.HUD_dock, id)
  end
  return found
end

-- ===========================================================================
-- Focus
-- ===========================================================================

local FOCUS_BLIND_H = 2.3 -- room for a boss's two debuff lines under the blind

--Run Info and Options beside the blind: 2.3 wide, up to 2.9 for a label that
--needs it ("Параметры"); the blind panel gives the width.
local function focus_side_w()
  local need = math.max(label_need(localize('b_options'), 2.9), label_need(localize('b_run_info_1')..' '..localize('b_run_info_2'), 2.9))
  return math.max(2.3, math.min(2.9, need))
end
local function focus_blind_w(W) return W - 0.2 - focus_side_w() - 0.1 end

function create_UIBox_HUD_focus()
  local _, W = portrait_frame()
  local inner = W - 0.2
  -- Four counter tiles and money, which gets the rest; a tile whose label
  -- needs more ("Weggooimog-/elijkheden") takes it from money.
  local tw = (inner - 4 * 0.08) / 5.4
  local labels = {localize('k_hud_hands'), localize('k_hud_discards'), localize('k_ante'), localize('k_round')}
  local ws = {}
  for k, label in ipairs(labels) do ws[k] = math.max(tw, math.min(tw * 1.25, label_need(label, tw))) end
  local money_w = inner - 4 * 0.08 - ws[1] - ws[2] - ws[3] - ws[4]
  local stats_h = tiles_h({{labels[1], ws[1]}, {labels[2], ws[2]}, {labels[3], ws[3]}, {labels[4], ws[4]}})
  portrait_remove_dock()

  return hud_panel(W, {
    {n=G.UIT.R, config={align = "cm"}, nodes={
      {n=G.UIT.C, config={align = "cm", id = 'row_blind', minw = focus_blind_w(W), minh = FOCUS_BLIND_H + portrait_badge_room()}, nodes={
        {n=G.UIT.B, config={w = 0, h = FOCUS_BLIND_H + portrait_badge_room(), id = 'row_blind_bottom'}, nodes={}}
      }},
      hgap(0.1),
      {n=G.UIT.C, config={align = "cm", minh = FOCUS_BLIND_H + portrait_badge_room()}, nodes={
        run_info_button(focus_side_w(), (FOCUS_BLIND_H - 0.1) / 2),
        vgap(0.1),
        options_button(focus_side_w(), (FOCUS_BLIND_H - 0.1) / 2),
      }},
    }},
    vgap(0.1),
    {n=G.UIT.R, config={align = "cm", minw = inner, padding = 0.06, r = 0.1, colour = G.C.DYN_UI.BOSS_MAIN}, nodes={
      {n=G.UIT.R, config={align = "cm", minw = inner - 0.12}, nodes={round_score(inner - 0.12)}},
      {n=G.UIT.R, config={align = "cl", minw = inner - 0.12, minh = 0.2, r = 0.1, colour = {0, 0, 0, 0.35}}, nodes={
        {n=G.UIT.C, config={id = 'portrait_progress', align = "cm", minw = 0.001, minh = 0.2, r = 0.1, colour = G.C.BLUE, func = 'portrait_progress', bar_w = inner - 0.12}, nodes={}},
      }},
    }},
    vgap(0.1),
    {n=G.UIT.R, config={id = 'hand_text_area', align = "cm", minw = inner, padding = 0.06, r = 0.1, colour = darken(G.C.BLACK, 0.1)}, nodes={
      hand_row(2.3, inner - 2 * 2.3 - 0.7),
    }},
    vgap(0.1),
    {n=G.UIT.R, config={align = "cm"}, nodes={
      tile('hud_hands', labels[1], {count_text(G.GAME.current_round, 'hands_left', G.C.BLUE, V, 'hand_UI_count')}, ws[1], stats_h), hgap(0.08),
      tile('hud_discards', labels[2], {count_text(G.GAME.current_round, 'discards_left', G.C.RED, V, 'discard_UI_count')}, ws[2], stats_h), hgap(0.08),
      tile(nil, nil, {money_text(V, money_w - 0.2)}, money_w, stats_h), hgap(0.08),
      tile('hud_ante', labels[3], ante_nodes(), ws[3], stats_h), hgap(0.08),
      tile('hud_round', labels[4], {count_text(G.GAME, 'round', G.C.IMPORTANT, V, 'round_UI_count')}, ws[4], stats_h, 'row_round_text'),
    }},
  })
end

function create_UIBox_HUD_blind_focus()
  local _, W = portrait_frame()
  local w = focus_blind_w(W)
  -- Wider for a long "Récompense :", so it and the reward both keep their size.
  local target_w = math.max(3.4, math.min(4.2, text_w(localize('ph_blind_reward'), L) + 1.8))
  G.GAME.blind:change_dim(1.2, 1.2)
  return {n=G.UIT.ROOT, config={align = "cm", minw = w, minh = FOCUS_BLIND_H, r = 0.1, colour = G.C.DYN_UI.DARK, padding = 0.05, func = 'HUD_blind_visible', id = 'HUD_blind'}, nodes={
    {n=G.UIT.R, config={align = "cm", minw = w - 0.1}, nodes={
      {n=G.UIT.C, config={align = "cm"}, nodes={{n=G.UIT.O, config={object = G.GAME.blind, draw_layer = 1}}}},
      hgap(0.1),
      {n=G.UIT.C, config={align = "cm", minw = w - 1.3 - target_w - 0.2}, nodes={
        {n=G.UIT.R, config={align = "cm", minh = 0.6}, nodes={blind_name(w - 1.3 - target_w - 0.3, V)}},
      }},
      hgap(0.1),
      blind_target(target_w),
    }},
    -- A boss's debuff gets the panel's full width ("Toutes les cartes
    -- perdent leurs bonus" was squeezed beside the name).
    debuff_rows(w - 0.3),
    portrait_blind_badge_row(),
  }}
end

--The bar under Focus's round score fills towards the blind's target.
G.FUNCS.portrait_progress = function(e)
  local target = G.GAME.blind and G.GAME.blind.chips
  local chips = G.GAME.chips
  local frac = 0
  if type(target) == 'number' and target > 0 and type(chips) == 'number' then
    frac = math.max(0, math.min(1, chips / target))
  end
  local w = math.max(0.001, frac * (e.config.bar_w or 1))
  if math.abs((e.config.minw or 0) - w) > 0.02 then
    e.config.minw = w
    portrait_relayout(e)
  end
  e.config.colour = frac >= 1 and G.C.GOLD or G.C.BLUE
end

-- ===========================================================================
-- Button bars
-- ===========================================================================

--Steamodded's "Limit: 7" under Play / Discard when a mod changes how many
--cards they take. Its own patch looks for the vanilla button rows, which the
--portrait bars do not have, so every bar adds the row itself. nil without it.
function portrait_hand_limit_row(which, scale)
  if not (SMODS and SMODS.hand_limit_strings) then return nil end
  return {n=G.UIT.R, config={align = "cm", padding = 0}, nodes={
    {n=G.UIT.T, config={ref_table = SMODS.hand_limit_strings, ref_value = which, scale = scale, colour = G.C.UI.TEXT_LIGHT, shadow = true}}
  }}
end

local function action(id, button, func, colour, w, h, label, label_scale, pip, limit)
  return {n=G.UIT.C, config={id = id, align = "cm", minw = w, maxw = w, minh = h, padding = 0.08, r = 0.14, hover = true, colour = colour, button = button, one_press = true, shadow = true, func = func}, nodes={
    {n=G.UIT.R, config={align = "cm", maxw = w - 0.3}, nodes={
      {n=G.UIT.T, config={text = label, scale = label_scale, colour = light(), shadow = true, focus_args = {button = pip, orientation = 'bm'}, func = 'set_button_pip'}}
    }},
    portrait_hand_limit_row(limit, L),
  }}
end

local function pill(id, label, button, w, colour)
  return {n=G.UIT.C, config={id = id, align = "cm", minh = 0.72, minw = w, maxw = w, padding = 0.06, r = 0.14, hover = true, colour = colour, button = button, shadow = true}, nodes={
    {n=G.UIT.T, config={text = label, scale = L, maxw = w - 0.2, colour = light(), shadow = true}}
  }}
end

--Swipe Only's cue: with cards selected, the directions fade in on either side
--of the hand's "8/8", where Play and Discard were and in their colours. They
--are not buttons, and are gone as soon as nothing is selected.
local swipe_arrow
local function arrow_node(size, up, colour)
  if not swipe_arrow then
    swipe_arrow = Moveable:extend()
    function swipe_arrow:init(s, is_up, c)
      Moveable.init(self, 0, 0, s, s)
      self.up, self.colour = is_up, c
      self.states.collide.can = false
    end
    function swipe_arrow:draw()
      local w, h = self.VT.w, self.VT.h
      prep_draw(self, 1)
      love.graphics.setColor(self.colour)
      if self.up then
        love.graphics.polygon('fill', 0, h, w / 2, 0, w, h)
      else
        love.graphics.polygon('fill', 0, 0, w / 2, h, w, 0)
      end
      love.graphics.pop()
    end
  end
  return {n=G.UIT.O, config={object = swipe_arrow(size, up, colour), can_collide = false}}
end

G.FUNCS.portrait_swipe_hint = function(e)
  local selected = (G.STATE == G.STATES.SELECTING_HAND and G.hand and #G.hand.highlighted) or 0
  local can
  if e.config.hint == 'play' then
    can = selected <= (G.hand and G.hand.config.highlighted_limit or 5) and not (G.GAME.blind and G.GAME.blind.block_play)
  else
    can = G.GAME.current_round.discards_left > 0
  end
  local target = selected > 0 and (can and 1 or 0.35) or 0
  local alpha = e.config.hint_alpha + (target - e.config.hint_alpha) * math.min(1, 12 * (G.real_dt or 0.016))
  e.config.hint_alpha = alpha
  e.config.colour[4] = 0.75 * alpha
  e.config.hint_colour[4] = alpha
end

--The cue's row: order as the bar's Play and Discard had it, empty in the middle
--for the card counter.
function portrait_swipe_hint_row(w, play_right)
  local function hint(kind, label, up, colour)
    local c = {colour[1], colour[2], colour[3], 0}
    return {n=G.UIT.C, config={align = "cm", padding = 0.07, r = 0.1, colour = {0, 0, 0, 0}, func = 'portrait_swipe_hint', hint = kind, hint_alpha = 0, hint_colour = c}, nodes={
      arrow_node(0.2, up, c),
      hgap(0.1),
      {n=G.UIT.T, config={text = label, scale = L, colour = c}},
    }}
  end
  local play = hint('play', localize('b_play_hand'), true, G.C.BLUE)
  local discard = hint('discard', localize('b_discard'), false, G.C.RED)
  local room = w - text_w(localize('b_play_hand'), L) - text_w(localize('b_discard'), L) - 1.1
  local middle = {n=G.UIT.C, config={minw = math.max(1.2, room)}, nodes={}}
  return {n=G.UIT.R, config={align = "cm", minw = w, minh = 0.46}, nodes=play_right and {discard, middle, play} or {play, middle, discard}}
end

--Swipe Only drops Play and Discard (swipe up plays, down discards) and keeps
--what each bar has besides them, in one thin row under the cue: One-Thumb's
--Options, Rank and Suit, Focus's sort toggle. The hand takes the room: its
--cards grow (hand_card_scale), it sits lower (swipe_hand_base_offset), and
--the shelves and stage share out the rest.
function create_UIBox_buttons_layout(layout, swipe)
  local _, W = portrait_frame()
  local inner = W - 0.1
  if layout == 'one_thumb' then
    local h = 1.7
    local play_w = math.floor((inner - 0.1) * 0.6 * 100) / 100
    local discard_w = inner - 0.1 - play_w
    local play = action('play_button', 'play_cards_from_highlighted', 'can_play', G.C.BLUE, play_w, h, localize('b_play_hand'), 0.7, 'x', 'play')
    local discard = action('discard_button', 'discard_cards_from_highlighted', 'can_discard', G.C.RED, discard_w, h, localize('b_discard'), 0.6, 'y', 'discard')
    -- Play sits under the thumb: the outer edge on the hand it is held in.
    local right_handed = (G.SETTINGS.play_main_hand or 2) == 2
    local pw = (inner - 0.2) / 3
    local menu = pill('thumb_menu_button', localize('b_options'), 'options', pw, G.C.GREY)
    menu.config.focus_args = {button = 'start', orientation = 'bm'}
    local small_row = {n=G.UIT.R, config={align = "cm"}, nodes={
      menu, hgap(0.1),
      pill(nil, localize('k_rank'), 'sort_hand_value', pw, G.C.ORANGE), hgap(0.1),
      pill(nil, localize('k_suit'), 'sort_hand_suit', pw, G.C.ORANGE),
    }}
    local rows = swipe and {portrait_swipe_hint_row(inner, right_handed), small_row} or {
      {n=G.UIT.R, config={align = "cm"}, nodes=right_handed and {discard, hgap(0.1), play} or {play, hgap(0.1), discard}},
      vgap(0.1),
      small_row,
    }
    return {n=G.UIT.ROOT, config={align = "cm", padding = 0, colour = G.C.CLEAR}, nodes={
      {n=G.UIT.R, config={align = "cm", minw = W, padding = 0.05}, nodes=rows},
    }}
  end

  -- Focus: Discard | sort toggle | Play, one row, one height.
  PORTRAIT_SORT_STATE.label = PORTRAIT_SORT_STATE.next == 'suit' and localize('k_suit') or localize('k_rank')
  if swipe then
    return {n=G.UIT.ROOT, config={align = "cm", padding = 0, colour = G.C.CLEAR}, nodes={
      portrait_swipe_hint_row(inner, G.SETTINGS.play_button_pos == 1),
      {n=G.UIT.R, config={align = "cm", minw = W, padding = 0.05}, nodes={
        {n=G.UIT.C, config={id = 'focus_sort_button', align = "cm", minw = inner, maxw = inner, minh = 0.72, padding = 0.06, r = 0.14, hover = true, colour = G.C.DYN_UI.BOSS_DARK, button = 'portrait_sort_toggle', shadow = true}, nodes={
          text(localize('b_sort_hand'), L),
          hgap(0.2),
          {n=G.UIT.T, config={ref_table = PORTRAIT_SORT_STATE, ref_value = 'label', scale = V, colour = G.C.ORANGE, shadow = true}},
        }},
      }},
    }}
  end
  local h = 1.55
  -- Wider for a long label ("Сортировать"), up to 3.2; Play and Discard give it.
  local sort_w = math.max(2.5, math.min(3.2, label_need(localize('b_sort_hand'), 3.2)))
  local side_w = (inner - sort_w - 0.2) / 2
  local play = action('play_button', 'play_cards_from_highlighted', 'can_play', G.C.BLUE, side_w, h, localize('b_play_hand'), 0.65, 'x', 'play')
  local discard = action('discard_button', 'discard_cards_from_highlighted', 'can_discard', G.C.RED, side_w, h, localize('b_discard'), 0.65, 'y', 'discard')
  local sort = {n=G.UIT.C, config={id = 'focus_sort_button', align = "cm", minw = sort_w, maxw = sort_w, minh = h, padding = 0.06, r = 0.14, hover = true, colour = G.C.DYN_UI.BOSS_DARK, button = 'portrait_sort_toggle', shadow = true}, nodes={
    {n=G.UIT.R, config={align = "cm"}, nodes={{n=G.UIT.C, config={align = "cm"}, nodes=label_rows(localize('b_sort_hand'), sort_w - 0.2, L)}}},
    {n=G.UIT.R, config={align = "cm", maxw = sort_w - 0.15}, nodes={
      {n=G.UIT.T, config={ref_table = PORTRAIT_SORT_STATE, ref_value = 'label', scale = V, colour = G.C.ORANGE, shadow = true}}
    }},
  }}
  -- Same order rule as the classic bar (Play/Discard Button Position).
  local row = G.SETTINGS.play_button_pos == 1 and {discard, hgap(0.1), sort, hgap(0.1), play} or {play, hgap(0.1), sort, hgap(0.1), discard}
  return {n=G.UIT.ROOT, config={align = "cm", padding = 0, colour = G.C.CLEAR}, nodes={
    {n=G.UIT.R, config={align = "cm", minw = W, padding = 0.05}, nodes=row},
  }}
end

-- ===========================================================================
-- Placing the card areas
-- ===========================================================================

local AREA_LABEL_H = 0.4 -- the "0/5" counters under the shelves

--Moveable:align_to_major works out a box's offset from its major once, when
--the alignment changes, not when the major is resized. After the areas
--change width, everything hung off them (button bar, score line, hand
--preview, shop, tags) is made to work it out again.
local function realign_area_boxes()
  local areas = {[G.hand] = true, [G.jokers] = true, [G.play] = true, [G.deck] = true, [G.consumeables] = true}
  for _, m in pairs(G.MOVEABLES) do
    if m.role and m.role.major and areas[m.role.major] and m.alignment then m.alignment.prev_type = nil end
  end
end

--Swipe Only's bigger cards need a taller hand area: the counter, the bar and
--the score line hang off its edges. Runs from CardArea:move, so a new run or a
--live toggle is picked up.
function portrait_set_hand_height()
  local hand = G.hand
  hand.portrait_base_h = hand.portrait_base_h or hand.T.h
  local h = hand.portrait_base_h * portrait_hand_scale()
  if math.abs(hand.T.h - h) > 0.001 then
    hand.T.h = h
    realign_area_boxes()
  end
end

--Card areas in the frame: consumables and deck on one shelf, jokers on the
--next, the stage for played cards, then the hand with what hangs off it. The
--spare height is shared evenly between the gaps. Returns false for Classic,
--which keeps its own placement in set_screen_positions.
function portrait_place_areas()
  local pc = PORTRAIT_CONFIG
  local layout = portrait_layout()
  local lc = pc.layouts and pc.layouts[layout]
  for _, area in ipairs({G.jokers, G.hand, G.play}) do
    area.portrait_base_w = area.portrait_base_w or area.T.w
  end
  if not lc then
    for _, area in ipairs({G.jokers, G.hand, G.play}) do area.T.w = area.portrait_base_w end
    realign_area_boxes()
    return false
  end

  local x0, W = portrait_frame()
  local room_h = G.ROOM.T.h
  G.jokers.T.w = W
  G.hand.T.w = W
  G.play.T.w = math.min(G.play.portrait_base_w, W)

  G.hand.T.x = x0
  G.hand.T.y = room_h - G.hand.T.h - pc.bottom_margin - get_hand_base_offset()

  -- Above the hand: a selected card's lift, and One-Thumb's score line.
  local above_hand = DOCK_GAP
  if layout == 'one_thumb' then
    above_hand = DOCK_GAP + ((G.HUD_dock and not G.HUD_dock.REMOVED and G.HUD_dock.T.h) or DOCK_H)
  end
  local stage_bottom = G.hand.T.y - above_hand - 0.15
  local hud_bottom = (G.HUD and not G.HUD.REMOVED and G.HUD.T) and (G.HUD.T.y + G.HUD.T.h) or 4
  local shelf_h = G.consumeables.T.h + AREA_LABEL_H
  local jokers_h = G.jokers.T.h + AREA_LABEL_H
  -- Even gaps, up to a point: past it the shelves stay with the HUD and the
  -- stage takes the middle of what is left, so the screen reads as two
  -- groups (what you have, what you play) rather than loose rows.
  local spare = stage_bottom - hud_bottom - shelf_h - jokers_h - G.play.T.h
  local gap = math.max(0.1, math.min(0.75, spare / 4))
  local stage_gap = math.max(gap, (spare - 2 * gap) / 2)

  local y = hud_bottom + gap
  local right_handed = (G.SETTINGS.play_main_hand or 2) == 2
  if right_handed then
    G.consumeables.T.x = x0 + W - G.consumeables.T.w
    G.deck.T.x = x0
  else
    G.consumeables.T.x = x0
    G.deck.T.x = x0 + W - G.deck.T.w
  end
  G.consumeables.T.y = y
  G.deck.T.y = y

  y = y + shelf_h + gap
  G.jokers.T.x = x0
  G.jokers.T.y = y

  y = y + jokers_h + stage_gap
  G.play.T.x = x0 + (W - G.play.T.w) / 2
  G.play.T.y = math.min(y, stage_bottom - G.play.T.h)

  G.discard.T.x = G.play.T.x + G.play.T.w + pc.discard_x_offset
  G.discard.T.y = G.play.T.y
  realign_area_boxes()
  portrait_arrange_tags()
  return true
end

--Place the portrait HUD only after its final UIBox width has been measured.
--ROOM is a Node (not a Moveable role major), so the vanilla portrait path
--intentionally positions the HUD directly rather than relying on role offsets.
function portrait_position_run_hud(hud)
  hud = hud or (G and G.HUD)
  if not (G and G.F_PORTRAIT_LAYOUT and G.ROOM and G.ROOM.T
          and hud and not hud.REMOVED and hud.T and hud.VT) then return end

  local x = G.ROOM.T.x + (G.ROOM.T.w - hud.T.w) / 2
  local changed = math.abs((hud.T.x or 0) - x) > 0.001
      or math.abs((hud.VT.x or 0) - x) > 0.001
  if changed then
    hud.T.x, hud.VT.x = x, x
    if hud.velocity then hud.velocity.x = 0 end
    -- Re-sync the child UI tree only when the HUD's world position changes.
    if hud.UIRoot and hud.UIRoot.initialize_VT then hud.UIRoot:initialize_VT() end
  end
  hud._portrait_position_passes = (hud._portrait_position_passes or 0) + 1
  hud._portrait_position_last_x = x
end

-- Switching styles in a run
-- ===========================================================================

--Rebuilds the HUD, blind panel, score line and hand preview in the current
--style, the way start_run builds them, so a style picked mid-run shows at
--once. Boxes anchored to the old HUD (blind prompt, shop sign) are moved to
--the new one.
function portrait_rebuild_HUD()
  if not (G.STAGE == G.STAGES.RUN and G.HUD and G.HUD_blind and G.GAME and G.GAME.blind) then return end
  local is_portrait = not not G.F_PORTRAIT_LAYOUT
  local had_hand_preview = G.hand_preview ~= nil

  -- Keep the active Blind object alive while replacing the HUD in either direction.
  local function detach(node)
    if node.config and node.config.object == G.GAME.blind then node.config.object = nil end
    for _, child in pairs(node.children or {}) do detach(child) end
  end
  detach(G.HUD_blind.UIRoot)

  local old_major = G.HUD_blind.role and G.HUD_blind.role.major
  local major_id = (old_major and old_major.config and old_major.config.id) or 'row_blind'
  local blind_offset_y = G.HUD_blind.alignment and G.HUD_blind.alignment.offset and G.HUD_blind.alignment.offset.y or 0

  G.HUD:remove()
  G.HUD_blind:remove()
  portrait_remove_dock()
  if G.hand_preview then G.hand_preview:remove(); G.hand_preview = nil end

  local row_align = is_portrait and 'tm' or 'cli'
  local row_offset = is_portrait and {x = 0, y = 0} or {x = -0.7, y = 0}
  -- Keep the proven upstream split: the portrait HUD is aligned directly to
  -- ROOM and positioned from ROOM's measured width; landscape uses ROOM_ATTACH.
  local row_major = is_portrait and G.ROOM or G.ROOM_ATTACH
  G.HUD = UIBox{
    definition = is_portrait and create_UIBox_HUD_vertical() or create_UIBox_HUD(),
    config = {align = row_align, offset = row_offset, major = row_major}
  }
  if is_portrait then
    G.HUD.T.y = 0.2
    G.HUD.T.x = (G.ROOM.T.w - G.HUD.T.w) / 2
  end

  local row_blind = G.HUD:get_UIE_by_ID('row_blind')
  G.HUD_blind = UIBox{
    definition = create_UIBox_HUD_blind(),
    config = {
      major = G.HUD:get_UIE_by_ID(major_id) or row_blind,
      align = 'cm',
      offset = {x = 0, y = is_portrait and blind_offset_y or -10},
      bond = 'Weak'
    }
  }
  if is_portrait then
    for _, id in ipairs({'HUD_blind_debuff_1', 'HUD_blind_debuff_2'}) do
      local node = G.HUD_blind:get_UIE_by_ID(id)
      if node then node.config.func = 'portrait_HUD_blind_debuff' end
    end
  end

  G.hand_text_area = {
    chips = G.HUD:get_UIE_by_ID('hand_chips'),
    mult = G.HUD:get_UIE_by_ID('hand_mult'),
    ante = G.HUD:get_UIE_by_ID('ante_UI_count'),
    round = G.HUD:get_UIE_by_ID('round_UI_count'),
    chip_total = G.HUD:get_UIE_by_ID('hand_chip_total'),
    handname = G.HUD:get_UIE_by_ID('hand_name'),
    hand_level = G.HUD:get_UIE_by_ID('hand_level'),
    game_chips = G.HUD:get_UIE_by_ID('chip_UI_count'),
    blind_chips = G.HUD_blind:get_UIE_by_ID('HUD_blind_count'),
    blind_spacer = G.HUD:get_UIE_by_ID('blind_spacer'),
  }
  G.FUNCS.blind_chip_UI_scale(G.hand_text_area.blind_chips)
  G.HUD:recalculate()
  if is_portrait then portrait_position_run_hud(G.HUD) end
  G.HUD_blind:recalculate()

  if had_hand_preview and is_portrait and PORTRAIT_CONFIG.hand_preview and PORTRAIT_CONFIG.hand_preview.enabled then
    G.hand_preview = UIBox{
      definition = create_UIBox_hand_preview(),
      config = {align = 'tm', offset = {x = 0, y = PORTRAIT_CONFIG.hand_preview.y_offset or -0.65}, major = G.hand, bond = 'Weak'}
    }
    G.hand_preview.states.collide.can = false
    G.hand_preview.states.visible = false
  end

  -- Boxes anchored to the old blind row must follow the replacement row.
  for _, box in ipairs({G.blind_prompt_box, G.SHOP_SIGN}) do
    if box and not box.REMOVED and row_blind then
      box:set_alignment({major = row_blind})
      for k, v in ipairs(G.I.UIBOX) do
        if v == box then table.remove(G.I.UIBOX, k) break end
      end
      table.insert(G.I.UIBOX, box)
    end
  end
end
--Where Classic's joker shelf sits: its tuned jokers_y on phones. On a short
--room (tablets, 16:10) that left the shop no room under the shelf and pushed
--its bottom row off screen, so there the shelves start under the HUD.
function portrait_jokers_y()
  local pc = PORTRAIT_CONFIG
  local short_room = G.ROOM and G.ROOM.T and G.ROOM.T.h < (pc.short_room_h or 24)
  if not (short_room and G.HUD and not G.HUD.REMOVED and G.HUD.T and G.jokers) then return pc.jokers_y end
  local shelf_top = G.HUD.T.y + G.HUD.T.h + 0.45
  return math.min(pc.jokers_y, shelf_top + G.jokers.T.h + 0.6)
end

--The round's end, blind select and shop panels hang off the hand. A style
--whose hand sits higher or lower than Classic's moves them by the
--difference, so they keep Classic's place at the bottom of the screen.
function portrait_panel_drop()
  if not G.F_PORTRAIT_LAYOUT then return 0 end
  local grown = G.hand and G.hand.portrait_base_h and (G.hand.T.h - G.hand.portrait_base_h) or 0
  return get_hand_base_offset() - PORTRAIT_CONFIG.hand_base_offset + grown
end

--The bottom of the screen in room units. The room starts G.ROOM.T.y down
--the screen, so its own height runs past the bottom edge.
function portrait_screen_bottom()
  return love.graphics.getHeight() / (G.TILESCALE * G.TILESIZE) - G.ROOM.T.y
end

--The shop's place under the hand: its top kept under the joker shelf. On a
--short room (a tablet in Focus) that left its packs off the bottom of the
--screen, so there the gap under the shelf gives up to 0.3 first.
function portrait_shop_offset()
  local floor_y = portrait_shelf_floor()
  local y = math.max(-5.3 + portrait_panel_drop(), floor_y and (floor_y - G.hand.T.y) or -99)
  if G.shop and G.shop.T and G.ROOM and floor_y then
    local fits = portrait_screen_bottom() - 0.05 - G.shop.T.h - G.hand.T.y
    y = math.min(y, math.max(fits, floor_y - 0.3 - G.hand.T.y))
  end
  return y
end

--Blind select's place: bottom-aligned in the hand, its top kept under the
--joker shelf so Select stays tappable, and, like the shop, its bottom on the
--screen (Japanese text, taller, took it 12 px past a tablet's edge).
function portrait_blind_select_offset()
  local box = G.blind_select
  local y = 0.8 - (G.hand.T.y - PORTRAIT_CONFIG.jokers_y) + box.T.h
  local floor_y = portrait_shelf_floor()
  if floor_y then
    y = math.max(y, floor_y - (G.hand.T.y + G.hand.T.h) + box.T.h)
    local fits = portrait_screen_bottom() - 0.05 - (G.hand.T.y + G.hand.T.h)
    y = math.min(y, math.max(fits, floor_y - 0.3 - (G.hand.T.y + G.hand.T.h) + box.T.h))
  end
  return y
end

--Where the hand comes to rest in the current state.
function portrait_hand_rest_y()
  local room_h = (G.ROOM and G.ROOM.T and G.ROOM.T.h) or G.TILE_H or 10
  local slide_offset = 3*((not G.deck_preview and (G.STATE == G.STATES.SELECTING_HAND or G.STATE == G.STATES.DRAW_TO_HAND)) and 1 or 0)
  return room_h - G.hand.T.h - get_hand_base_offset() - slide_offset
end

--After a style switch the hand has moved; put an open shop or blind select
--back where their builders would have. set_screen_positions leaves the hand
--short of its rest, and a panel placed from there ended 0.35 too low.
local function portrait_realign_box(box)
  if not (box and not box.REMOVED and box.alignment) then return end
  if box.align_to_major then box:align_to_major() end
  if box.hard_set_VT then box:hard_set_VT() end
end

function portrait_reflow_panels()
  if not G.F_PORTRAIT_LAYOUT or not G.hand then return end
  G.hand.T.y = portrait_hand_rest_y()
  if G.shop and not G.shop.REMOVED and G.shop.alignment and G.shop.alignment.offset and G.STATE == G.STATES.SHOP then
    G.shop.alignment.offset.y = portrait_shop_offset()
    portrait_realign_box(G.shop)
  end
  if G.blind_select and not G.blind_select.REMOVED and G.blind_select.alignment and G.blind_select.alignment.offset and G.STATE == G.STATES.BLIND_SELECT then
    G.blind_select.alignment.offset.y = portrait_blind_select_offset()
    portrait_realign_box(G.blind_select)
  end
end

--Leaving portrait previously restored panel offsets inside portrait_rebuild_HUD,
--before set_screen_positions put the hand and joker shelf back in landscape
--coordinates. The blind-select formula therefore used stale hand coordinates.
--Run this only after the card areas have their final landscape positions.
function portrait_restore_landscape_panels()
  if not (G and not G.F_PORTRAIT_LAYOUT) then return end

  if G.shop and not G.shop.REMOVED and G.shop.alignment then
    G.shop.alignment.offset.y = -5.3
    portrait_realign_box(G.shop)
  end
  if G.blind_select and not G.blind_select.REMOVED and G.blind_select.alignment and G.blind_select.alignment.offset and G.blind_select.T and G.hand and G.jokers then
    G.blind_select.alignment.offset.y = 0.8 - (G.hand.T.y - G.jokers.T.y) + G.blind_select.T.h
    portrait_realign_box(G.blind_select)
  end
  if G.round_eval and not G.round_eval.REMOVED and G.round_eval.alignment then
    G.round_eval.alignment.offset.y = -7.8
    portrait_realign_box(G.round_eval)
  end
  if G.HUD_tags and G.HUD_tags[1] then
    G.HUD_tags[1]:set_alignment({
      type = 'bri', offset = {x = 0.7, y = 0},
      xy_bond = 'Weak', major = G.ROOM_ATTACH
    })
    for _, tag in ipairs(G.HUD_tags) do
      portrait_realign_box(tag)
    end
  end
end

--Tags stack up from the corner under the joker shelf. Past the room left
--under the HUD (a short tablet room fits about seven) the rest go down from
--the first tag instead, so no tag ever sits on the HUD. Re-run whenever a tag
--comes or goes and when the shelves move.
function portrait_arrange_tags()
  if not (G.F_PORTRAIT_LAYOUT and G.HUD_tags and G.HUD_tags[1] and G.jokers and G.jokers.T) then return end
  local align, offset = get_portrait_first_tag_align()
  local tag_h = G.HUD_tags[1].T.h > 0 and G.HUD_tags[1].T.h or 0.9
  local first_top = G.jokers.T.y + G.jokers.T.h
  local limit = (G.HUD and not G.HUD.REMOVED and G.HUD.T) and (G.HUD.T.y + G.HUD.T.h + 0.1) or 0
  local up = math.max(1, math.floor((first_top + tag_h - limit) / tag_h))
  for k, box in ipairs(G.HUD_tags) do
    if k == 1 then
      box:set_alignment({type = align, offset = {x = offset.x, y = offset.y}, major = G.jokers, xy_bond = 'Weak'})
    elseif k <= up then
      box:set_alignment({type = 'tm', offset = {x = 0, y = 0}, major = G.HUD_tags[k - 1], xy_bond = 'Weak'})
    else
      box:set_alignment({type = 'bm', offset = {x = 0, y = 0}, major = G.HUD_tags[k == up + 1 and 1 or k - 1], xy_bond = 'Weak'})
    end
    box.alignment.prev_type = nil
  end
end

--Fold6 display classification uses LÖVE's DPI-scaled logical dimensions.
--The cover's short edge is below 600dp; the unfolded inner display's short
--edge is above it. Unlike w > h, the minimum dimension remains stable when the
--cover itself is switched to landscape or when the device rotates by 180°.
function portrait_fold6_is_inner_display(w, h)
  if not (love and love.system and love.system.getOS and love.system.getOS() == 'Android') then return false end
  if type(w) ~= 'number' or type(h) ~= 'number' then
    w, h = love.graphics.getDimensions()
  end
  return math.min(w, h) >= 600
end

--Request one sensor-locked orientation from SDL.
--The Fold6 SDLActivity patch selects the requested orientation from width/height
--and does not depend on the resizable flag. One setMode call is sufficient:
--LÖVE 11.5 recreates its SDL window and GL context on every setMode call, so
--the former false->true resizable toggle recreated the native window twice.
function portrait_request_android_orientation(mode)
  if not (love and love.system and love.system.getOS and love.system.getOS() == 'Android') then
    return true
  end
  if portrait_fold6_is_inner_display() then return true end

  local width, height = mode == 2 and 1280 or 720, mode == 2 and 720 or 1280
  local flags = {}
  local got_mode, _, _, current_flags = pcall(love.window.getMode)
  if got_mode and type(current_flags) == 'table' then
    for key, value in pairs(current_flags) do flags[key] = value end
  end
  flags.fullscreen = true
  flags.fullscreentype = 'desktop'
  flags.usedpiscale = true
  flags.resizable = true

  local started_at = love.timer.getTime()
  local ok, result = pcall(love.window.setMode, width, height, flags)
  if PORTRAIT_SWITCH_METRICS and PORTRAIT_SWITCH_METRICS.active then
    PORTRAIT_SWITCH_METRICS.orientation_request_ms = (love.timer.getTime() - started_at) * 1000
    PORTRAIT_SWITCH_METRICS.orientation_finished_at = love.timer.getTime()
  end
  if not ok or result == false then
    return false, tostring(result or 'Unable to set the Android window mode')
  end
  return true
end

--Capture the exact active run before rebuilding the scene after an orientation
--or portrait-layout change. This mirrors the rollback system's proven save_run
-- + copy_table sequence, but keeps the fresh snapshot queued as the normal run
-- save as well, so a process exit during the transition cannot fall back to an
-- older save.jkr.
function portrait_capture_run_for_layout_reload()
  if not (G and G.STAGE == G.STAGES.RUN and G.GAME and G.GAME.blind and G.GAME.selected_back) then
    return nil, 'The current scene is not an active run'
  end

  local capture_started_at = love.timer.getTime()
  G.ARGS = G.ARGS or {}
  local previous_save = G.ARGS.save_run
  local previous_culled = G.culled_table
  G.ARGS.save_run = nil
  G.culled_table = nil

  local ok, snapshot = pcall(function()
    save_run()
    if type(G.ARGS.save_run) ~= 'table' then
      error('save_run did not produce a fresh snapshot')
    end

    local saved = copy_table(G.ARGS.save_run)
    if type(saved) ~= 'table'
       or type(saved.GAME) ~= 'table'
       or type(saved.cardAreas) ~= 'table'
       or type(saved.BLIND) ~= 'table'
       or type(saved.BACK) ~= 'table'
       or saved.STATE == nil then
      error('The active run snapshot is incomplete')
    end
    return saved
  end)

  if PORTRAIT_SWITCH_METRICS and PORTRAIT_SWITCH_METRICS.active then
    PORTRAIT_SWITCH_METRICS.snapshot_ms = (love.timer.getTime() - capture_started_at) * 1000
  end
  if not ok or not snapshot then
    G.ARGS.save_run = previous_save
    G.culled_table = previous_culled
    if PORTRAIT_SWITCH_METRICS then
      PORTRAIT_SWITCH_METRICS.active = false
      PORTRAIT_SWITCH_METRICS.failed_stage = 'snapshot'
    end
    return nil, tostring(snapshot or 'Unable to capture the active run')
  end

  -- Keep the same fresh snapshot for the save thread and for start_run().
  G.ARGS.save_run = snapshot
  G.culled_table = snapshot
  G.FILE_HANDLER = G.FILE_HANDLER or {}
  G.FILE_HANDLER.run = true
  G.FILE_HANDLER.update_queued = true
  G.FILE_HANDLER.force = true
  return snapshot
end

--Re-enter the active run through Balatro's native load-from-save path. That
--path calls delete_run(), prep_stage(), creates new card areas/HUD/backdrop,
--then restores every saved CardArea, tag, blind and game state. The settings
--are already updated, so prep_stage/love.resize builds the new orientation.
function portrait_restart_scene_for_layout_change(snapshot)
  if not G then return false, 'Game state is unavailable' end

  if G.STAGE == G.STAGES.RUN then
    local err
    if not snapshot then snapshot, err = portrait_capture_run_for_layout_reload() end
    if not snapshot then return false, err end
    -- Keep the original game transition animation. Optimize only the
    -- pre-transition work (snapshot + Android surface/orientation wait).
    local metrics = PORTRAIT_SWITCH_METRICS
    local queued_at = love.timer.getTime()
    local ok, err = pcall(G.FUNCS.start_run, nil, {
      savetext = snapshot,
      from_portrait_layout = true
    })
    if metrics and metrics.active then
      metrics.restart_enqueue_ms = (love.timer.getTime() - queued_at) * 1000
      metrics.start_run_queued_at = love.timer.getTime()
    end
    if not ok then return false, tostring(err) end
    return true
  end

  if G.STAGE == G.STAGES.MAIN_MENU then
    -- No in-memory run exists on the main menu. Recreate the menu scene using
    -- the same transition as the vanilla Main Menu button; save.jkr is left
    -- untouched so Continue remains available.
    G.FUNCS.go_to_menu()
    return true
  end

  return false, 'This screen cannot be safely rebuilt from an active run save'
end

--Resize and realign the felt/background sprite when the logical room changes
--between portrait and the original landscape viewport. Its dimensions are
--fixed when start_run creates it, so changing only ROOM.T left old black bands
--or a cropped background behind the new layout.
function portrait_refresh_backdrop()
  local bg = G and G.SPLASH_BACK
  if not (bg and not bg.REMOVED and bg.T and G.ROOM and G.ROOM.T) then return end
  bg.T.w = G.ROOM.T.w + 60
  bg.T.h = G.ROOM.T.h + 22
  if bg.VT then
    bg.VT.w = bg.T.w
    bg.VT.h = bg.T.h
  end
  -- The main-menu backdrop covers the physical display, including the top
  -- inset. ROOM_ATTACH is shifted down to keep UI clear of the status area;
  -- cancel that shift only for the backdrop, not for the menu controls.
  if G.STAGE == G.STAGES.MAIN_MENU and G.ROOM_ATTACH and bg.alignment
     and bg.alignment.major == G.ROOM_ATTACH then
    bg.alignment.offset = bg.alignment.offset or {x = 0, y = 0}
    bg.alignment.offset.y = G.F_PORTRAIT_LAYOUT and -(G.ROOM_ATTACH.T.y or 0) or 0
  end
  if bg.align_to_major then bg:align_to_major() end
  if bg.hard_set_VT then bg:hard_set_VT() end
end

--One live-layout transaction for both display-direction changes and the
--Classic / One-Thumb / Focus selector. Rebuild the HUD first: One-Thumb's
--score dock and Focus's blind panel are created by their HUD builders. Only
--then place the card areas against the new HUD and rebuild the button bar.
function portrait_apply_live_layout()
  if not G then return end
  if G.STAGE == G.STAGES.RUN then
    portrait_rebuild_HUD()
    if set_screen_positions then set_screen_positions() end
    if G.F_PORTRAIT_LAYOUT then
      portrait_reflow_panels()
      portrait_arrange_tags()
    else
      portrait_restore_landscape_panels()
    end
    if G.buttons and rebuild_buttons_uibox then rebuild_buttons_uibox() end
  elseif G.STAGE == G.STAGES.MAIN_MENU then
    if G.MAIN_MENU_UI then G.MAIN_MENU_UI:remove(); G.MAIN_MENU_UI = nil end
    if G.PROFILE_BUTTON then G.PROFILE_BUTTON:remove(); G.PROFILE_BUTTON = nil end
    if G.LANGUAGE_BUTTON then G.LANGUAGE_BUTTON:remove(); G.LANGUAGE_BUTTON = nil end
    if set_main_menu_UI then set_main_menu_UI() end
  end
  portrait_refresh_backdrop()
end

--Sets the text of a row to config.text_scale once the box is built, for rows
--whose label line has to stay exactly as vanilla wrote it (another mod's
--Lovely patch anchors on that line).
G.FUNCS.portrait_text_scale = function(e)
  if e.config.text_scaled or not G.F_PORTRAIT_LAYOUT then return end
  for _, child in ipairs(e.children) do
    if child.UIT == G.UIT.T and child.config then child.config.scale = e.config.text_scale end
  end
  e.config.text_scaled = true
  portrait_relayout(e)
end

--A tutorial overlay is a dimming box centred on the room. Vanilla's carries
--a room-sized row, which makes it cover a portrait screen; a mod's built
--without one (Cryptid's intro: a 32-tile square) leaves the top of a tall
--room undimmed. Such a box is grown once to cover the whole screen.
--In portrait a tutorial stacks under its character: speech bubble, then the
--step's own panel (Cryptid's gameset pick), then the button. A panel hung
--off the character, as landscape lays it out, sat on the bubble; it goes
--under the bubble, and the button under the panel.
local function stack_tutorial(ot)
  local J = ot.Jimbo
  local sb = J and J.children and J.children.speech_bubble
  local content = ot.content
  if not (sb and content and not content.REMOVED) then return end
  if content.portrait_stacked ~= sb then
    content.portrait_stacked = sb
    content:set_alignment({major = sb, type = 'bm', offset = {x = 0, y = 0.15}})
    content.alignment.prev_type = nil
  end
  local button = J.children.button
  if button and not button.REMOVED and button.portrait_stacked ~= content then
    button.portrait_stacked = content
    button:set_alignment({major = content, type = 'bm', offset = {x = 0, y = 0.2}})
    button.alignment.prev_type = nil
  end
end

--A mod may put its own panel where the bubble now goes (Cryptid's gameset
--pick sits just under the screen's middle). Once the bubble is up, the
--character is lifted by whatever its bubble and button would cover of such a
--panel, once per bubble.
local function lift_tutorial(ot)
  local J = ot.Jimbo
  local sb = J and J.children and J.children.speech_bubble
  if not (sb and sb.states.visible and J.alignment and J.alignment.offset) or J.portrait_lifted_for == sb then return end
  J.portrait_lifted_for = sb
  local top = sb.T.y
  local bottom = sb.T.y + sb.T.h
  local button = J.children.button
  if button and not button.REMOVED and not ot.content then bottom = button.T.y + button.T.h end
  local own = {[sb] = true, [ot] = true}
  if ot.content then own[ot.content] = true end
  if button then own[button] = true end
  -- Buttons of another box drawn where the bubble and its button now go.
  local lift = 0
  local function walk(node)
    if node.states and node.states.visible == false then return end
    local c = node.config
    if c and c.button and node.T and node.T.w > 0
       and node.T.y < bottom + 0.15 and node.T.y + node.T.h > top
       and node.T.x < sb.T.x + sb.T.w and node.T.x + node.T.w > sb.T.x then
      lift = math.max(lift, bottom + 0.4 - node.T.y)
    end
    for _, child in pairs(node.children or {}) do
      if type(child) == 'table' and child.T and not child.UIRoot then walk(child) end
    end
  end
  for _, box in ipairs(G.I.UIBOX) do
    if not own[box] and not box.REMOVED and box.states.visible and box.UIRoot then walk(box.UIRoot) end
  end
  if lift > 0 then
    J:set_alignment({offset = {x = J.alignment.offset.x or 0, y = (J.alignment.offset.y or 0) - lift}})
  end
end

-- The stock Game:init_window creates WINDOWTRANS with only logical game
-- bounds. The Android/LÖVE resize callback may be deferred until the surface
-- settles, but update_canvas_juice reads real_window_w/h during the first
-- Game:update. Fill only missing values before entering the original update;
-- the stabilized resize path will replace them with the final dimensions.
local function portrait_ensure_real_window_dimensions()
  if not (G and G.WINDOWTRANS) then return end
  local width, height = love.graphics.getDimensions()
  if not G.WINDOWTRANS.real_window_w or G.WINDOWTRANS.real_window_w <= 0 then
    G.WINDOWTRANS.real_window_w = width
  end
  if not G.WINDOWTRANS.real_window_h or G.WINDOWTRANS.real_window_h <= 0 then
    G.WINDOWTRANS.real_window_h = height
  end

  -- The first Android resize may have fired before G.ROOM existed and was
  -- discarded by _portrait_apply_resize. update_canvas_juice runs before
  -- love.draw can consume a deferred resize, so seed the original room
  -- transform here and ask the draw path to apply the real viewport next.
  if G.ROOM and G.ROOM.T and not G.ROOM_ORIG then
    G.ROOM_ORIG = {
      x = G.ROOM.T.x or 0,
      y = G.ROOM.T.y or 0,
      r = G.ROOM.T.r or 0
    }
    if love.system.getOS() == 'Android' and not G.PORTRAIT_RESIZE_PENDING then
      G.PORTRAIT_RESIZE_PENDING = {
        w = width, h = height, stable_frames = 2
      }
    end
  end
end

local portrait_game_start_run = Game.start_run
function Game:start_run(args)
  local metrics = PORTRAIT_SWITCH_METRICS
  local is_layout_reload = args and args.from_portrait_layout and metrics and metrics.active
  local started_at = is_layout_reload and love.timer.getTime() or nil
  if is_layout_reload then
    metrics.queue_to_start_run_ms = (started_at - (metrics.start_run_queued_at or started_at)) * 1000
  end
  portrait_game_start_run(self, args)
  if is_layout_reload then
    metrics.game_start_run_ms = (love.timer.getTime() - started_at) * 1000
    metrics.game_start_run_finished_at = love.timer.getTime()
    metrics.awaiting_first_frame = true
  end
end

local portrait_game_update = Game.update
function Game:update(dt)
  portrait_ensure_real_window_dimensions()
  portrait_game_update(self, dt)
  local switch_metrics = PORTRAIT_SWITCH_METRICS
  if switch_metrics and switch_metrics.awaiting_first_frame
     and G.STAGE == G.STAGES.RUN and G.HUD and G.HUD_blind then
    switch_metrics.first_frame_total_ms = (love.timer.getTime() - switch_metrics.started_at) * 1000
    switch_metrics.completed_at = love.timer.getTime()
    switch_metrics.awaiting_first_frame = nil
    switch_metrics.active = false
  end
  -- A cover orientation change is asynchronous. Wait until Android has
  -- delivered the target aspect ratio and the resize debounce has completed,
  -- then rebuild the scene from the snapshot captured before requesting it.
  local pending_layout = G.PORTRAIT_LAYOUT_RELOAD_PENDING
  if pending_layout then
    local w, h = love.graphics.getDimensions()
    local target_reached = pending_layout.mode == 2 and w > h or pending_layout.mode ~= 2 and h > w
    if target_reached and not G.PORTRAIT_RESIZE_PENDING then
      if pending_layout.last_w == w and pending_layout.last_h == h then
        pending_layout.stable_frames = (pending_layout.stable_frames or 0) + 1
      else
        pending_layout.last_w, pending_layout.last_h = w, h
        pending_layout.stable_frames = 1
      end
    else
      pending_layout.stable_frames = 0
      pending_layout.last_w, pending_layout.last_h = w, h
    end

    local scene_ready = G.STAGE == G.STAGES.RUN or G.STAGE == G.STAGES.MAIN_MENU
    if pending_layout.stable_frames >= 2 and scene_ready then
      G.PORTRAIT_LAYOUT_RELOAD_PENDING = nil
      if switch_metrics and switch_metrics.active then
        switch_metrics.surface_wait_ms = (love.timer.getTime() - (switch_metrics.orientation_finished_at or pending_layout.started_at)) * 1000
      end
      local ok, err = portrait_restart_scene_for_layout_change(pending_layout.snapshot)
      if not ok then
        G.SETTINGS.portrait_display_mode = pending_layout.previous_mode
        G:save_settings()
        pcall(portrait_request_android_orientation, pending_layout.previous_mode)
        print('PORTRAIT LAYOUT RELOAD ABORTED: ' .. tostring(err))
      end
    elseif love.timer.getTime() - pending_layout.started_at > 10 then
      G.PORTRAIT_LAYOUT_RELOAD_PENDING = nil
      G.SETTINGS.portrait_display_mode = pending_layout.previous_mode
      G:save_settings()
      pcall(portrait_request_android_orientation, pending_layout.previous_mode)
      print('PORTRAIT ORIENTATION CHANGE TIMED OUT; previous mode restored')
    end
  end

  -- A Fold6 cover/inner transition changes the Android configuration class.
  -- Re-enter the same saved run after the new surface dimensions have settled.
  if G.PORTRAIT_FOLD_RELOAD_PENDING
     and not G.PORTRAIT_LAYOUT_RELOAD_PENDING
     and not G.PORTRAIT_RESIZE_PENDING
     and (G.STAGE == G.STAGES.RUN or G.STAGE == G.STAGES.MAIN_MENU) then
    G.PORTRAIT_FOLD_RELOAD_PENDING = nil
    local ok, err = portrait_restart_scene_for_layout_change()
    if not ok then
      G.PORTRAIT_FOLD_RELOAD_PENDING = true
      print('FOLD DISPLAY RELOAD DEFERRED: ' .. tostring(err))
    end
  end
  local ot = G.OVERLAY_TUTORIAL
  if G.F_PORTRAIT_LAYOUT and ot and not ot.REMOVED then
    stack_tutorial(ot)
    lift_tutorial(ot)
  end
  if G.F_PORTRAIT_LAYOUT and ot and not ot.REMOVED and not ot.portrait_covered and ot.UIRoot and G.ROOM and G.ROOM.T then
    ot.portrait_covered = true
    local need_h = G.ROOM.T.h + 2 * (math.abs(ot.alignment and ot.alignment.offset and ot.alignment.offset.y or 0) + 2)
    if ot.T.h < need_h then
      ot.UIRoot.config.minh = need_h
      ot.UIRoot.config.minw = math.max(ot.T.w, G.ROOM.T.w + 4)
      ot:recalculate()
    end
  end

  -- Final pass after the original update, resize handling and all portrait
  -- layout work. Some late UI initialization paths can restore a stale x.
  if G.F_PORTRAIT_LAYOUT and G.HUD and portrait_position_run_hud then
    portrait_position_run_hud(G.HUD)
  end
end

--Steamodded's badge is made 4.4 tiles wide and, to make room for it, eases the
--HUD down: right for the desktop HUD, but a portrait blind panel is narrower
--and the portrait HUD is placed by hand. The badge is held to its panel's
--width and slimmer, and the HUD stays where it is.
local function wrap_smods_badge()
  if not G.FUNCS.HUD_blind_badge or G.FUNCS.portrait_badge_wrapped then return end
  local smods_badge = G.FUNCS.HUD_blind_badge
  G.FUNCS.portrait_badge_wrapped = true
  G.FUNCS.HUD_blind_badge = function(e)
    local had = e.children[1]
    local panel = G.HUD_blind
    smods_badge(e)
    -- Leaving a modded blind, Steamodded builds the blind panel anew; its
    -- debuff lines get their portrait func, as start_run gives them.
    if G.HUD_blind ~= panel and G.HUD_blind then
      for _, id in ipairs({'HUD_blind_debuff_1', 'HUD_blind_debuff_2'}) do
        local node = G.HUD_blind:get_UIE_by_ID(id)
        if node then node.config.func = 'portrait_HUD_blind_debuff' end
      end
      if G.hand_text_area then G.hand_text_area.blind_chips = G.HUD_blind:get_UIE_by_ID('HUD_blind_count') end
      return
    end
    local badge = e.children[1]
    if G.F_PORTRAIT_LAYOUT and badge and badge ~= had and e.UIBox and e.UIBox.T then
      local max_w = e.UIBox.T.w - 0.2
      local function clamp(node)
        if node.config and node.config.minw and node.config.minw > max_w then node.config.minw = max_w end
        if node.config then node.config.maxw = math.min(node.config.maxw or max_w, max_w) end
        for _, child in pairs(node.children or {}) do if type(child) == 'table' and child.config then clamp(child) end end
      end
      clamp(badge)
      e.config.minh = 0.38
      e.UIBox:recalculate()
    end
  end
end
portrait_wrap_smods_badge = wrap_smods_badge

local game_ease_value = ease_value
function ease_value(ref_table, ...)
  if G.F_PORTRAIT_LAYOUT and G.HUD and G.HUD.alignment and ref_table == G.HUD.alignment.offset then return end
  return game_ease_value(ref_table, ...)
end
