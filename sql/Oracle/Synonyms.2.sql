select synonym_name
from   all_synonyms
where  UPPER(owner) = UPPER( ? )
order by synonym_name
