select distinct name from all_source
where UPPER(owner) = UPPER( ? )
and type = 'PACKAGE'
order by name
