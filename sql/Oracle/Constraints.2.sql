select distinct constraint_name
from   all_constraints
where  UPPER(owner) = UPPER( ? )
order by 1
