package orac_Informix;

sub init1_orac_Informix {
   package main;
   my ($sys, $ps) = @_;
print STDERR "init1_orac_Informix()\n";

   # Place here whatever environmental variables are needed
   # for dbi:Informix, eg (for oracle):
   # $ENV{TWO_TASK} = $v_db;
   #
   # the user needs to have:
   #   INFORMIXDIR
   #   INFORMIXSERVER
   #   ONCONFIG
   # hmm, don't know what to do if we don't have these, can we croak to a dialog?
   $$sys = "";
   $$ps = "";
   # i have no way to guess values...

   # also useful, but optional
   #   DBTERM
   #   DBDATE
   $ENV{DBTERM} = "vt100" if (!exists($ENV{DBTERM}));
   $ENV{DBDATE} = "y4md0" if (!exists($ENV{DBDATE}));
}
sub init2_orac_Informix {
   package main;

   # Place here any bits of code you would like to run
   # once you've connected to each database.  For Oracle,
   # you may want to select the database block size into
   # a variable, so it's available for each subsequent 
   # statement, without continually reloading it.
}
sub init3_orac_Informix {
   package main;

   my($cm,$sub,$frm) = @_;

   # We'll cover this one later.  Don't do anything here
   # unless you know what it is you're trying to achieve.

   return($cm,$frm);
}
sub init4_orac_Informix {
   package main;

   my $flag = shift;

   # Again, this is for special report formatting.  
   # You do not need to do anything here, for now.

}
######################### Database dependent code functions below here #########################
sub onstat_dbspaces {
    # Do your stuff
    show_sql(main::f_str("DBSpaces", "1")); #"
}
sub onstat_chunks {
    # Do your stuff
    show_sql(main::f_str("Chunks", "1")); #"
}
sub onstat_onconfig_params {
    # Do your stuff
    $main::v_text->insert('end', main::gf_str("$ENV{INFORMIXDIR}/etc/$ENV{ONCONFIG}"));
}
sub oncheck_extents {
    # Do your stuff
    show_sql(main::f_str("Extents", "1")); #"
}
sub onstat_log_rep {
    # Do your stuff
    show_sql(main::f_str("LogRpt", "1")); #"
}
sub onlog_log {
    # Do your stuff
    show_sql(main::f_str("ShowLog", "1")); #"
}
sub dbschema_syns {
    # Do your stuff
    show_sql(main::f_str("Synonyms", "1")); #"
}
sub dbschema_procs {
    # Do your stuff
}
sub dbschema_proc_list {
    # Do your stuff
}
sub dbschema_grants {
    # Do your stuff
    show_sql(main::f_str("Grants", "1")); #"
}
sub dbschema_indices {
    # Do your stuff
    show_sql(main::f_str("Indicies", "1")); #"
}
sub dbschema_schema {
    # Do your stuff
    #show_sql(main::f_str("Schema", "1")); #"
    my $db = $main::v_db;
    $db =~ s/@.*//o;
    $main::v_text->insert('end', "$ENV{INFORMIXDIR}/bin/dbschema -d $db 2>&1");
    my $x = `$ENV{INFORMIXDIR}/bin/dbschema -d $db 2>&1`;
    $main::v_text->insert('end', $x);
    # just want to see if you're awake andy ;-)
    # barely, need more caffeine - ajd :)
}
sub onstat_threads {
    # Do your stuff
    show_sql(main::f_str("Threads", "1")); #"
}
sub onstat_curr_sql {
    # Do your stuff
    show_sql(main::f_str("CurrSQL", "1")); #"
}
sub finderr_num {
    # Do your stuff
    #show_sql(main::f_str("FindErr", "1")); #"
}
sub onstat_io_profile {
    # Do your stuff
    show_sql(main::f_str("IOProfile", "1")); #"
}
###############################################################################
# Generic support functions &
# Generic execute query & auto-format results & print...
###############################################################################
sub show_sql
{
	my ($sql) = @_;
	my (@row, $id);

	unless (defined($sql)) { return; }

	# get patient id
	my ($r_lines, $r_format, $r_tlen, $r_names, $header) = get_lines($sql);
	my @lines = @{$r_lines};

	#@list = $tar->[0]; $list[0][0] $list[0][1] $list[0][2]
	#@names = @{$sth->{NAME}}
	#@prec = @{$sth->{PRECISION}}
	#@scal = @{$sth->{SCALE}}
	#@tlen = @{$sth->{ix_ColLength}} # type length
	#@tnum = @{$sth->{ix_ColType}};  # type number, use this is left/right justify?

	if ($#lines == -1)
    {
		$main::v_text->insert('end', "No rows returned.\n");
    }
    else
    {
        print_lines($header, $r_lines, $r_tlen, $r_format);
    }
}

sub get_lines
{
	my $sth;
	my $tar = do_query_fetch_all($_[0], \$sth);
    # ALERT!  Informix specific value!
    # $sth->{PRECISIION} does NOT cut it, what else do we have?
	my @tlen = @{$sth->{ix_ColLength}};
	my @names = @{$sth->{NAME}};
#	my @scal = @{$sth->{SCALE}};
#	my @prec = @{$sth->{PRECISION}};

	my ($j, $i, $len);
	my (@format, $header);

	for ($i=0 ; $i <= $#names ; $i++)
	{
# debugging, trying to something == to ix_ColLength, no luck yet...
#print STDERR "tlen=$tlen[$i]  scal=$scal[$i]  prec=$prec[$i]\n";
		$len = length($names[$i]);
		$tlen[$i] = $len if ($len > $tlen[$i]);
		$format[$i] = "%-$tlen[$i]s ";
		$header .= sprintf($format[$i], $names[$i]);
	}
	return ($tar, \@format, \@tlen, \@names, $header);
}

sub print_lines
{
	my ($header, $tar, $r_tlen, $r_format) = @_;
	my ($i, $j, @row);
	my @lines = @{$tar};
	my @format = @{$r_format};
	my @tlen = @{$r_tlen};
    my $ubar = '_______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________';

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
1;
# vi: set sw=4 ts=4 et:
