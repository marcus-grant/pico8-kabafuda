pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- tab0: main&init

-- layout constants
TABLU_Y = 28 --yofset tablu part

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
end

function _draw()
 cls(3) -- clear to dark green
 spr_init_board()--redraw board each frame
 
 -- draw dealt cards in tableaux
 for i=1,7 do
  local tbl = sts.tbl[i]
  if #tbl > 0 then
   for j=1,#tbl do
    local c = tbl[j]--tbl card
    local x = 2 + (i-1) * 18
    local y=TABLU_Y+((j-1) << 3)
    spr_card(c.r, c.s, x, y)
   end
  end
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
 
 -- draw top 3 waste cards
 if #sts.waste > 0 then
  local start = max(1, #sts.waste - 2)
  for i = start, #sts.waste do
   local c = sts.waste[i]
   local offset = (i - start) * 8
   local x = 20 + offset
   local y = 2
   spr_card(c.r, c.s, x, y)
  end
 end
 
 -- show stock count
 if #sts.sto > 0 then
  print(#sts.sto, 6, 8, 7)
 end
 
 -- show waste count
 if #sts.waste > 0 then
  print(#sts.waste, 22, 10, 1)
 end
 
 
 -- draw cursor
 draw_crs()
end

-->8
-- tab1: state

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
 top_pos = 0, --0=stock, 1=waste, 2-5=foundations
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

function deal_cards()
 --start dealing animation
 anim.active = true
 anim.tbl_i = 1
 anim.card_i = 0
 anim.timer = 0
end

function update_deal()
 if not anim.active then
  return
 end
 
 anim.timer += 1
 if anim.timer < anim.delay then
  return
 end
 
 -- time to deal next card
 anim.timer = 0
 
 -- deal card to current tableau
 local card = sts.sto[#sts.sto]
 local ti = anim.tbl_i
 del(sts.sto, card)
 add(sts.tbl[ti], card)
 
 -- move to next card in tableau
 anim.card_i += 1
 
 -- check if tableau is full
 local tbl_totl = ti
 if anim.card_i >= tbl_totl then
  -- move to next tableau
  anim.tbl_i += 1
  anim.card_i = 0
  
  -- check if all tableaux dealt
  if anim.tbl_i > 7 then
   anim.active = false
  end
 end
end

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

function valid_tablu(st,cnt)
 --whether 'cnt' cards from
 --top of stack 'st' obeys
 --solitaire ordering rules
 --ie interleaves red/black
 --{in/de}creases by one each
 --stacks of 1 or 0 cards are not valid
 if #st < 2 or cnt < 2 then
  return false --todo: maybe allow?
 end
 local i = #st
 local min_i = max(2, i - cnt + 2)
 
 while i >= min_i do
  --cc: curr. card, lc: lower
  local cc, lc = st[i], st[i-1]
  
  if (cc.r + 1) != lc.r then
   return false
  end
  
  --todo:should is_blk be a fn?
  --cb: curr. is black
  --lb: lower is black
  local cb = (cc.s & 1) == 1
  local lb = (lc.s & 1) == 1
  
  if cb == lb then--if same,
   return false --color same
  end--not valid tableu seq.
  i -= 1
 end
 
 --gone thru stack or range
 return true -- its valid
end

function valid_fnd(fnd,card)
 --check if card can go on fnd
 if #fnd == 0 then
  --empty foundation
  return card.r == RA --ace only
 else
  --must match suit & be +1
  local top = fnd[#fnd]
  return card.s == top.s and
         card.r == top.r + 1
 end
end
-->8
-- tab2: draw

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
 msg = "num cards: "
 msg = msg..#sts.sto
 print(msg,8,104,4)
end

function strcard(card)
 if card.r < 10 then
  txt = tostr(card.r)
 elseif card.r == R10 then
  txt = "0"
 elseif card.r == RJ then
  txt = "j"
 elseif card.r == RQ then
  txt = "q"
 elseif card.r == RK then
  txt = "k"
 elseif card.r == RA then
  txt = "a"
 else
  txt = "bad"
 end
 if card.s == HRT then
  txt = txt.."h"
 elseif card.s == SPD then
  txt = txt.."s"
 elseif card.s == DIA then
  txt = txt.."d"
 elseif card.s == CLB then
  txt = txt.."c"
 else
  txt = txt.."!"
 end
 return txt
end

function print_st(st)
 pt = {0, 0}
 for c in all(st) do
  msg = strcard(c)
  print(msg, pt[1], pt[2])
  pt[1] += 16
  if pt[1] >= 128 then
   pt[1] = 0
   pt[2] += 16
  end
 end
end

function spr_deckback()
 --Draw 2x3 sprs for
 --turned over stock decks back
 local p = {2, 2}
 sspr(0,32,16,24,p[1],p[2])
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
 spr_deckback()
 for i=0,3 do
  sprfnd(i)
 end
 for i=0,6 do
  sprtbl(i)
 end
end

function mv_cards(from,to,cnt)
 --blindly move cnt cards
 for i=1,cnt do
  local c = from[#from]
  del(from, c)
  add(to, c)--add to end
 end
end

function grab_from_tbl()
 --grab selected cards from tableau
 local src = sts.tbl[crs.tbl_i]
 if #src >= crs.sel_cnt then
  mv_cards(src, held, crs.sel_cnt)
  held_from = src
  crs.sel_cnt = 1 --reset selection
 end
end

function grab_from_waste()
 --grab top card from waste pile
 if #sts.waste > 0 then
  mv_cards(sts.waste, held, 1)
  held_from = sts.waste
 end
end

function grab_from_fnd()
 --grab top card from foundation
 local fi = crs.top_pos - 1
 local src = sts.fnd[fi]
 if #src > 0 then
  mv_cards(src, held, 1)
  held_from = src
 end
end

function deal_sto()
 --deal 3 cards from stock to waste
 if #sts.sto >= 3 then
  for i=1,3 do
   mv_cards(sts.sto, sts.waste, 1)
  end
 elseif #sts.sto > 0 then
  --deal remaining cards
  mv_cards(sts.sto, sts.waste, #sts.sto)
 end
end

function grab_cards()
 --dispatch based on cursor area
 if crs.area == "tbl" then
  grab_from_tbl()
 elseif crs.area == "top" then
  if crs.top_pos == 0 then
   --deal from stock
   deal_sto()
  elseif crs.top_pos == 1 then
   grab_from_waste()
  elseif crs.top_pos >= 2 then
   grab_from_fnd()
  end
 end
end

function place_on_tbl()
 --place held cards on tableau
 local dest=sts.tbl[crs.tbl_i]
 local valid = false
 
 if #dest == 0 then
  --empty tableau accepts any
  valid = true
 else
  --test combined stack validity
  local test = {}
  for c in all(dest) do
   add(test, c)
  end
  for c in all(held) do
   add(test, c)
  end
  valid=valid_tablu(test,#held+1)
 end
 
 if valid then
  mv_cards(held, dest, #held)
  held_from = nil
 end
end

function place_on_stock()
 --place single card on empty stock
 if #sts.sto==0 and #held==1 then
  mv_cards(held, sts.sto, 1)
  held_from = nil
 end
end

function place_on_fnd()
 --place single card on foundation
 local fi = crs.top_pos - 1
 local dest = sts.fnd[fi]
 
 if #held==1 and 
    valid_fnd(dest,held[1]) 
 then
  mv_cards(held, dest, 1)
  held_from = nil
 end
end

function place_cards()
 --dispatch based on cursor area
 if crs.area == "tbl" then
  place_on_tbl()
 elseif crs.area == "top" then
  if crs.top_pos == 0 then
   place_on_stock()
  elseif crs.top_pos >= 2 then
   place_on_fnd()
  end
 end
end

-->8
-- tab3: input

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
 
 -- handle grab/place w/ O btn
 if btnp(4) then
  if #held > 0 then
   place_cards()
  else
   grab_cards()
  end
 end
 
 -- handle cancel w/ X btn
 if btnp(5) and #held > 0 then
  if held_from then
   mv_cards(held, held_from, #held)
   held_from = nil
  end
 end
end

function move_crs_left()
 if crs.area == "tbl" then
  crs.tbl_i -= 1
  if crs.tbl_i < 1 then
   crs.tbl_i = 1
  end
  local tbl = sts.tbl[crs.tbl_i]
  crs.sel_cnt = 1
 elseif crs.area == "top" then
  crs.top_pos -= 1
  if crs.top_pos < 0 then
   crs.top_pos = 0
  end
 end
end

function move_crs_right()
 if crs.area == "tbl" then
  crs.tbl_i += 1
  if crs.tbl_i > 7 then
   crs.tbl_i = 7
  end
  local tbl = sts.tbl[crs.tbl_i]
  crs.sel_cnt = 1
 elseif crs.area == "top" then
  crs.top_pos += 1
  if crs.top_pos > 5 then
   crs.top_pos = 5
  end
 end
end

function move_crs_up()
 if crs.area == "tbl" then
  local tbl=sts.tbl[crs.tbl_i]
  if #tbl == 0 then
   crs.area = "top"
   crs.top_pos = 0
  else
   --try to expand selection
   local new_cnt=crs.sel_cnt+1
   if valid_tablu(tbl,new_cnt) 
   then
    crs.sel_cnt = new_cnt
   else
    --can't expand,move to top
    crs.area = "top"
    crs.top_pos = 0
    crs.sel_cnt = 1
   end
  end
 end
end

function move_crs_down()
 if crs.area == "top" then
  crs.area = "tbl"
  local tbl = sts.tbl[crs.tbl_i]
  crs.sel_cnt = 1
 elseif crs.area == "tbl" then
  local tbl = sts.tbl[crs.tbl_i]
  if #tbl == 0 then
   return
  end
  --reduce selection to 1
  if crs.sel_cnt > 1 then
   crs.sel_cnt -= 1
  end
 end
end

function draw_crs()
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
  if crs.top_pos == 0 then
   -- stock position
   return 2, 2
  elseif crs.top_pos == 1 then
   --waste pos. (next to stock)
   return 20, 2
  else
   -- foundation position
   -- (2-5 to foundations 1-4)
   local fnd_i = crs.top_pos - 2
   local pad = 2
   local offs = (pad+16) * fnd_i
   return 56 + offs, 2
  end
 else
  -- tableau position
  local x = 2
  x += (crs.tbl_i - 1) * 18
  local tbl = sts.tbl[crs.tbl_i]
  if #tbl == 0 then
   -- empty tableau,
   -- position at tableau mark
   return x, TABLU_Y
  else
   --position at bottom of sel
   local y = TABLU_Y
   local bot_i=#tbl-crs.sel_cnt
   y += bot_i << 3
   return x, y
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
