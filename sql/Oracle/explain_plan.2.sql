select sql_text
from v$sqlarea
where command_type in (2,3,6,7,47)
order by address
