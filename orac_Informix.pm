use strict;
package orac_Informix;

# what I really need is a init0_orac_Informix();
# something to be called before id/password collection!

sub init0_orac_Informix
{
   # Place here anything you need before connecting to the DB.
   print STDERR "init0_orac_Informix()\n" if ($main::debug > 0);
   $main::dont_need_sys = 1;
   $main::dont_need_ps = 1;
}
sub init1_orac_Informix
{
   package main;
   print STDERR "init1_orac_Informix()\n" if ($main::debug > 0);

   # Place here whatever environmental variables are needed
   # for dbi:Informix, eg (for oracle):
   # $ENV{TWO_TASK} = $v_db;
   #
   # the user needs to have:
   #   INFORMIXDIR
   #   INFORMIXSERVER
   #   ONCONFIG
   # hmm, don't know what to do if we don't have these, can we croak to a dialog?
   # i have no way to guess values...

   # also useful, but optional
   #   DBTERM
   #   DBDATE
   $ENV{DBTERM} = "vt100" if (!exists($ENV{DBTERM}));
   $ENV{DBDATE} = "y4md0" if (!exists($ENV{DBDATE}));

   # blank out the user & passwd, we don't need them
   #$main::v_sys = "";
   #$main::v_ps = "";
}
sub init2_orac_Informix
{
    package main;
print STDERR "init2_orac_Informix()\n" if ($main::debug > 0);

    # Place here any bits of code you would like to run
    # once you've connected to each database.  For Oracle,
    # you may want to select the database block size into
    # a variable, so it's available for each subsequent 
    # statement, without continually reloading it.

    # Remove trailing blanks.
    # doesn't everyone want to do this?
    $main::dbh->{ChopBlanks}=1;
}
sub init3_orac_Informix
{
   package main;
print STDERR "init3_orac_Informix()\n" if ($main::debug > 0);

   my($cm,$sub,$frm) = @_;

   # We'll cover this one later.  Don't do anything here
   # unless you know what it is you're trying to achieve.

   return($cm,$frm);
}
sub init4_orac_Informix
{
   package main;
   print STDERR "init4_orac_Informix()\n" if ($main::debug > 0);

   my $flag = shift;

   # Again, this is for special report formatting.  
   # You do not need to do anything here, for now.

}
##################### Database dependent code functions below here #####################
sub onstat_databases
{
    # Do your stuff
    show_sql(main::f_str("Databases", "1"));
}
sub onstat_dbspaces
{
    # Do your stuff
    show_sql(main::f_str("DBSpaces", "1"));
}
sub onstat_chunks
{
    # Do your stuff
    show_sql(main::f_str("Chunks", "1"));
}
sub onstat_onconfig_params
{
    # Do your stuff
    $main::v_text->insert('end', main::gf_str("$ENV{INFORMIXDIR}/etc/$ENV{ONCONFIG}"));
}
sub oncheck_extents
{
    # Do your stuff
    show_sql(main::f_str("Extents", "1"));
}
sub onstat_log_rep
{
    # Do your stuff
    show_sql(main::f_str("LogRpt", "1"));
}
sub onlog_log
{
    # Do your stuff
    show_sql(main::f_str("ShowLog", "1"));
}
sub dbschema_syns
{
    # Do your stuff
    show_sql(main::f_str("Synonyms", "1"));
}
sub dbschema_procs
{
    # Do your stuff
}
sub dbschema_proc_list
{
    # Do your stuff
}
sub dbschema_grants
{
    # Do your stuff
    show_sql(main::f_str("Grants", "1"));
}
sub dbschema_indices
{
    # Do your stuff
    show_sql(main::f_str("Indicies", "1"));
}
sub dbschema_schema
{
    # Do your stuff
    #show_sql(main::f_str("Schema", "1"));

    # hmm, IN THEORY, IT SHOULD BE POSSIBLE TO DO THIS VIA THE SMI TABLES, BUT HOW?!!!

    my $db = $main::v_db;
    $db =~ s/@.*//o;
    #$main::v_text->insert('end', "$ENV{INFORMIXDIR}/bin/dbschema -d $db 2>&1");
    #my $x = `$ENV{INFORMIXDIR}/bin/dbschema -d $db 2>&1`;
    #$main::v_text->insert('end', $x);

    $main::v_text->insert('end', "at the command-line do:  dbschema -d $db");
}
sub onstat_threads
{
    # Do your stuff
    show_sql(main::f_str("Threads", "1"));
}
sub onstat_curr_sql
{
    # Do your stuff
    show_sql(main::f_str("CurrSQL", "1"));
}
sub finderr_num
{
    # Do your stuff
    #show_sql(main::f_str("FindErr", "1"));
}
sub onstat_io_profile
{
    # Do your stuff
    #show_sql(main::f_str("IOProfile", "1"));
    live_update(main::f_str("IOProfile", 1), $main::lg{oi_io_profile_title});
}
sub onstat_locks_held
{
    # Do your stuff
    live_update(main::f_str("Locks", 1), $main::lg{locks_held});
}
###############################################################################
# Generic support functions &
# Generic execute query & auto-format results & print...
###############################################################################
# Take an SQL statement, execute it, and show the results in a matrix-like format.
# ARG1 = the SQL statement
# ARG2 = a title (optional, if not sent, the first 40 chars of the SQL is used)
# ARG3 = text widget to use (optional, if not sent it uses the main one)
sub show_sql
{
	my ($sql, $title) = @_;
	my (@row, $id);

	unless (defined($sql)) { return; }

	# get patient id
	my ($r_lines, $r_format, $r_tlen, $r_names, $header) = get_lines($sql);
	my @lines = @{$r_lines};

	#@list = $tar->[0]; $list[0][0] $list[0][1] $list[0][2]
	#@names = @{$sth->{NAME}}
	#@prec = @{$sth->{PRECISION}}
	#@scal = @{$sth->{SCALE}}

    $title = substr($sql, 0, 40) if (!$title);
    main::rep_tit($title);
	if ($#lines == -1)
    {
		$main::v_text->insert('end', $main::lg{no_rows_found} . "\n");
    }
    else
    {
        print_lines($header, $r_lines, $r_tlen, $r_format);
        main::see_plsql($sql);
    }
}

# support func for show_sql
sub get_lines
{
	my $sth;
	my $tar = do_query_fetch_all($_[0], \$sth);
	my @tlen;
	my @names = @{$sth->{NAME}};
#	my @scal = @{$sth->{SCALE}};
#	my @prec = @{$sth->{PRECISION}};

	my ($j, $i, $len);
	my (@format, $header);

	for ($i=0 ; $i <= $#names ; $i++)
	{
# debugging, trying to something == to ix_ColLength, no luck yet...
#print STDERR "tlen=$tlen[$i]  scal=$scal[$i]  prec=$prec[$i]\n";

        # get the column name length
		$len = length($names[$i]);
        $tlen[$i] = $len; # comment this out if we do A. below

        # A. is the length of the column definition bigger?
		#$tlen[$i] = $len if ($len > $tlen[$i]);
        # B. instead check find the longest value!
        for ($j=0 ; $j < @{$tar} ; $j++)
        {
            # NOTE: unless you turned on ChopBlanks, you may not be totally happy
            $len = defined($tar->[$j]->[$i]) ? length($tar->[$j]->[$i]) : 0;
            $tlen[$i] = $len if ($len > $tlen[$i]);
        }

        # now build the format & header
        # sigh, we always left justify, we really should look
        #   at the type then do the right thing, maybe later...
		$format[$i] = "%-$tlen[$i]s ";
		$header .= sprintf($format[$i], $names[$i]);
	}
	return ($tar, \@format, \@tlen, \@names, $header);
}

# a support func for show_sql
sub print_lines
{
	my ($header, $tar, $r_tlen, $r_format) = @_;
	my ($i, $j, @row);
	my @lines = @{$tar};
	my @format = @{$r_format};
	my @tlen = @{$r_tlen};
    my $ubar = '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';

    # print the column header
	$main::v_text->insert('end', "\n$header\n");

    # print the underbars to show column width
    for ($i=0 ; $i <= $#tlen ; $i++)
	{
        $main::v_text->insert('end', substr($ubar, 0, $tlen[$i]) . ' ');
    }
    $main::v_text->insert('end', "\n");

    # print the data!
	for ($j=0 ; $j <= $#lines ; $j++)
	{
		@row = @{$lines[$j]};
		for ($i=0 ; $i <= $#tlen ; $i++)
		{
			$row[$i] = "" if (!defined($row[$i]));
            $main::v_text->insert('end', sprintf($format[$i], $row[$i]));
		}
		$main::v_text->insert('end', "\n");
	}
}
###############################################################################
# some DBI/DBD wrappers...
###############################################################################
# do a standard query, call $sth->fetch() to retrieve.
sub do_query
{
    my ($stmt) = @_;
    my $sth;

    print STDERR $stmt, "\n" if ( $main::debug > 4 );

    $sth = $main::dbh->prepare($stmt);
    db_check_error($stmt, "Prepare");
    $sth->execute();
    db_check_error($stmt, "Execute");
    return $sth;
}
# do a query, and fetch all rows into an array of arrays
# be careful, this could consume a LOT of memory if called with a bad statement!
sub do_query_fetch_all
{
    my($stmt, $asth) = @_;
    my $tbl_ary_ref = undef;
    my $sth;

    # to do them all:
    $sth = do_query($stmt);
    $tbl_ary_ref = $sth->fetchall_arrayref();
    db_check_error($stmt, "Fetch");
    $$asth = $sth if (defined($asth));
    $sth->finish();

    return $tbl_ary_ref;
}
# generic check for errors while interacting with the DB
sub db_check_error
{
    my ($stmt, $action) = @_;
    if (defined($DBI::err) && $DBI::err  < 0)
    {
        print STDERR "-->>$action error for $stmt\n";
        print STDERR "$DBI::errstr\n";
        print_stack();
        die "SQL Error";
    }
}
# we're about to die, so print a stack dump to see how we got in trouble
sub print_stack
{
    my($package, $filename, $line, $i);
    $package="";
    $i=0;
    while (($package, $filename, $line) = caller($i++))
    {
        print STDERR "Package: $package   File: $filename   Line: $line\n";
    }
}
###############################################################################
my $live_update_flag; # our control flag
sub live_update
{
    my ($sql, $title) = @_;

    # give us a clean slate
    main::must_f_clr();

    # create the stop button and put it at the top
    my $b = $main::v_text->Button(-text=>$main::lg{stop},
                                 -command=>sub{stop_live_update()});
    $main::v_text->window('create','end',-window=>$b);
    $main::v_text->insert('end', "\n\n");

    # set this to be true so we loop for awhile
    $live_update_flag = 1;

    # while we're live, keep updating
    while ($live_update_flag)
    {
        # delete from after the stop button to EOS
        $main::v_text->delete('1.1', 'end');
        # put the new values on the screen
        show_sql($sql, $title);
        # cause the screen to show the new values
        $main::v_text->update();
        sleep(1);
    }
    # the user hit stop, so remove the stop button
    $main::v_text->delete('1.0', '1.1');
}
sub stop_live_update
{
    # the user hit stop, so change the control flag
    $live_update_flag = 0;
}
1;
# vi: set sw=4 ts=4 et:
