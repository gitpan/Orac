select /*+ ORDERED */
s.sid,
s.username,
s.osuser,
nvl(s.machine,'?') machine,
nvl(s.program,'?') program,
s.process FGrnd,
p.spid BGrnd,
X.sql_text
from sys.v_$session S,
sys.v_$process P,
sys.v_$sqlarea X
where s.osuser like lower(nvl( ? ,'%'))
and s.username like UPPER(nvl( ? ,'%'))
and s.sid like nvl( ? ,'%')
and s.paddr = p.addr
and s.type != 'BACKGROUND'
and s.sql_address = x.address
and s.sql_hash_value = x.hash_value
order by s.sid
