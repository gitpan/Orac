select distinct table_name
from   dba_indexes
where  UPPER(owner) = UPPER( ? )
order by 1
