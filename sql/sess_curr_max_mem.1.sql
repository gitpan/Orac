select statistic#,name,class,value
from v$sysstat
where (name like '%memory%') and
(name like '%session%')
order by 1,2
