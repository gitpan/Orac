/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor cm_c is select owner,table_name,table_type,comments
from sys.dba_tab_comments
where owner = ?
and table_name = ?
and comments is not null
order by owner,table_name;
cursor com_c is select owner,table_name,column_name,comments from sys.dba_col_comments
where owner = ?
and table_name = ?
and comments is not null
order by owner,table_name,column_name;
l_on sys.dba_tab_comments.owner%TYPE;
l_tn sys.dba_tab_comments.table_name%TYPE;
l_tab_typ sys.dba_tab_comments.table_type%TYPE;
l_comt sys.dba_tab_comments.comments%TYPE;
l_col_nam sys.dba_col_comments.column_name%TYPE;
l_ln number;
text_length number;
startp number;
xchar number;
break_pos number;
lf_pos number;
lf_break number;
backwords number;
new_line number;
offset number;
out_start number;
out_len number;
l number;
out_line varchar2(2000);
bef_chars varchar2(2000);
a_lin varchar2(80);
my_lin varchar2(2000);
function wri(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
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
break_pos := instr(x_str,' '||chr(9),startp);
if break_pos > 0
then
bef_chars := ltrim(substr(x_str,startp,
break_pos - startp + 1));
if nvl(bef_chars,'@@xyzzy') = '@@xyzzy'
then
break_pos := 0;
end if;
end if;
lf_pos := instr(x_str,chr(10),startp);
lf_break := 0;
if (lf_pos < break_pos or break_pos = 0) and lf_pos > 0 then
break_pos := lf_pos;
lf_break := 1;
end if;
if break_pos + lf_pos = 0 then
break_pos := startp + 80;
if break_pos > text_length then
break_pos := text_length + 1;
end if;
backwords := 1;
new_line := 0;
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
if break_pos > text_length
then
break_pos := text_length + 1;
end if;
backwords := 1;
end if;
while backwords = 1
loop
if break_pos > text_length
then
backwords := 0;
exit;
end if;
if break_pos <= startp
then
break_pos := startp + 79;
if break_pos > text_length
then
break_pos := text_length + 1;
end if;
backwords := 0;
exit;
end if;
if substr(x_str,break_pos,1) = ' '
then
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
l_col_nam := ' ';
open cm_c;
loop
fetch cm_c into l_on,l_tn,l_tab_typ,l_comt;
exit when cm_c%NOTFOUND;
a_lin := wri(a_lin,'COMMENT ON TABLE ',0);
a_lin := wri(a_lin,l_on||'.'||l_tn,1);
a_lin := wri(a_lin,'     IS ',0);
a_lin := brkline(a_lin,chr(39)||l_comt||chr(39),0);
a_lin := wri(a_lin,';',1);
end loop;
close cm_c;
open com_c;
loop
fetch com_c into l_on,l_tn,l_col_nam,l_comt;
exit when com_c%NOTFOUND;
a_lin := wri(a_lin,'COMMENT ON COLUMN ',0);
a_lin := wri(a_lin,l_on||'.'||l_tn||'.'||l_col_nam,1);
a_lin := wri(a_lin,'     IS ',0);
a_lin := brkline(a_lin,chr(39)||l_comt||chr(39),0);
a_lin := wri(a_lin,';',1);
end loop;
close com_c;
exception
when others then
raise_application_error(-20000,'Unexpected error on '||l_on||'.'||l_tn||': '||to_char(SQLCODE)||' - Aborting...');
end;
