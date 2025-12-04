pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- main
-- Main game loop and state

-- #include cards.lua
-->8
-- cards
-- Card manipulation, shuffling, and movement logic

function shuffle(st)
 if st == nil then
  st = sts.sto
 end
 local tmp = 0
 local i = #st
 local j = 0
 while i >= 2 do
  j = rnd(i)\1 + 1
  tmp = st[i]
  st[i] = st[j]
  st[j] = tmp
  i -= 1
 end
end

function mv_cards(from,to,cnt)
 --move cnt cards from->to
 --maintains order (top to top)
 cnt = cnt or 1
 local start = #from - cnt + 1
 for i=start,#from do
  if from[i] then
   add(to, from[i])
  end
 end
 --remove from source
 for i=1,cnt do
  del(from, from[#from])
 end
end

function deal_sto()
 --deal 3 cards from stock to waste
 local to_deal = min(3, #sts.sto)
 if to_deal > 0 then
  mv_cards(sts.sto, sts.waste, to_deal)
 end
end

function deal_cards()
 --start dealing animation
 anim.active = true
 anim.tbl_i = 1
 anim.card_i = 0
 anim.timer = 0
end

function update_deal()
 --update dealing animation
 if not anim.active then
  return --deal not active
 end
 
 anim.timer += 1
 if anim.timer < anim.delay then
  return --wait for next card
 end
 
 anim.timer = 0--reset timer
 anim.card_i += 1
 
 if anim.card_i > anim.tbl_i then
  --move to next tableau column
  anim.tbl_i += 1
  anim.card_i = 1
  
  if anim.tbl_i > 7 then
   --dealing complete
   anim.active = false
  end
 end
 
 if anim.active then
  --move card from stock to tableau
  mv_cards(sts.sto, sts.tbl[anim.tbl_i], 1)
 else
  --dealing complete, no more animation
  anim.active = false
 end
end
-- #include validators.lua
-->8
-- validators
-- Move validation logic for all game areas

function valid_pair(lower, upper)
 --check if upper on lower is valid
 --lower has higher index in stack
 if not lower or not upper then
  return false
 end
 --upper rank must be 1 less
 if upper.r != lower.r - 1 then
  return false
 end
 --colors must alternate
 local ub = (upper.s & 1) == 1
 local lb = (lower.s & 1) == 1
 return ub != lb
end

--todo: check if counterpart makes obsolete
function valid_seq(cards, start_i, count)
 --check sequence validity
 if not cards or count < 2 then
  return false
 end
 start_i = start_i or #cards
 local end_i = max(1, start_i - count + 1)
 
 for i = start_i, end_i + 1, -1 do
  local upper = cards[i]
  local lower = cards[i-1]
  if not valid_pair(lower, upper) then
   return false
  end
 end
 return true
end

function valid_tablu(st, cnt)
 --backwards compat wrapper
 return valid_seq(st, #st, cnt)
end

function valid_fnd(fnd,c)
 --check if card c can go on fnd
 if #fnd == 0 then
  --empty foundation
  return c.r == RA --ace only
 elseif #fnd == 1 then
  --ace on fnd, need 2
  local top = fnd[#fnd]
  return c.s == top.s and c.r == R2
 else
  --normal sequence
  local top = fnd[#fnd]
  return c.s == top.s and
         c.r == top.r + 1
 end
end

function can_grab_sto()
 --can we grab from stock position?
 --only when 1 card (empty slot mode)
 return #sts.sto == 1
end

function can_place_sto()
 --can we place on stock position?
 --only when empty & holding 1 card
 return #sts.sto == 0 and #held == 1
end

function can_grab_here()
 --check if can grab from cur pos
 if crs.area == "top" then
  if crs.top_pos == 1 then
   --stock: either deal or grab single
   return #sts.sto >= 1
  elseif crs.top_pos == 2 then
   --waste: can grab if has cards
   return #sts.waste > 0
  else
   --foundation: can grab top card
   local fi = crs.top_pos - 2
   return #sts.fnd[fi] > 0
  end
 elseif crs.area == "tbl" then
  --tableau: check valid sequence
  local tbl = sts.tbl[crs.tbl_i]
  if #tbl == 0 then
   return false
  end
  return valid_tablu(tbl, crs.sel_cnt)
 end
 return false
end

function can_place_tbl(ti)
 --can place held on tableau ti?
 if #held == 0 then
  return false
 end
 local tbl = sts.tbl[ti]
 if #tbl == 0 then
  return true --empty accepts any
 end
 --check bottom held vs top tbl
 local top_card = tbl[#tbl]
 local bot_card = held[1]
 
 return valid_pair(top_card, bot_card)
end

function can_place_fnd(fi)
 --check if can place on foundation
 if #held != 1 then
  return false --only single cards
 end
 return valid_fnd(sts.fnd[fi], held[1])
end
-- #include renderers.lua
-->8
-- renderers
-- All rendering and drawing functions

function spr_card(rank,suit,x,y)
 --draws 2x3 card sprite
 --rank:R2-RA,suit:HRT,SPD,DIA,CLB
 
 local blk = suit&1==1
 local rtop = blk and 32 or 0
 local rbot = blk and 48 or 16
 
 local sbase = blk and 32 or 0
 if suit>1 then sbase+=1 end
 
 -- 2x3 sp/rite layout:
 -- [r][s] top
 -- [15][31] mid
 -- [s][r] bot
 
 spr(rtop+rank, x,   y)
 spr(sbase,     x+8, y)
 spr(15,        x,   y+8)
 spr(31,        x+8, y+8)
 spr(sbase+16,  x,   y+16)
 spr(rbot+rank, x+8, y+16)
end

function rend_card_st(cards,x,y,dy)
 --render vertical stack of cards
 --dy = vertical offset per card
 if not cards then return end
 dy = dy or CARD_STACK_DY
 for i=1,#cards do
  local c = cards[i]
  spr_card(c.r, c.s, x, y+(i-1)*dy)
 end
end

function rend_waste_cards(cards,x,y)
 --render waste pile (max 3 visible)
 if not cards or #cards == 0 then
  return
 end
 local start = max(1, #cards - 2)
 for i = start, #cards do
  local c = cards[i]
  local dx = (i - start) * WASTE_DX
  spr_card(c.r, c.s, x + dx, y)
 end
end

function rend_held_cards(cards,x,y)
 --render cards being held/moved
 if not cards or #cards == 0 then
  return
 end
 -- offset for visibility
 rend_card_st(cards, x-4, y-4)
end

function rend_dialog(msg,x,y,frames)
 --render timed dialog message
 if frames > 0 then
  print(msg, x, y, 14)
 end
end

function spr_st(st)
 --
 if st == nil then
	st = sts.sto
 end
 x = 0
 y = 0 
 for c in all(st) do
	if x >= 128 then
	 x = 0
	 y = y + 24
	end			
	if y >= 128 then
	 y = 8
	end
	spr_card(c.r,c.s,x,y)
	x += 16
 end
end

function spr_sto(is_sto)
 --Draw stock area sprite
 local p = {2, 2}
 if is_sto then
  --draw card back for stock
  sspr(0,32,16,24,p[1],p[2])
 else
  --draw empty slot marker
  sspr(16,32,16,24,p[1],p[2])
 end
end

function sprfnd(n)
 --draw 2x3 sprs for
 --found stack markers
 --param n is num of ace mark
 local pad = 2
 local offs= (pad + 16) * n
 local p = {56+offs, 2}
 sspr(16,32,16,24,p[1],p[2])
end

function sprtbl(n)
 --draw 2x3 sprs for...
 --...frecell markings (0..6)
 local marg = 2 --margin to scr
 local pad = 2 --between marks 
 local posx = marg
 local posy = TABLU_Y --all marks
 posx += (n * (pad + 16))
 sspr(16,32,16,24,posx,posy)
end

function spr_init_board()
 if #sts.sto > 1 then
  --multiple cards = stock
  spr_sto(true)
 elseif #sts.sto == 1 then
  --single card placed here
  local c = sts.sto[1]
  spr_card(c.r, c.s, 2, 2)
 else
  --empty slot
  spr_sto(false)
 end
 for i=0,3 do
  sprfnd(i)
 end
 for i=0,6 do
  sprtbl(i)
 end
end

function rend_crs()
 --TODO: replace rect with
 --cursor sprite when avail.
 --draws expanding cursor
 local x, y = get_crs_pos()
 local color = 9 -- orange
 if crs.selected then --if selct
  color = 2 --...d.purple
 end
 local h = 23 -- base height
 if crs.area == "tbl" then
  --expand height for selection
  h += (crs.sel_cnt-1) << 3
 end
 rect(x, y, x+15, y+h, color)
end

function get_crs_pos()
 if crs.area == "top" then
  if crs.top_pos == 1 then
   -- stock position
   return 2, 2
  elseif crs.top_pos == 2 then
   --waste pos. (next to stock)
   local waste_cnt = #sts.waste
   local x_offset = 0
   if waste_cnt >= 3 then
    x_offset = 16
   elseif waste_cnt == 2 then
    x_offset = 8
   end
   return 20 + x_offset, 2
  else
   -- foundation position
   -- (3-6 to foundations 1-4)
   local fnd_i = crs.top_pos - 2
   local pad = 2
   local offs = (pad+16) * (fnd_i - 1)
   return 56 + offs, 2
  end
 elseif crs.area == "tbl" then
  -- tableau position
  local x = 2 + (crs.tbl_i-1) * 18
  local tbl = sts.tbl[crs.tbl_i]
  local y = TABLU_Y
  if #tbl > 0 then
   --adj. y for stack height
   local card_i = #tbl - crs.sel_cnt + 1
   card_i = max(1, card_i)
   y = y + (card_i - 1) * 8
  end
  return x, y
 end
 return 0, 0
end
-- #include auto_move.lua
-->8
-- auto_move
-- Automatic card movement to foundations

function can_auto_move(c)
 --check if card can safely auto-move
 --to foundation per conservative rules
 if c.r == RA then
  return true --aces always safe
 elseif c.r == R2 then
  --2s safe when ace in foundation
  local fnd_i = 4 - c.s
  return #sts.fnd[fnd_i] >= 1
 else
  --3-K: need both opp color rank-1
  local need_r = c.r - 1
  local is_red = (c.s & 1) == 1
  local found_opp = 0
  
  for i=1,4 do
   local fnd = sts.fnd[i]
   if #fnd >= need_r then
    --fnd order: C,D,S,H = suits 3,2,1,0
    local fnd_suit = 4 - i
    local fnd_red = (fnd_suit & 1) == 1
    if fnd_red != is_red then
     found_opp += 1
    end
   end
  end
  
  return found_opp >= 2
 end
end

function check_auto_moves()
 --scan accessible cards for auto-moves
 --only when no cards held
 if #held > 0 then return end
 
 --check waste top
 if #sts.waste > 0 then
  local c = sts.waste[#sts.waste]
  --map suit to fnd: H,S,D,C -> 4,3,2,1
  local fnd_i = 4 - c.s
  if can_auto_move(c) and 
     valid_fnd(sts.fnd[fnd_i], c) then
   mv_cards(sts.waste, sts.fnd[fnd_i], 1)
   local suits = {"C","D","S","H"}
   ui_msg = "auto-moved " .. c.r .. 
            suits[c.s+1]
   ui_msg_timer = 30
   return --one move per frame
  end
 end
 
 --check single stock
 if #sts.sto == 1 then
  local c = sts.sto[1]
  local fnd_i = 4 - c.s
  if can_auto_move(c) and 
     valid_fnd(sts.fnd[fnd_i], c) then
   mv_cards(sts.sto, sts.fnd[fnd_i], 1)
   local suits = {"C","D","S","H"}
   ui_msg = "auto-moved " .. c.r .. 
            suits[c.s+1]
   ui_msg_timer = 30
   return
  end
 end
 
 --check tableau tops
 for i=1,7 do
  local tbl = sts.tbl[i]
  if #tbl > 0 then
   local c = tbl[#tbl]
   local fnd_i = 4 - c.s
   if can_auto_move(c) and 
      valid_fnd(sts.fnd[fnd_i], c) then
    mv_cards(tbl, sts.fnd[fnd_i], 1)
    local suits = {"C","D","S","H"}
    ui_msg = "auto-moved " .. c.r .. 
             suits[c.s+1]
    ui_msg_timer = 30
    return
   end
  end
 end
end
-- #include input.lua
-->8
-- input
-- Cursor control and input handling

--TODO: refactor grab/place functions
--most grab_* functions do: mv_cards(src, held, cnt); held_from = src
--most place_* functions do: mv_cards(held, dest, #held); held = {}; held_from = nil
--could be generalized to reduce redundant logic

function update_crs()
 -- handle cursor movement w/ dpad
 if btnp(0) then -- left
  move_crs_left()
 elseif btnp(1) then -- right
  move_crs_right()
 elseif btnp(2) then -- up
  move_crs_up()
 elseif btnp(3) then -- down
  move_crs_down()
 end
 
 -- handle grab/place buttons
 if btnp(4) then -- O button
  if #held == 0 then
   -- grabbing
   if crs.area == "top" then
    grab_from_top() --handles stock/waste/fnd
   elseif crs.area == "tbl" then
    grab_from_tbl()
   end
  else
   -- placing
   if crs.area == "top" then
    if not place_on_top() then
     ui_msg = "can't place here"
     ui_msg_timer = 30
    end
   elseif crs.area == "tbl" then
    if can_place_tbl(crs.tbl_i) then
     place_on_tbl(crs.tbl_i)
    else
     ui_msg = "can't place here"
     ui_msg_timer = 30
    end
   else
    --TODO: better invalid gfx
    ui_msg = "can't place here"
    ui_msg_timer = 30 --1 second
   end
  end
 elseif btnp(5) then -- X button
  if #held > 0 and held_from then
   --return held cards to source
   for i=1,#held do
    add(held_from, held[i])
   end
   held = {}
   held_from = nil
  end
 end
end

function move_crs_left()
 if crs.area == "tbl" then
  crs.tbl_i -= 1
  if crs.tbl_i < 1 then
   crs.tbl_i = 7 --wrap to rightmost
  end
  local tbl = sts.tbl[crs.tbl_i]
  crs.sel_cnt = 1
 elseif crs.area == "top" then
  crs.top_pos -= 1
  --skip empty waste (pos 2)
  if crs.top_pos == 2 and
     #sts.waste == 0 then
   crs.top_pos = 1
  end
  if crs.top_pos < 1 then
   crs.top_pos = 6 --wrap to rightmost
  end
 end
end

function move_crs_right()
 if crs.area == "tbl" then
  crs.tbl_i += 1
  if crs.tbl_i > 7 then
   crs.tbl_i = 1 --wrap to leftmost
  end
  local tbl = sts.tbl[crs.tbl_i]
  crs.sel_cnt = 1
 elseif crs.area == "top" then
  crs.top_pos += 1
  --skip empty waste (pos 2)
  if crs.top_pos == 2 and
     #sts.waste == 0 then
   crs.top_pos = 3
  end
  if crs.top_pos > 6 then
   crs.top_pos = 1 --wrap to leftmost
  end
 end
end

function move_crs_up()
 if crs.area == "tbl" then
  local tbl=sts.tbl[crs.tbl_i]
  if #tbl == 0 then
   crs.area = "top"
   --map empty tbl to nearest
   if crs.tbl_i == 1 then
    crs.top_pos = 1 -- 1→stock
   elseif crs.tbl_i <= 3 then
    crs.top_pos = 2 -- 2,3→waste
   else
    crs.top_pos = crs.tbl_i - 1 -- 4→3,5→4,6→5,7→6
   end
  elseif #held == 0 then
   --try to expand selection (only when not holding)
   local new_cnt=crs.sel_cnt+1
   if new_cnt <= #tbl and 
      valid_tablu(tbl,new_cnt) 
   then
    crs.sel_cnt = new_cnt
   else
    --can't expand,move to top
    crs.area = "top"
    --map tbl to nearest top pos
    if crs.tbl_i == 1 then
     crs.top_pos = 1 -- 1→stock
    elseif crs.tbl_i <= 3 then
     crs.top_pos = 2 -- 2,3→waste
    else
     crs.top_pos = crs.tbl_i - 1 -- 4→3,5→4,6→5,7→6
    end
    crs.sel_cnt = 1
   end
  else
   --holding cards, go to top
   crs.area = "top"
   --same mapping when holding
   if crs.tbl_i == 1 then
    crs.top_pos = 1 -- 1→stock
   elseif crs.tbl_i <= 3 then
    crs.top_pos = 2 -- 2,3→waste
   else
    crs.top_pos = crs.tbl_i - 1 -- 4→3,5→4,6→5,7→6
   end
   crs.sel_cnt = 1
  end
 elseif crs.area == "top" then
  --wrap to tableau bottom
  crs.area = "tbl"
  --map top to nearest tbl
  if crs.top_pos == 1 then
   crs.tbl_i = 1 -- stock→1
  elseif crs.top_pos == 2 then
   crs.tbl_i = 2 -- waste→2
  else
   crs.tbl_i = crs.top_pos + 1 -- 3→4,4→5,5→6,6→7
  end
  crs.sel_cnt = 1
 end
end

function move_crs_down()
 --TODO: map waste->tbl2 when waste<3 cards
 --would be closer visually 
 if crs.area == "top" then
  crs.area = "tbl"
  -- map top pos to closest tbl
  if crs.top_pos == 1 then
   crs.tbl_i = 1 -- stock→1
  elseif crs.top_pos == 2 then
   crs.tbl_i = 2 -- waste→2 (or 3)
  else
   crs.tbl_i = crs.top_pos + 1 -- 3→4,4→5,5→6,6→7
  end
  local tbl = sts.tbl[crs.tbl_i]
  crs.sel_cnt = 1
 elseif crs.area == "tbl" then
  local tbl = sts.tbl[crs.tbl_i]
  if #tbl == 0 or crs.sel_cnt == 1 then
   --wrap to top when at bottom
   crs.area = "top"
   --map tbl to nearest top pos
   if crs.tbl_i == 1 then
    crs.top_pos = 1 -- 1→stock
   elseif crs.tbl_i <= 3 then
    crs.top_pos = 2 -- 2,3→waste
   else
    crs.top_pos = crs.tbl_i - 1 -- 4→3,5→4,6→5,7→6
   end
   crs.sel_cnt = 1
  else
   --reduce selection
   crs.sel_cnt -= 1
  end
 end
end

-- Grab functions
function grab_deal_sto()
 if #sts.sto > 1 then
  deal_sto()
 else
  mv_cards(sts.sto, held, 1)
  held_from = sts.sto
 end
end

--DELETEME: temp testing function
function grab_waste()
 mv_cards(sts.waste, held, 1)
 held_from = sts.waste
end

function grab_from_tbl()
 local tbl = sts.tbl[crs.tbl_i]
 mv_cards(tbl, held, crs.sel_cnt)
 held_from = tbl
 crs.sel_cnt = 1 --reset selection
end

function grab_from_fnd(fi)
 --grab top card from foundation fi
 --TODO: optimize grab_* funcs
 local fnd = sts.fnd[fi]
 mv_cards(fnd, held, 1)
 held_from = fnd
end

function grab_from_top()
 --handle all top area grabs
 if crs.top_pos == 1 then
  grab_deal_sto()
  return
 end
 
 if crs.top_pos == 2 then
  if #sts.waste > 0 then
   grab_waste()
  end
  return
 end
 
 --foundation (pos 3-6)
 local fi = crs.top_pos - 2
 if #sts.fnd[fi] > 0 then
  grab_from_fnd(fi)
 end
end

-- Place functions
function place_on_stock()
 mv_cards(held, sts.sto, #held)
 held = {}
 held_from = nil
end

function place_on_tbl(ti)
 --TODO: optimize place_* funcs
 --lots of duplicate logic
 local tbl = sts.tbl[ti]
 mv_cards(held, tbl, #held)
 held = {}
 held_from = nil
end

function place_on_fnd(fi)
 --TODO: optimize place_* funcs
 local fnd = sts.fnd[fi]
 mv_cards(held, fnd, #held)
 held = {}
 held_from = nil
end

function place_on_top()
 --handle all top area placements
 if crs.top_pos == 1 then
  if can_place_sto() then
   place_on_stock()
   return true
  end
  return false
 end
 
 if crs.top_pos == 2 then
  return false --can't place on waste
 end
 
 --foundation (pos 3-6)
 local fi = crs.top_pos - 2
 if can_place_fnd(fi) then
  place_on_fnd(fi)
  return true
 end
 return false
end

-- layout constants
TABLU_Y = 28 --yofset tablu part
CARD_STACK_DY = 8 --card stack offset
WASTE_DX = 8 --waste card x offset

-- ui messages
ui_msg = ""
ui_msg_timer = 0

--TODO: implement deeper undo system
--options:
--1. move-based: store inverse operations
--   {type="grab",src=waste,cnt=1} etc.
--   pros: tiny memory, cons: complex logic
--2. state snapshots: 3-5 full board states  
--   pros: simple, cons: more memory
--question: does multi-undo make game too easy?

--TODO: mouse support
--detect mouse movement in play field
--switch to mouse mode until btn pressed
--show mouse cursor sprite in mouse mode
--hide rect cursor in mouse mode
--implement drag/drop using held[] state

--TODO: pause menu & instructions
--basic rules of kabafuda
--input controls explanation
--restart option in pause menu

--TODO: satisfying game ending
--animate cards leaving foundations
--auto-restart after win
--restart option accessible anytime

function _init()
 xoff_card = 16
 yoff_card = 24

 palt(0, false) -- render black
 palt(3, true)  -- d.grn transp.
 cls(3)         -- clear d.grn
 -- setup play board
 init_gm()
 shuffle()
 
 -- start dealing animation
 deal_cards()
 
 spr_init_board()
end

function _update()
 update_deal()
 -- only allow cursor movement
 -- ...after dealing is complete
 if not anim.active then
  update_crs()
 end
 
 -- update ui message timer
 if ui_msg_timer > 0 then
  ui_msg_timer -= 1
 end
 
 -- check for auto-moves
 if not anim.active then
  check_auto_moves()
 end
end

function _draw()
 cls(3) -- clear to dark green
 spr_init_board()--redraw board each frame
 
 -- draw dealt cards in tableaux
 for i=1,7 do
  local tbl = sts.tbl[i]
  local x = 2 + (i-1) * 18
  rend_card_st(tbl, x, TABLU_Y)
 end
 
 -- draw foundation cards
 for i=1,4 do
  local fnd = sts.fnd[i]
  if #fnd > 0 then
   local c = fnd[#fnd]--top card
   local pad = 2
   local offs= (pad + 16) * (i-1)
   local x = 56 + offs
   local y = 2
   spr_card(c.r, c.s, x, y)
  end
 end
 
 -- render top 3 waste cards
 rend_waste_cards(sts.waste, 20, 2)
 
 -- show stock count
 if #sts.sto > 1 then
  print(#sts.sto, 6, 8, 7)
 end
 
 -- show waste count
 if #sts.waste > 0 then
  print(#sts.waste, 22, 10, 1)
 end

 -- draw cursor
 rend_crs()
 
 -- render held cards
 if #held > 0 then
  local x, y = get_crs_pos()
  rend_held_cards(held, x, y)
 end

 -- render ui messages
 rend_dialog(ui_msg, 0, 120, ui_msg_timer)

end

-->8
-- state

-- suit constants (0-based for sprites)
HRT, SPD, DIA, CLB = 0,1,2,3

-- rank constants  
R2,R3,R4,R5,R6 = 2,3,4,5,6
R7,R8,R9,R10 = 7,8,9,10
RJ,RQ,RK,RA = 11,12,13,14

-- cursor state
crs = {--vvv--(stock/waste/foundations)
 area = "tbl",--tbl|top ^^^
 tbl_i = 1,   --which tableau(1-7)
 sel_cnt = 1, --cards selected from top
 top_pos = 1, --1=stock, 2=waste, 3-6=foundations
 selected = false--card sel?
}

sts = {}
held = {} -- cards being held
held_from = nil -- source stack
anim = {
 active = false,
 tbl_i = 1, --curr. tableau (1-based)
 card_i = 0,--curr. card in tableau
 timer = 0, --animation timer
 delay = 1  --frames btwn deals 
}

function init_gm()
 --(re)init stacks global state
 sts = {
  sto = {},
  waste = {},
  fnd = {{}, {}, {}, {}},
  tbl={{},{},{},{},{},{},{}}
 }
 
 --populate stock w/ all cards
 for s=HRT,CLB do
  for r=R2,RA do
   add(sts.sto, {r=r, s=s})
  end
 end
end

__gfx__
55555533555555333355555533555555335555553355555533555555335555553355555533555555335555553355555533555555335555553355555557777777
77777753777777533577777735777777357777773577777735777777357777773577777735777777357777773577777735777777357777773577777757777777
78878875777877755788877757888777578787775788877757877777578887775788877757888777578788875788877757787777578787775778777757777777
78888875778887755777877757778777578787775787777757877777577787775787877757878777578787875778777757878777578787775787877757777777
78888875788888755788877757788777578887775788877757888777577787775788877757888777578787875778777757878777578877775787877757777777
77888775778887755787777757778777577787775777877757878777577787775787877757778777578787875778777757887777578787775788877757777777
77787775777877755788877757888777577787775788877757888777577787775788877757778777578788875788777757788777578787775787877757777777
77777775777777755777777757777777577777775777777757777777577777775777777757777777577777775777777757777777577777775777777757777777
57777777577777777777777577777775777777757777777577777775777777757777777577777775777777757777777577777775777777757777777577777775
57887887577787777778887577788875777878757778887577787775777888757778887577788875787888757778887577778775777878757777877577777775
57888887577888777777787577777875777878757778777577787775777778757778787577787875787878757777877577787875777878757778787577777775
57888887578888877778887577778875777888757778887577788875777778757778887577788875787878757777877577787875777887757778787577777775
57788877577888777778777577777875777778757777787577787875777778757778787577777875787878757777877577788775777878757778887577777775
57778777577787777778887577788875777778757778887577788875777778757778887577777875787888757778877577778875777878757778787577777775
35777777357777777777775377777753777777537777775377777753777777537777775377777753777777537777775377777753777777537777775377777775
33555555335555555555553355555533555555335555553355555533555555335555553355555533555555335555553355555533555555335555553377777775
55555533555555333355555533555555335555553355555533555555335555553355555533555555335555553355555533555555335555553355555500000000
77777753777777533577777735777777357777773577777735777777357777773577777735777777357777773577777735777777357777773577777700000000
77707775770007755700077757000777570707775700077757077777570007775700077757000777570700075700077757707777570707775770777700000000
77000775700000755777077757770777570707775707777757077777577707775707077757070777570707075770777757070777570707775707077700000000
70000075700000755700077757700777570007775700077757000777577707775700077757000777570707075770777757070777570077775707077700000000
70070075777077755707777757770777577707775777077757070777577707775707077757770777570707075770777757007777570707775700077700000000
77707775770007755700077757000777577707775700077757000777577707775700077757770777570700075700777757700777570707775707077700000000
77777775777777755777777757777777577777775777777757777777577777775777777757777777577777775777777757777777577777775777777700000000
57777777577777777777777577777775777777757777777577777775777777757777777577777775777777757777777577777775777777757777777500000000
57770777577000777770007577700075777070757770007577707775777000757770007577700075707000757770007577770775777070757777077500000000
57700077570000077777707577777075777070757770777577707775777770757770707577707075707070757777077577707075777070757770707500000000
57000007570000077770007577770075777000757770007577700075777770757770007577700075707070757777077577707075777007757770707500000000
57007007577707777770777577777075777770757777707577707075777770757770707577777075707070757777077577700775777070757770007500000000
57770777577000777770007577700075777770757770007577700075777770757770007577777075707000757770077577770075777070757770707500000000
35777777357777777777775377777753777777537777775377777753777777537777775377777753777777537777775377777753777777537777775300000000
33555555335555555555553355555533555555335555553355555533555555335555553355555533555555335555553355555533555555335555553300000000
335555555555553333eeeeeeeeeeee33000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
35cccccccccccc533e3e33e33e33e3e3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5cc7777777777cc5e3e33e33e33e33ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7cdccdccdcc7c5ee33e33e33e33e3e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7dccdccdccd7c5e33e33e33e33e33e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7ccdccdccdc7c5e3e33e33e33e33ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7cdccdccdcc7c5ee33e33e33e33e3e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7dccdccdccd7c5e33e33e33e33e33e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7ccdccdccdc7c5e3e33e33e33e33ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7cdccdccdcc7c5ee33e33e33e33e3e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7dccdccdccd7c5e33e33e33e33e33e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7ccdccdccdc7c5e3e33e33e33e33ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7cdccdccdcc7c5ee33e33e33e33e3e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7dccdccdccd7c5e33e33e33e33e33e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7ccdccdccdc7c5e3e33e33e33e33ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7cdccdccdcc7c5ee33e33e33e33e3e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7dccdccdccd7c5e33e33e33e33e33e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7ccdccdccdc7c5e3e33e33e33e33ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7cdccdccdcc7c5ee33e33e33e33e3e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7dccdccdccd7c5e33e33e33e33e33e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c7ccdccdccdc7c5e3e33e33e33e33ee000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5c777777777777c5ee33e33e33e33e3e000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
35cccccccccccc533e3e33e33e33e3e3000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
335555555555553333eeeeeeeeeeee33000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
