select distinct view_name 
from all_views
where UPPER(owner) = UPPER( ? )
order by view_name
