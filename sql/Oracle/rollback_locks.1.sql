select r.usn,
r.name,
s.osuser,
s.username,
s.serial# ser#,
s.sid,
x.extents extns,
x.extends extds,
x.waits wait,
x.shrinks shrk,
x.wraps wrp
from sys.v_$rollstat X,
sys.v_$rollname R,
sys.v_$session S,
sys.v_$transaction T
where t.addr = s.taddr (+)
and x.usn (+) = r.usn
and t.xidusn (+) = r.usn
order by r.usn
