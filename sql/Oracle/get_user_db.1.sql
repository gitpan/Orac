/* Thanks to Andy Campbell */
select bytes/blocks "db_block_size" from user_free_space
union
select bytes/blocks from user_segments
where rownum < 2
