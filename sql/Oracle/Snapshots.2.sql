select name
from   all_snapshots
where  UPPER(owner) = UPPER( ? )
order by name
