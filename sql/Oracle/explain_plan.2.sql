select b.username, a.sql_text
from v$sqlarea a, dba_users b
where a.command_type in (2,3,6,7,47)
and   a.parsing_user_id = b.user_id
order by a.address
