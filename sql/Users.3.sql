/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor user_cursor is select username,password,default_tablespace,temporary_tablespace,profile
from sys.dba_users
where username = ?
order by username;
cursor quo_cursor (c_user varchar2) is select tablespace_name,max_bytes
from sys.dba_ts_quotas
where username = c_user;
l_unm sys.dba_users.username%TYPE;
l_password sys.dba_users.password%TYPE;
l_default_tbl sys.dba_users.default_tablespace%TYPE;
l_temp_tbl sys.dba_users.temporary_tablespace%TYPE;
l_profile sys.dba_users.profile%TYPE;
l_tbsp sys.dba_ts_quotas.tablespace_name%TYPE;
l_max_bytes sys.dba_ts_quotas.max_bytes%TYPE;
l_string varchar2(80);
l_ln number;
procedure write_out is
begin
l_ln := l_ln + 1;
dbms_output.put_line(l_string);
end;
begin
l_ln := 0;
open user_cursor;
loop
fetch user_cursor into
l_unm,
l_password,
l_default_tbl,
l_temp_tbl,
l_profile;
exit when user_cursor%NOTFOUND;
l_string := 'CREATE USER '||l_unm||' identified by values '||chr(39)||l_password||chr(39);
write_out;
l_string := '    default tablespace '||l_default_tbl;
write_out;
l_string := '    temporary tablespace '||l_temp_tbl;
write_out;
open quo_cursor(l_unm);
loop
fetch quo_cursor into l_tbsp,l_max_bytes;
exit when quo_cursor%NOTFOUND;
if l_max_bytes = -1 then
l_string := '    quota unlimited on '||l_tbsp;
elsif mod(l_max_bytes,1048576) = 0 then
l_string := '    quota '||l_max_bytes/1048576||'M on '||l_tbsp;
elsif mod(l_max_bytes,1024) = 0 then
l_string := '    quota '||l_max_bytes/1024||'K on '||l_tbsp;
else
l_string := '    quota '||l_max_bytes||' on '||l_tbsp;
end if;
write_out;
end loop;
close quo_cursor;
l_string := '    profile '||l_profile||';';
write_out;
end loop;
close user_cursor;
end;
