select type typ,sequence seq,line ln,position pos,text
from   dba_errors
where  owner = ? and
name  = ?
order by type,sequence,line
