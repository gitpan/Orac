/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor view_cursor is select owner,view_name,text
from sys.dba_views
where owner = ?
and view_name = ?
order by owner,view_name;
l_on sys.dba_views.owner%TYPE;
l_view_name sys.dba_views.view_name%TYPE;
l_text sys.dba_views.text%TYPE;
l_ln number;
text_length number;
startp number;
xchar number;
break_pos number;
lf_pos number;
semi_pos number;
lf_break number;
backwords number;
new_line number;
offset number;
out_start number;
out_len number;
l number;
out_line varchar2(2000);
bef_chars varchar2(2000);
a_lin varchar2(2000);
my_lin varchar2(2000);
search_for_break boolean;
start_break_search number;
function wri(x_lin in varchar2,x_str in varchar2,
x_force in number) return varchar2 is
begin
if length(x_lin) + length(x_str) > 80
then
l_ln := l_ln + 1;
dbms_output.put_line(x_lin);
if x_force = 0
then
return x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line(x_str);
return '';
end if;
else
if x_force = 0
then
return x_lin||x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line(x_lin||x_str);
return '';
end if;
end if;
end wri;
function brkline(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
my_lin := x_lin;
text_length := nvl(length(x_str),0);
startp := 1;
while startp <= text_length
loop
backwords := 0;
offset := 0;
new_line := 1;
search_for_break := TRUE;
start_break_search := startp;
while search_for_break
loop
search_for_break := FALSE;
break_pos := instr(x_str,' '||chr(9),start_break_search);
if break_pos > 0
then
bef_chars := ltrim(substr(x_str,start_break_search,break_pos - start_break_search + 1));
if nvl(bef_chars,'@@xyzzy') = '@@xyzzy'
then
break_pos := 0;
if start_break_search + 2 < text_length then
search_for_break := TRUE;
start_break_search := start_break_search
+ 1;
end if;
end if;
end if;
end loop;

lf_pos := instr(x_str,chr(10),startp);
lf_break := 0;
if (lf_pos < break_pos or break_pos = 0) and lf_pos > 0 then
break_pos := lf_pos;
lf_break := 1;
end if;
semi_pos := instr(x_str,';',startp);
if break_pos + lf_pos = 0 or (break_pos > semi_pos and semi_pos > 0) then
if semi_pos = 0 then
break_pos := startp + 80;
if break_pos > text_length then
break_pos := text_length + 1;
end if;
backwords := 1;
new_line := 0;
else
break_pos := semi_pos + 1;
end if;
else
if lf_break = 0 then
break_pos := break_pos + 1;
offset := 1;
else
offset := 1;
end if;
end if;
if break_pos - startp > 80
then
break_pos := startp + 79;
if break_pos > text_length then
break_pos := text_length + 1;
end if;
backwords := 1;
end if;
while backwords = 1
loop
if break_pos > text_length then
backwords := 0;
exit;
end if;
if break_pos <= startp then
break_pos := startp + 79;
if break_pos > text_length then
break_pos := text_length + 1;
end if;
backwords := 0;
exit;
end if;
if substr(x_str,break_pos,1) = ' ' then
backwords := 0;
exit;
end if;
break_pos := break_pos - 1;
end loop;
xchar := break_pos - startp;
if xchar = 0 then
if offset = 0 then
return my_lin;
end if;
else
out_line := replace(substr(x_str,startp,xchar),chr(9),'        ');
out_start := 1;
l := length(out_line);
if nvl(l,-1) = -1 then
return my_lin;
end if;
while out_start <= l
loop
if l >= out_start + 79 then
out_len := 80;
else
out_len := l - out_start + 1;
end if;
my_lin := wri(my_lin,
substr(out_line,out_start,
out_len),new_line);
out_start := out_start + out_len;
end loop;
end if;
startp := startp + xchar + offset;
end loop;
return my_lin;
end brkline;
begin
a_lin := '';
l_ln := 0;
open view_cursor;
loop
fetch view_cursor into
l_on,
l_view_name,
l_text;
exit when view_cursor%NOTFOUND;
a_lin := wri(a_lin,'create view '||l_on,0);
a_lin := wri(a_lin,'.'||l_view_name,0);
a_lin := wri(a_lin,' as ',1);
a_lin := brkline(a_lin,l_text,0);
a_lin := wri(a_lin,';',1);
end loop;
close view_cursor;
exception
when others then
raise_application_error(-20000,'Unexpected error on '||l_on||'.'||l_view_name||': '||to_char(SQLCODE)||' - Aborting...');
end;
