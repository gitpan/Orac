select distinct index_name
from   all_indexes
where  UPPER(owner) = UPPER( ? )
order by 1
