select SUM(value) "Total_Session_UGA_Max"
from v$sysstat
where name = 'session uga memory max'
