select db_link
from   all_db_links
where  UPPER(owner) = UPPER( ? )
order by 1
