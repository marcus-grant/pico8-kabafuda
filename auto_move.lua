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