select distinct owner 
from all_tab_comments
where comments is not null
union
select distinct owner 
from all_col_comments
where comments is not null
order by 1
