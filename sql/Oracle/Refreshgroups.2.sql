select rname
from   all_refresh
where  UPPER(rowner) = UPPER( ? )
order by rname
