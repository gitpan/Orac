select sequence_name
from   all_sequences
where  UPPER(sequence_owner) = UPPER( ? )
order by sequence_name
