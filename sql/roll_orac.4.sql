/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

select 1 point,'Rollback contention system undo header = '||
(round(max(decode(class,'system undo header',count,0)) /
(sum(count)+0.00000000001),4))*100||'%'||
' (Total requests = '||sum(count)||')' text
from v$waitstat
union
select 2 point,'Rollback contention system undo block  = '||
(round(max(decode(class,'system undo block',count,0)) /
(sum(count)+0.00000000001),4))*100||'%'||
' (Total requests = '||sum(count)||')' text
from v$waitstat
union
select 3 point,'Rollback contention undo header        = '||
(round(max(decode(class,'undo header',count,0)) /
(sum(count)+0.00000000001),4))*100||'%'||
' (Total requests = '||sum(count)||')' text
from v$waitstat
union
select 4 point,'Rollback contention undo block         = '||
(round(max(decode(class,'undo block',count,0)) /
(sum(count)+0.00000000001),4))*100||'%'||
' (Total requests = '||sum(count)||')' text
from v$waitstat
union
select 5 point,'If percentage is more than 1%,create more rollback segments' text
from dual
order by 1
