select distinct owner
from   all_source
where  type = 'FUNCTION'
order by owner
