select /*+ ORDERED */
s.sid,s.osuser,s.username,
nvl(s.machine,' ? ') machine,
nvl(s.program,' ? ') program,
s.process Fground,p.spid Bground,X.sql_text
from sys.v_$session S,
sys.v_$process P,
sys.v_$sqlarea X
where s.paddr = p.addr
and s.type != 'BACKGROUND'
and s.sql_address = x.address
and s.sql_hash_value = x.hash_value
order by s.sid
