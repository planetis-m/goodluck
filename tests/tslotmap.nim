import entitytype, slotmap

var sm: SlotMap[int]
let ent = sm.incl(5)
sm.del(ent)
echo sm.len
echo ent in sm
let ent2 = sm.incl(6)
let ent3 = sm.incl(7)
echo ent2
echo ent3
for p in sm.pairs:
  echo p
sm.del(ent2)
echo sm.len
echo sm[ent3]
sm.clear
