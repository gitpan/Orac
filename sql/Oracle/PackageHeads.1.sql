select distinct owner
from   all_source
where  type = 'PACKAGE'
order by owner
