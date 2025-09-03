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