/* From Oracle Scripts, O Reilly and Associates, Inc. */
/* Copyright 1998 by Brian Lomasky, DBA Solutions, Inc., */
/* lomasky@earthlink.net */

declare
cursor src_cursor is
select owner,name,text
from sys.dba_source
where type = 'PROCEDURE'
and owner = ?
and name = ?
order by owner,name,line;
l_on sys.dba_source.owner%TYPE;
l_nm sys.dba_source.name%TYPE;
l_text sys.dba_source.text%TYPE;
l_ln number;
text_length number;
startp number;
xchar number;
first_break number;
break_pos number;
dash_pos number;
lf_pos number;
semi_pos number;
backwords number;
new_line number;
offset number;
out_start number;
out_len number;
l number;
bef_chars varchar2(2000);
out_line varchar2(2000);
a_lin varchar2(120);
prev_owner sys.dba_source.owner%TYPE;
prev_name sys.dba_source.name%TYPE;
delete_object number;
delete_name number;
function wri(x_lin in varchar2,x_str in varchar2,x_force in number) return varchar2 is
begin
if length(x_lin) + length(x_str) > 120 then
l_ln := l_ln + 1;
dbms_output.put_line(x_lin);
if x_force = 0 then
return x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line(x_str);
return '';
end if;
else
if x_force = 0 then
return x_lin||x_str;
else
l_ln := l_ln + 1;
dbms_output.put_line(x_lin||x_str);
return '';
end if;
end if;
end wri;
begin
a_lin := '';
l_ln := 0;
prev_owner := '@';
prev_name := '';
open src_cursor;
loop
<<fetchnext>>
fetch src_cursor into
l_on,
l_nm,
l_text;
exit when src_cursor%NOTFOUND;
if prev_owner != l_on or prev_name != l_nm then
if prev_owner != '@' then
a_lin := wri(a_lin,chr(10)||'/',1);
a_lin := wri(a_lin,'rem -------------------------',1);
end if;
a_lin := wri(a_lin,'create or replace procedure ',0);
a_lin := wri(a_lin,l_on||'.'||l_nm,1);
prev_owner := l_on;
prev_name := l_nm;
delete_object := 1;
delete_name := 1;
end if;
if delete_object = 1 then
break_pos := instr(upper(l_text),'PROCEDURE');
if break_pos != 0 then
delete_object := 0;
if length(l_text) < break_pos + 10 then
goto fetchnext;
end if;
l_text := substr(l_text,break_pos + 9);
end if;
end if;
if delete_name = 1 then
break_pos := instr(upper(l_text),upper(l_nm));
if break_pos != 0 then
delete_name := 0;
if length(l_text) < break_pos + length(l_nm) + 1 then
goto fetchnext;
end if;
l_text := substr(l_text,break_pos + length(l_nm));
end if;
end if;
break_pos := instr(l_text,'0'||chr(2));
if break_pos != 0 then
l_text := substr(l_text,1,break_pos - 1);
end if;
text_length := nvl(length(l_text),0);
startp := 1;
while startp <= text_length
loop
break_pos := instr(l_text,' '||chr(9),startp);
lf_pos := instr(l_text,chr(10),startp);
dash_pos := instr(l_text,'-- ',startp);
semi_pos := instr(l_text,';',startp);
if break_pos > 0 then
bef_chars := ltrim(substr(l_text,startp,break_pos - startp + 1));
if bef_chars is null then
break_pos := 0;
end if;
end if;
backwords := 0;
new_line := 1;
first_break := 9999;
if lf_pos != 0 and lf_pos < first_break then
first_break := lf_pos;
offset := 1;
end if;
if semi_pos != 0 and semi_pos < first_break then
first_break := semi_pos + 1;
offset := 0;
end if;
if break_pos != 0 and break_pos < first_break then
if first_break != semi_pos + 1 or first_break - startp > 119 then
first_break := break_pos + 1;
offset := 1;
end if;
end if;
if dash_pos != 0 and dash_pos < first_break then
if text_length - startp > 119 then
first_break := dash_pos;
offset := 0;
if dash_pos = startp then
first_break := 9999;
end if;
end if;
end if;
if dash_pos != 0 and semi_pos != 0 and text_length - startp < 120 and first_break = semi_pos + 1 then
first_break := 9999;
end if;
if first_break = 9999 then
first_break := startp + 120;
if break_pos > text_length then
break_pos := text_length + 1;
end if;
backwords := 1;
new_line := 0;
end if;
break_pos := first_break;
if break_pos - startp > 120 then
break_pos := startp + 119;
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
break_pos := startp + 119;
if break_pos > text_length then
break_pos := text_length + 1;
end if;
backwords := 0;
exit;
end if;
if substr(l_text,break_pos,1) = ' ' then
backwords := 0;
exit;
end if;
break_pos := break_pos - 1;
end loop;
xchar := break_pos - startp;
if xchar = 0 then
if offset = 0 then
goto fetchnext;
end if;
else
out_line := replace(substr(l_text,startp,xchar),chr(9),'   ');
out_start := 1;
l := length(out_line);
if l is null then
goto fetchnext;
end if;
while out_start <= l
loop
if l >= out_start + 119 then
out_len := 120;
else
out_len := l - out_start + 1;
end if;
a_lin := wri(a_lin,
substr(out_line,out_start,
out_len),new_line);
out_start := out_start + out_len;
end loop;
end if;
startp := startp + xchar + offset;
end loop;
end loop;
close src_cursor;
if prev_owner != '@' then
a_lin := wri(a_lin,chr(10)||'/',1);
end if;
end;
