select table_name
from   all_tables
where  UPPER(owner) = UPPER( ? )
order by 1
