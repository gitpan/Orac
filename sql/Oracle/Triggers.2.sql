select distinct table_name from all_triggers
where UPPER(owner) = UPPER( ? )
order by table_name
