/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

select pct_free,ini_trans
from dba_tables
where owner = upper( ? )
and table_name = upper( ? )
