/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor role_cursor is
select name,password
from sys.user$
where type# = 0
and name = ?
order by 1;
l_nm sys.user$.name%TYPE;
l_password sys.user$.password%TYPE;
l_ln number;
a_lin varchar2(80);
function wri(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
if length(x_lin) + length(x_str) > 80
then
l_ln := l_ln + 1;
dbms_output.put_line( x_lin);
if x_force = 0
then
return '    '||x_str;
else
l_ln := l_ln + 1;
if substr(x_lin,1,2) = '  '
then
dbms_output.put_line( x_str);
else
dbms_output.put_line( '    '||x_str);
end if;
return '';
end if;
else
if x_force = 0
then
return x_lin||x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line( x_lin||x_str);
return '';
end if;
end if;
end wri;
begin
a_lin := '';
open role_cursor;
loop
fetch role_cursor into l_nm,l_password;
exit when role_cursor%NOTFOUND;
a_lin := wri(a_lin,'CREATE ROLE ',0);
a_lin := wri(a_lin,l_nm,0);
if nvl(l_password,'NO') = 'NO' then
a_lin := wri(a_lin,' not identified;',1);
elsif l_password = 'EXTERNAL' then
a_lin := wri(a_lin,' identified externally;',1);
else
a_lin := wri(a_lin,' identified by values ',0);
a_lin := wri(a_lin,chr(39)||l_password||chr(39)||';',1);
end if;
end loop;
close role_cursor;
end;
