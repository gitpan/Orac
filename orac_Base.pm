package orac_Base;
use strict;

###############################################################################
# Generic execute query & auto-format results & print...
###############################################################################
# Take an SQL statement, execute it, and show the results in a matrix-like format.
# ARG1 = the SQL statement
# ARG2 = a title (optional, if not sent, the first 40 chars of the SQL is used)
# ARG3 = text widget to use (optional, if not sent it uses the main one)
# consider adding ARG4, an optional function pointer to do post-processing on a row-by-row basis (useful for interpreting values [e.g. change 'U' to 'Unique', change 262 to 'varchar not null', ...]), how can we tell it concat rows?

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

   # as this is new, how do I know if the user's version has this before I use it?
   my @types;
   @types = @{$sth->{TYPE}} if (exists($sth->{TYPE}));

   my ($j, $i, $len, $just);
   my (@format, $header);

   for ($i=0 ; $i <= $#names ; $i++)
   {

      # default justify to the left and hope for the best!
      $just = '-';
      # as this is new, how do I know if the user's version has this before I use it?
      if (exists($sth->{TYPE}) && defined(DBI::SQL_INTEGER))
      {
         # find the type to set the justification; get these from DBI.pm
         SWITCH: {
            $_ = $types[$i];
            ($_ == DBI::SQL_CHAR) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_VARCHAR) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_DATE) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_TIME) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_TIMESTAMP) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_LONGVARCHAR) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_BINARY) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_VARBINARY) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_LONGVARBINARY) && do { $just = '-'; last SWITCH; };
            ($_ == DBI::SQL_NUMERIC) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_DECIMAL) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_INTEGER) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_SMALLINT) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_BIGINT) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_TINYINT) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_FLOAT) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_REAL) && do { $just = ''; last SWITCH; };
            ($_ == DBI::SQL_DOUBLE) && do { $just = ''; last SWITCH; };
         } # SWITCH
      }

      # get the column name length
      $len = length($names[$i]);
      $tlen[$i] = $len; # comment this out if we do A. below

      # Option A is use the width of the column definition
      # Option B is find the widest value & use that!  (current)
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
      # if I was really good, I'd try to line up decimal points on
      #   floating point numbers, :-) maybe later...
      $format[$i] = "%$just$tlen[$i]s ";
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
################################################
1;
# vi: set sw=3 ts=3 et:
