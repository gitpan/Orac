/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

select name seg_name,
tablespace_name,
v$rollstat.status status
from v$rollstat,v$rollname,dba_rollback_segs
where v$rollstat.usn = v$rollname.usn and name = segment_name
