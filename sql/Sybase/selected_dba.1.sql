select  Column_name = c.name,
        Type =  t.name,
        Nulls = convert(bit, (c.status & 8)),
        Length = c.length
 from  syscolumns c, systypes t
 where c.id = object_id('%s')
 and   c.usertype *= t.usertype
 order by colid
