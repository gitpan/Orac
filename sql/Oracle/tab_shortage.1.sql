select d.tablespace_name tspace,
d.file_id file_id,
d.bytes/1024/1024 tot_mb,
d.bytes/ ? ora_blks,
nvl(sum(e.blocks),0.00) tot_used,
nvl(round(((sum(e.blocks)/
(d.bytes/ ? ))*100),2),0.00) pct_used
from sys.dba_extents e,
sys.dba_data_files d
where d.file_id = e.file_id (+)
group by d.tablespace_name,D.file_id,d.bytes
