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