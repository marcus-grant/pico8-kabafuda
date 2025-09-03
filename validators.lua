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