select master
from   all_snapshot_logs
where  UPPER(log_owner) = UPPER( ? )
order by master
