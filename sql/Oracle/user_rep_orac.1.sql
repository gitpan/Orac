select username,user_id,default_tablespace,
temporary_tablespace tmp_tabsp,profile,created
from dba_users
order by username
