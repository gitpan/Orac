/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

select name seg_name,
waits wait,
floor(100 * waits / gets) pc_wt,
decode(sign(9999999-gets),-1,lpad(trunc(gets / 1000000),3)||' M',decode(sign(9999-gets),-1,
lpad(trunc(gets / 1000),3)||' k', lpad(gets,5))) gets,
decode(sign(9999999-writes) ,-1,lpad(trunc(writes / 1000000),3)||' M',
decode(sign(9999-writes),-1,lpad(trunc(writes / 1000),3)||' k', lpad(writes,5))) write,
round((rssize / 1048576 ),2) MB,
round((optsize /1048576),2) Opt_MB,
round((hwmsize / 1048576),2) Hi_Wtr_MB,
shrinks Shrnk,
extends Extd,
decode(sign(9999999-aveactive),-1,lpad(trunc(aveactive / 1000000),3)||' M',
decode(sign(9999-aveactive),-1, lpad(trunc(aveactive / 1000),3)||' k',
lpad(aveactive,5))) aveactive,
extents Exts,
xacts Trn,
wraps Wrp,
decode(sign(9999999-aveshrink),-1,lpad(trunc(aveshrink / 1000000),3)||' M',
decode(sign(9999-aveshrink),-1,lpad(trunc(aveshrink / 1000),3)||' k',
lpad(aveshrink,5))) avshrk
from v$rollstat,v$rollname
where v$rollstat.usn = v$rollname.usn
