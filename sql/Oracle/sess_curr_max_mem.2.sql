select SUM(value) "Total_Session_UGA"
from v$sysstat
where name = 'session uga memory'
