select distinct owner
from   all_source
where  type = 'PROCEDURE'
order by owner
