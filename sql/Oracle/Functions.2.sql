select distinct name
from   all_source
where  UPPER(owner) = UPPER( ? )
and    type = 'FUNCTION'
order by name
