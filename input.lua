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