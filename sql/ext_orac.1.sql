select owner,
tablespace_name,
segment_type typ,
segment_name,
decode(max_extents,'2147483645','ULTD',to_char(round(max_extents,2))) maxt,
extents exts,
round((extents/max_extents*100),2) pct,
decode(sign(75 - (extents/max_extents*100)),-1,' * ',
decode(sign(20 - extents) ,-1,' * ','')) Fix
from sys.dba_segments
where extents > 1
and segment_type != 'ROLLBACK'
and segment_type != 'CACHE'
and owner != 'SYS'
order by Fix,PCT desc,extents desc,owner,segment_type
