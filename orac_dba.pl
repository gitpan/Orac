#!/usr/local/bin/perl
################################################################################
# Copyright (c) 1998,1999 Andy Duncan
#
# You may distribute under the terms of either the GNU General Public License
# or the Artistic License,as specified in the Perl README file,with the
# exception that it cannot be placed on a CD-ROM or similar media for commercial
# distribution without the prior approval of the author.
#
# This code is provided with no warranty of any kind,and is used entirely at
# your own risk. This code was written by the author as a private individual,
# and is in no way endorsed or warrantied.
#
# Support questions and suggestions can be directed to andy_j_duncan@yahoo.com
# Download from CPAN/authors/id/A/AN/ANDYDUNC
################################################################################

# Pick up all the standard modules necessary to run the program

use Tk;
#use Carp;
use FileHandle;
use Cwd;
use Time::Local;
use DBI;
use DBI::Shell;
use Tk::DialogBox;
use Tk::Pretty;
use Tk::HList;
require Tk::BrowseEntry;

# Pick up our specialised modules.

use orac_Oracle;
use orac_Informix;
use orac_Sybase;

# Read the menu/language.txt file to pick up all text
# for use with the rest of the program

main::read_language();

# Set up a few defaults, such as the lovely Steelblue2
# for the background colour

$bc = main::get_backgr($lg{def_backgr_col});
$hc = $lg{bar_col};
$ssq = $lg{see_sql};
$ec = $lg{def_fill_fld_col};
$fc = $lg{def_fg_col};

# Bring up the main "Worksheet" window

$mw = MainWindow->new();

# Start work on the menu, with the Orac badge,
# and then build up the menu buttons

my(@layout_mb) = qw/-side top -padx 5 -expand no -fill both/;
$mb = $mw->Frame->pack(@layout_mb);

my $orac_li = $mw->Pixmap(-file=>'img/orac.bmp');
$mb->Label(-image=>$orac_li,-borderwidth=>2,-relief=>'flat')->pack(-side=>'left',-anchor=>'w');

# First of all, provide the only hard-coded menu that we
# do, for functions across all databases

$file_mb = $mb->Menubutton(-text=>$lg{file},-relief=>'raised')->pack(-side=>'left',-padx=>2);
$file_mb->command(-label=>$lg{reconn},
                  -command=>sub{main::get_db()});
$file_mb->command(-label=>$lg{about_orac},
                  -command=>sub{main::bz();main::f_clr();
                                main::about_orac('README');main::ubz()});
$file_mb->command(-label=>$lg{menu_config},
                  -command=>sub{main::bz();main::f_clr();
                                main::about_orac('txt/menu_config.txt');
                                main::ubz()});
$file_mb->separator();

# Build up the colour options, so
# a nice lemonchiffon is possible as a backdrop

$bc_txt = $lg{back_col_menu};
$file_mb->cascade(-label=>$bc_txt);
$bc_men = $file_mb->cget(-menu);
$bc_cols = $bc_men->Menu;

# Now pick up all the lovely colours and build a radiobutton

$file_mb->entryconfigure($bc_txt,-menu=>$bc_cols);
open(COLOUR_FILE, "txt/colours.txt");
while(<COLOUR_FILE>){
   chomp;
   eval {
      $bc_cols->radiobutton(-label=>$_,-background=>$_,
                            -command=>[ sub {main::bc_upd()}],-variable=>\$bc,-value=>$_);
   };
}
close(COLOUR_FILE);

# Now give them the 'Exit Orac' option

$file_mb->separator();
$file_mb->command(-label=>$lg{exit},-command=>sub{main::back_orac()});

# Let them know the state of play, on connections

$l_top_t = $lg{not_conn};
$mb->Label(-textvariable=>\$l_top_t,-relief=>'flat')->pack(-side=>'right',-anchor=>'e');
$v_text = $mw->Scrolled('Text',-wrap=>'none',-cursor=>undef,-foreground=>$fc,-background=>$bc);
$v_text->pack(-expand=>1,-fil=>'both');
tie (*TEXT,'Tk::Text',$v_text);

# Sort out the options to clear the screen on
# each report

$mw->Button(-text=>$lg{clear},-command=>sub{main::bz();main::must_f_clr();main::ubz()})->pack(side=>'left');
$v_clr = 'Y';
$mw->Radiobutton(variable=>\$v_clr,text=>$lg{man_clear},value=>'N')->pack (side=>'left');
$mw->Radiobutton ( variable=>\$v_clr,text=>$lg{auto_clear},value=>'Y')->pack (side=>'left');
$mw->Button(-text=>$lg{reconn},-command=>sub{main::bz();main::get_db();main::ubz()})->pack(side=>'right');

# Set main window title and set window icon

$this_title = 'Orac-' . $lg{orac_pan};
$mw->title($this_title);
main::iconize($mw);

# Sort out which database we're going to be working with
# Once this is done, connect to a database.

$orac_orig_db = 'XXXXXXXXXX';
main::set_curr_db();
$val_con = 0;
main::get_db();

# Here we go, lights, cameras, action!

MainLoop();

# Clear out everything before exiting, and then draw
# those curtains

main::back_orac();

#################### Sub functions begin ####################

# Various sub-functions to clear screen, exit program
# cleanly etc 

sub f_clr {

   # Check out what clearing option has
   # been chosen, and then clear the 
   # screen if appropriate

   if($v_clr eq 'Y'){
      main::must_f_clr();
   }
}
sub must_f_clr {

   # Clear out all the text on the main screen,
   # and anything else that may be lurking like
   # 'See SQL' buttons.

   $v_text->delete('1.0','end');
}
sub back_orac {

   # Back out of program nicely, and save any chosen
   # options in the main configuration file

   if ($val_con){
      $rc  = $dbh->disconnect;
   }
   main::fill_defaults($orac_curr_db, $sys_user, $bc, $v_db);
   exit 0;
}
sub fill_defaults {

   # Make sure defaults the way the user likes 'em.

   my($db_typ, $dba, $bc, $db) = @_;

   open(DB_FIL,'>config/what_db.txt');
   print DB_FIL $db_typ . '^' . $dba . '^' . $bc . '^' . $db . '^' . "\n";
   close(DB_FIL);
}
sub get_connected {

   # Put up dialogue to pick a new database.
   # Allow user to change database type,
   # if they wish.  Also, set flag
   # to help prevent connection
   # error messages, except on the
   # last attempt at connection.

   my $dn = 0;
   $conn_comm_flag = 0;

   if ($val_con == 1){
      main::must_f_clr();
      $rc = $dbh->disconnect;
      $l_top_t = $lg{disconn};
      $val_con = 0;
   }
   do {
      $c_d = $mw->DialogBox(-title=>$lg{login_txt},-buttons=>[ $lg{connect}, $lg{change_dbtyp}, $lg{exit} ]);
      my $l1 = $c_d->Label(-text=>$lg{db} . ':',-anchor=>'e',-justify=>'right');
      $db_list = $c_d->BrowseEntry(-cursor=>undef,-variable=>\$v_db,-foreground=>$fc,-background=>$ec);
      my %ls_db;

      # Pick up all the databases currently available to this user
      # directly from here

      my @h = DBI->data_sources('dbi:' . $orac_curr_db . ':');
      my $h = @h;
      my @ic;
      my $ic;
      for ($i = 1;$i < $h;$i++){
         @ic = split(/:/,$h[$i]);
         $ic = @ic;
         $ls_db{$ic[($ic - 1)]} = 101;
      }
      
      # Supplement these, with stored database to which they've
      # successfully connected in the past 

      open(DBFILE,"txt/" . $orac_curr_db . "/orac_db_list.txt");
      while(<DBFILE>){
         chomp;
         $ls_db{$_} = 102;
      }
      close(DBFILE);

      my $key;
      my @hd;
      undef @hd;
      $i = 0;
      foreach $key (keys %ls_db) {
         $hd[$i] = "$key";
         $i++;
      }
      my @hd2;
      @hd2 = sort @hd;

      foreach(@hd2){
         $db_list->insert('end',$_);
      }

      # Now put up the rest of the widgets with this Dialogue

      my $l2 = $c_d->Label(-text=>$lg{sys_user} . ':',-anchor=>'e',-justify=>'right');
      $ps_u = $c_d->add("Entry",-cursor=>undef,
                        -textvariable=>\$sys_user,-foreground=>$fc,
                        -background=>$ec)->pack(side=>'right');

      my $l3 = $c_d->Label(-text=>$lg{sys_pass} . ':',-anchor=>'e',-justify=>'right');
      $ps_e = $c_d->add("Entry",-cursor=>undef,-show=>'*',-foreground=>$fc,
                        -background=>$ec)->pack(side=>'right');

      my $l4 = $c_d->Label(-text=>$lg{db_type} . ':',-anchor=>'e',-justify=>'right');
      my $l4a = $c_d->Label(-text=>$orac_curr_db,-anchor=>'w',-justify=>'left');

      # Go Grid crazy!  Assign the widgets to starting 
      # racetrack postitions

      Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
      Tk::grid($db_list,-row=>0,-column=>1,-sticky=>'ew');
      Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
      Tk::grid($ps_u,-row=>1,-column=>1,-sticky=>'ew');
      Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');
      Tk::grid($ps_e,-row=>2,-column=>1,-sticky=>'ew');
      Tk::grid($l4,-row=>3,-column=>0,-sticky=>'e');
      Tk::grid($l4a,-row=>3,-column=>1,-sticky=>'ew');

      # Now put up the dialogue on the main screen

      $c_d->gridRowconfigure(1,-weight=>1);
      $db_list->focusForce;
      $mn_b = $c_d->Show;

      # Now verify all input and attempt connection to chosen database

      if ($mn_b eq $lg{connect}) {
         my $v_sys = $ps_u->get;
         if (defined($v_sys) && length($v_sys)){
            my $v_ps = $ps_e->get;
            if (defined($v_ps) && length($v_ps)){

               # Build up Primary database independent initialisation
               # and set all environmental variables required for this database type

               my $db_init_command;
               $db_init_command = 'orac_' . $orac_curr_db . '::' . 'init1_orac_' . $orac_curr_db . '()';
               eval $db_init_command ; warn $@ if $@;

               # Now attempt connection, first tell user what we're doing

               $l_top_t = $lg{connecting};
               main::bz();

               # Try a double whammy on connecting, to help out
               # various operating systems. Set a flag
               # to later suppress connection errors,
               # except on the last one.  Try the full connection
               # option first, the one needed for NT.

               $data_source_1 = 'dbi:' . $orac_curr_db . ':';
               $data_source_2 = 'dbi:' . $orac_curr_db . ':' . $v_db;

               $conn_comm_flag = 1;

               main::connector($data_source_2, $v_sys, $v_ps);
               if (defined($DBI::errstr)){
                  eval $db_init_command ; warn $@ if $@;

                  # Set flag, to now allow proper warnings, on the last
                  # attempted connection

                  $conn_comm_flag = 0;
                  main::connector($data_source_1, $v_sys, $v_ps);
               }
               $conn_comm_flag = 0;

               if (!defined($DBI::errstr)){
                  $dn = 1;
                  $val_con = 1;
                  if ((!defined($ls_db{$v_db})) || ($ls_db{$v_db} != 102)){

                     # If we connected successfully to a new database, store
                     # this fact, and put it in the browse option for later use

                     open(DBFILE,">>txt/" . $orac_curr_db . "/orac_db_list.txt");
                     print DBFILE "$v_db\n";
                     close(DBFILE);
                  }
                  $l_top_t = "$v_db";
                  $sys_user = $v_sys;
               } else {
                  $l_top_t = "";
               }
               main::ubz();
            } else {
               # Various error messages for invalid input

               main::mes($mw,$lg{system_please});
            }
         } else {
            main::mes($mw,$lg{user_please});
         }
      } elsif ($mn_b eq $lg{change_dbtyp}) {
         
         # User may have decided to change database type 

         $orac_curr_db = main::select_dbtyp(2);
      } else {
         $dn = 1;
      }
   } until $dn;

   # Ok, we're done here.  Now Orac can start work.  Stand by your beds.
}
sub connector {
   $dbh = DBI->connect($_[0], $_[1], $_[2]);
}
sub select_dbtyp {

   # User may either be picking default database type for the first
   # time, or changing database type.  Either way, build up
   # dialogue to allow them to do this.

   my ($option) = @_;
   my $mess;
   my $tit;
   my $loc_db;
   if ($option == 1){
      $mess = $lg{please_pick_db};
      $tit = $lg{new_dbtyp};
   } else {
      $mess = $lg{db_change_mess};
      $tit = $lg{change_dbtyp};
      $loc_db = $orac_curr_db;
   }
   my $dn = 0;
   do {
      my $d = $mw->DialogBox(-title=>$tit);
      my $l1 = $d->Label(-text=>$mess,-anchor=>'n')->pack(-side=>'top');
      my $l2 = $d->Label(-text=>$lg{db_type} . ':',-anchor=>'e',-justify=>'right');
      my $b_d = $d->BrowseEntry(-cursor=>undef,-variable=>\$loc_db,
                                -foreground=>$fc,-background=>$ec,-width=>40);
   
      # Check out which DBs we're currently allowed to pick from

      open(DB_FIL,'config/all_dbs.txt');
      my $i = 0;
      while(<DB_FIL>){
         my @hold = split(/\^/, $_);
         if (($option == 1) && ($i == 0)) {
            $loc_db = $hold[0];
            $i++;
         }
         $b_d->insert('end', $hold[0]);
      }
      close(DB_FIL);
      
      # It's grid crazy time again.  Don't ya love it!

      Tk::grid($l1,-row=>0,-column=>1,-sticky=>'e');
      Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
      Tk::grid($b_d,-row=>1,-column=>1,-sticky=>'ew');
      $d->gridRowconfigure(1,-weight=>1);
      $d->Show;
   
      # Check out that that they the correct DBI module loaded.
      # If not, give them a politically correct virtual slap!

      my $db_init_command = 'DBI->data_sources(\'dbi:' . $loc_db . ':\');';
      eval $db_init_command;
      if ($@) {
         warn $@;
         main::mes($mw,$lg{wrong_dbi});
      } else {
         $dn = 1;
      }
   } until $dn;

   # A successful connection means we store the variable for later

   # Pick up the standard DBA user for the particular database
   ($sys_user,$v_db) = get_dba_user($loc_db);
   main::fill_defaults($loc_db, $sys_user, $bc, $v_db);

   return $loc_db;
}
sub get_dba_user {
   my($db) = @_;
   my $dba_user;
   my $new_db;

   # Picks up the typical DBA user for the particular database

   open(DB_FIL,'config/all_dbs.txt');
   while(<DB_FIL>){
      my @hold = split(/\^/, $_);
      if ($db eq $hold[0]){
         $dba_user = $hold[1];
         $new_db = $hold[2];
      }
   }
   close(DB_FIL);
   return ($dba_user,$new_db);
}
sub get_db {
   # Picks up database, and then configures menus accordingly

   main::get_connected();
   unless ($val_con){
     main::back_orac();
   }
   # Build up 2nd database independent initialisation

   my $db_init_command;
   $db_init_command = 'orac_' . $orac_curr_db . '::' . 'init2_orac_' . $orac_curr_db . '()';
   eval $db_init_command ; warn $@ if $@;

   # Now sort out Jared's tools and configurable menus
   if ($orac_orig_db ne $orac_curr_db){

      # We do this, if either we're into the program for the first time,
      # or the user has changed the database type

      main::del_Jareds_tools();
      main::config_menu();
      main::Jareds_tools();
      main::read_format();
      $orac_orig_db = $orac_curr_db;
   }
}
sub see_plsql {
 
   # Helps put up a button on the page, so that the generative 
   # SQL code can be viewed for validation purposes

   my ($res,$dum) = @_;
   my $b = $v_text->Button(-text=>$ssq,-command=>sub{main::see_sql($mw,$res)});
   print TEXT "\n\n  ";
   $v_text->window('create','end',-window=>$b);
   print TEXT "\n\n";
}
sub see_sql {

   # Produce the box that contains the viewable SQL

   $_[0]->Busy;
   my $d = $_[0]->DialogBox(-title=>$ssq);
   my $t = $d->Scrolled('Text',-height=>16,-width=>60,-wrap=>'none',
                        -cursor=>undef,-foreground=>$fc,-background=>$bc);
   $t->pack(-expand=>1,-fil=>'both');
   tie (*THIS_TEXT,'Tk::Text',$t);
   print THIS_TEXT "$_[1]\n";
   main::orac_Show($d);
   $_[0]->Unbusy;
}
sub about_orac {
   # Slap up the various files onto the
   # main TEXT widget

   my $print_out = main::gf_str($_[0]);
   print TEXT $print_out;
}
# generic file into a string
sub gf_str
{
    my $file = $_[0];
    my $rt = "";

    if (-r $file)
    {
        open(SQL, "<$file") or return "ERROR:  can not open $file\n";
        $rt = $rt . $_ while(<SQL>);
        close(SQL);
    }
    return $rt;
}
sub bz {
   # Make the main GUI pointer go busy
   $mw->Busy;
}
sub ubz {
   # Make the main GUI pointer normalise to unbusy
   $mw->Unbusy;
}
sub orac_print {

   # Prints out a named text file, into the main window

   my ($file) = @_;
   open (ORAC_PRINT,"txt/$file.txt");
   while(<ORAC_PRINT>){
      print TEXT $_;
   }
   close(ORAC_PRINT);
}
sub f_str {

   # Takes a SQL module name, and sequence number,
   # and then returns the SQL code stored in the
   # appropriate file, as a Perl string variable

   my($sub,$number) = @_;
   my $rt = "";

   if(defined($sub) && defined($number)){
      my $file = sprintf("%s.%s.sql",$sub,$number);
      open(SQL,"sql/$orac_curr_db/$file");
      while(<SQL>){
         $rt = $rt . $_;
      }
      close(SQL);
   }
   return $rt;
}
sub crt_rp_do {

   # Helps chop up strings for report formatting purposes

   $g_frm = shift;
   $^A = "";
   @vals = @_;
   eval { formline($g_frm,@vals); };
   if ($@){
      print "$@ \n";
   }
   return $^A;
}
sub crt_frm {

   # Given certain parameters, helps build up
   # a format string to help report output

   my $frm_format = shift;
   my $flag = shift;
   my $ln = shift;
   my @arr = split(/,/,$frm_format);
   my $len_arr = @arr;
   my $format = "";
   my $i;
   my $j;
   my $part_1;
   my $part_2;
   my $sub_form = '^';
   my $sub_bit;
   my @lines;

   # While we're doing this formatting, build up
   # the underlines for each title header as well 
   # via the @lines array

   for($i = 1;$i < $len_arr;$i++){
      ($part_1,$part_2) = split(/:/, $arr[$i]);
      if ($part_1 eq 'l'){
         $sub_bit = '<';
      } else {
         $sub_bit = '>';
      }
      $lines[($i - 1)] = '-';
      for($j = 1;$j < $part_2;$j++){
         $sub_form = $sub_form . $sub_bit;
         $lines[($i - 1)] = $lines[($i - 1)] . '-';
      }
      $format = $format . $sub_form;
      $sub_form = ' ^';
   }

   # Ok, this is a kludge, but it's a kludge that
   # works, so don't knock it :)

   $format = $format . 'xyzzyxxyzzyx ~~';
   $j = @_;
   for($i = 0;$i < $j;$i++){
      if(!defined($_[$i])){
         $_[$i] = ' ';
      }
   }
   main::cr_prt($format,$flag,$ln,@_);
   if($arr[0] eq 't'){
      main::cr_prt($format,$flag,$ln,@lines);
   }
}
sub cr_prt {

   # Prints out the variably formatted reports, and
   # slaps out the report results into the main
   # Worksheet window
   
   my $format = shift;
   my $flag = shift;
   my $ln = shift;
   my $string = crt_rp_do($format, @_);
   $string =~ s/xyzzyxxyzzyx/\n/g;
   if((defined($flag)) && ($flag > 0) && ($flag != 2)){
      chomp($string);
   }
   print TEXT $string;
      
   if ((defined($flag)) && (($flag == 1)||($flag == 3))){
      if ($ln > 0){
         # We may have set up special flaggings for these?
 
         # First of all, get all the array bits and pieces into a string of
         # potential variable values.

         my $bit_string;
         my @loc_arr = @_;
         my $loc_arr_count = @loc_arr;
         my $i;

         for ($i = 0;$i < $loc_arr_count;$i++){
            $bit_string = $bit_string . '\'' . $loc_arr[$i] . '\'';

            # Remember to stick commas between the variable values

            unless ($i == ($loc_arr_count - 1)){
               $bit_string = $bit_string . ', ';
            }
         }

         # Now build up command, and execute.

         my $db_init_command;
         $db_init_command = 'orac_' . $orac_curr_db . '::' . 
                            'init4_orac_' . $orac_curr_db . 
                            '($flag,' . $bit_string . ')';
         eval $db_init_command ; warn $@ if $@;
      }
      print TEXT "\n";
   }
}
sub get_Jared_sql {

   # Takes pointers to which cascade and button the user
   # wishes to run, and sucks SQL info out of the appropriate
   # file, before returning as a Perl string variable

   my($casc,$butt) = @_;
   my $filename = 'tools/sql/' . $casc . '.' . $butt . '.sql';
   my $cm = '';
   open(JARED_FILE, "$filename");
   while(<JARED_FILE>){
      $cm = $cm . $_;
   }
   close(JARED_FILE);
   return $cm;
}
sub prp_lp {

   # This is the main workhorse function of the Orac program.

   # It takes the title of the report, then the SQL module number,
   # then the SQL module number.  It then takes the appropriate
   # reporting format, then a special flag, which is normally zero.
   # Non-zero values for the flag can be used to do more than
   # the ordinary printing of a standard report.
   
   $tit = shift;
   $sub = shift;
   $num = shift;
   $frm = shift;
   $flag = shift;

   # Once we have the main guaranteed parameters, the calling function
   # may also have sent in a number of variable values to bind
   # in later.  If it has, shuffle the deck and get these sorted out.

   my @bindee = @_;
   my $num_bind = @bindee;
   my $cm;

   # Work out the format, and the command string

   if($sub eq 'Jared_cascade_button'){
      $cm = main::get_Jared_sql($bindee[0],$bindee[1]);
      $frm = main::get_frm($cm,5);
      $num_bind = 0;
   } else {
      if((length($sub) > 0) && (length($num) > 0) ){
         $cm = main::f_str($sub,$num);
      }
   }

   # For special cases however, we may want $cm
   # to be a bit different.

   my $db_init_command;
   $db_init_command = '($cm,$frm) = orac_' . $orac_curr_db . 
                                    '::' . 'init3_orac_' . $orac_curr_db . 
                                    '($cm,$sub,$frm)';
   eval $db_init_command ; warn $@ if $@;

   # Now prepare the SQL.  If approriate, bind in the calling
   # parameters

   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 

   if ($num_bind > 0){
      my $i;
      for ($i = 1;$i <= $num_bind;$i++){
         $sth->bind_param($i,$bindee[($i - 1)]);
      }
   }

   # Get the information, and print out the rows.
   # Don't forget the underlined titles, and say
   # 'no rows found' if appropriate.
   # If required, give user a button to view SQL.

   $sth->execute;
   my $detected = 0;
   while (@res = $sth->fetchrow) {
      if (($detected == 0) && ($flag >= 0)){
         main::tit_do($detected,$tit,$frm,$sth,$flag);
      }
      $detected++;
      main::crt_frm(('b,' . $frm),$flag,$detected,@res);
   }
   if (($detected == 0) && ($flag >= 0)){
      main::tit_do($detected,$tit,$frm,$sth);
      print TEXT "$lg{no_rows_found}\n";
   }
   if(($flag == 0)||($flag == 1)||($flag == -2)||($flag == 3)){
      see_plsql( $sth->{"Statement"} );
   }
   $sth->finish;
   return $cm;
} 
sub get_time {
   my($time_type) = @_;

   # Pick up the system time

   my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

   # As everything has come out of the ctime 'struct', a few
   # of them go from zero upwards, so let's turn them into
   # more sensible real world values

   $mon = $mon + 1;
   $year = $year + 1900;
   $wday = $wday + 1;
   $yday = $yday + 1;

   my $time;
   if($time_type == 1){
      $time = sprintf("%02d:%02d:%02d %02d/%02d/%04d", $hour, $min, $sec,
                                                       $mday, $mon, $year);
   } else {
      $time = sprintf("%02d:%02d:%02d %02d/%02d/%04d", $hour, $min, $sec,
                                                       $mday, $mon, $year);
   }
   return $time;
}
sub tit_do {

   # Work out the title, from some handy DBI variables.

   my($detect,$tit,$frm,$sth,$flag) = @_;
   if((defined($tit)) && ((length($tit) > 0))){
      main::rep_tit($tit);
   }
   my @tit_vals;
   my $i;
   for ($i = 0;$i < $sth->{NUM_OF_FIELDS};$i++){
      $tit_vals[$i] = $sth->{NAME}->[$i];
   }
   main::crt_frm(('t,' . $frm),$flag,$detect,@tit_vals);
}
sub rep_tit {
   my($title) = @_;
   print TEXT "$lg{report} $title ($v_db " . main::get_time(1) . "):\n\n";
}
sub get_frm {

   # We may occasionally wish to generate formats on-the-fly.
   # If this is required, this is where we do it.

   my($cm,$min_len) = @_;
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $sth->execute;
   my $ret;
   if (@res = $sth->fetchrow) {
      my $i = 0;
      my $str = "";
      for($i = 0;$i < $sth->{NUM_OF_FIELDS};$i++){
         $str = $sth->{NAME}->[$i];
         my $l = length($str);
         if ($l < $min_len){ 
            $l = $min_len;
         }
         if($i == 0){
            $ret = 'r:' . $l;
         } else {
            $ret = $ret . ',r:' . $l;
         }
      }
   }
   $sth->finish;
   return $ret;
}
sub mes {

   # Orac messaging Dialogue function.  Have you
   # ever seen a program without one of these?

   my $d = $_[0]->DialogBox();
   $d->Label(text=>$_[1])->pack();
   main::orac_Show($d);
}
sub orac_Show {

   # The standard Dialogue "Show" functionality is a bit
   # too clumsy for Orac.  Here we refine it's operation
   # a little, to make window sizing a little nicer
   # for Orac users.

   my($d) = @_;
   my $old_focus = $d->focusSave;
   my $old_grab = $d->grabSave;
   $d->Subwidget("top")->pack(fill=>'both',expand=>'y');
   $d->Subwidget("bottom")->pack(expand=>'n');
   $d->Popup();
   $d->grab;
   $d->waitVisibility;
   $d->focus;
   $d->waitVariable(\$d->{"selected_button"});
   $d->grabRelease;
   $d->withdraw;
   &$old_focus;
   &$old_grab;
}
sub bc_upd {

   # Change the background colour on all open windows.
   # This is where all those text and window handles
   # come in useful.

   eval {
      $v_text->configure(-background=>$bc);
   };
   my $comp_str = "";
   my $i;
   for ($i = 0;$i < $global_sub_win_count;$i++){
      if (defined($sw[$i])){
         $comp_str = $sw[$i]->state;
         if("$comp_str" ne 'withdrawn'){
            eval {
               $sw_hand[$i]->configure(-background=>$bc);
            }
         }
      }
   }
}
sub read_language {

   # Open up the main configurable
   # language file, and pick up all
   # the strings required by Orac

   open(TITLES_FILE, "txt/language.txt");
   my $lhand;
   my $rhand;
   while(<TITLES_FILE>){
      ($lhand,$rhand) = split(/\^/, $_);
      $lg{$lhand} = $rhand;
   }
   close(TITLES_FILE);
}
sub read_format {

   # Pick up the database dependent configurable 
   # report formats, and load into variables

   open(FRM_F, "txt/$orac_curr_db/format.txt");
   my $lhand;
   my $rhand;
   while(<FRM_F>){
      chomp;
      ($lhand,$rhand) = split(/\^/, $_);
      $rfm{$lhand} = $rhand;
   }
   close(FRM_F);
}
sub config_menu {

   # Read the database dependent menu configuration
   # file, and build up menus.

   my $i;
   my $func_line_ct;
   my $menu_command = "";

   $global_sub_win_count = 0;

   # Does a configurable menu currently exist?
   # If so, destroy it.

   $tm_but_ct = 0;
   if(defined(@tm_but)){
      my $i;
      my $ct = @tm_but;
      for ($i = ($ct - 1);$i >= 0;$i--){
         $tm_but[$i]->destroy();
      }
      @tm_but = undef;
   }
   $tm_but_ct = -1;

   # Initialize variables to prevent
   # warnings

   my $file = "menu/$orac_curr_db/menu.txt";
   open(MENU_F, $file);
   while(<MENU_F>){
      chomp;
      $chop_bit = $_;
      @menu_line = split(/\^/, $chop_bit);
      if ($menu_line[0] eq 'Menubutton'){
         $menu_command = $menu_command . 
                         ' $tm_but_ct++; ' . "\n" .
                         ' $tm_but[$tm_but_ct] = ' . "\n" .
                         ' $mb->Menubutton(-text=>$lg{' . $menu_line[1] . '},' . "\n" .
                         ' -relief=>\'raised\')->pack(-side=>\'left\',-padx=>2); ' . "\n";
      }
      if (($menu_line[0] eq 'command') || ($menu_line[0] eq 'casc_command')){
         if ($menu_line[1] ne '0'){
            $menu_command = $menu_command . ' $swc{' . $menu_line[1] . '} = ' . 
                            $global_sub_win_count . ';' . "\n";
            $menu_command = $menu_command . ' $sw_flg[' . 
                            $global_sub_win_count . '] = ';
            $global_sub_win_count++;
         }

         if ($menu_line[0] eq 'command'){
            $menu_command = $menu_command . 
                            ' $tm_but[$tm_but_ct]->command(-label=>$lg{' . 
                            $menu_line[3] . '},' . 
                            ' -command=>sub{main::bz();';
         } elsif ($menu_line[0] eq 'casc_command'){
            $menu_command = $menu_command . ' 
                            $casc_item->command(-label=>$lg{' . 
                            $menu_line[3] . '},' . 
                            ' -command=>sub{main::bz();';
         }
         if ($menu_line[2] == 1){
            $menu_command = $menu_command . ' main::f_clr(); ';
         }
         $menu_command = $menu_command . $menu_line[4] . '(';

         if(defined($menu_line[5])){
            # Now build the function's parameters we're going to run.
            # (if any parameters exist)

            @func_line = split(/\+/, $menu_line[5]);
            $func_line_ct = @func_line;
   
            for ($i = 0;$i < $func_line_ct;$i++){
               $menu_command = $menu_command . $func_line[$i];
               if (($i + 1) < $func_line_ct){
                  $menu_command = $menu_command . ', ';
               }
            }
         }
         $menu_command = $menu_command . ');main::ubz()}); ' . "\n";
      }
      if ($menu_line[0] eq 'separator'){
         $menu_command = $menu_command . ' $tm_but[$tm_but_ct]->separator(); ' . "\n";
      }
      if ($menu_line[0] eq 'cascade'){
         $menu_command = $menu_command . 
                         ' $tm_but[$tm_but_ct]->cascade(-label=>$lg{' . 
                         $menu_line[1] . '}); ' . "\n" .
                        ' $casc = $tm_but[$tm_but_ct]->cget(-menu); ' . "\n" .
                        ' $casc_item = $casc->Menu; ' . "\n" .
                        ' $tm_but[$tm_but_ct]->entryconfigure($lg{' . 
                        $menu_line[1] . '}, -menu => $casc_item); ' . "\n";
      }
   }
   close(MENU_F);

   # Here we go!  Slap up those menus.

   eval $menu_command ; warn $@ if $@;
}
sub Jareds_tools {

   # Build up the 'My Tools' menu option.

   if(!defined($jt)){
      $comm_str = 
          ' $jt = $mb->Menubutton(-text=>$lg{my_tools},-relief=>\'raised\',-borderwidth=>2,-menuitems=> ' . "\n" .
     ' [[Button=>$lg{help_with_tools},' .
     ' -command=>sub{main::bz();main::f_clr();main::orac_print(\'help_with_tools\');main::ubz()}], ' . "\n" .
     '  [Cascade=>$lg{config_tools},-menuitems => ' . "\n" .
     '   [[Button=>$lg{config_add_casc},-command=>sub{main::bz();main::config_Jared_tools(1);main::ubz()},], ' . "\n" .
     '    [Button=>$lg{config_edit_casc},-command=>sub{main::bz();main::config_Jared_tools(6);main::ubz()},], ' . "\n" .
     '    [Button=>$lg{config_del_casc},-command=>sub{main::bz();main::config_Jared_tools(2);main::ubz()},], ' . "\n" .
     '    [Separator=>\'\'], ' . "\n" .
     '    [Button=>$lg{config_add_butt},-command=>sub{main::bz();main::config_Jared_tools(3);main::ubz()},], ' . "\n" .
     '    [Button=>$lg{config_edit_butt},-command=>sub{main::bz();main::config_Jared_tools(7);main::ubz()},], ' . "\n" .
     '    [Button=>$lg{config_del_butt},-command=>sub{main::bz();main::config_Jared_tools(4);main::ubz()},], ' . "\n" .
     '    [Separator=>\'\'], ' . "\n" .
     '    [Button=>$lg{config_edit_sql},-command=>sub{main::bz();main::config_Jared_tools(5);main::ubz()},],], ' . "\n" .
     '  ], ' . "\n" .
     ' [Separator=>\'\'], ' . "\n";

      if(open(JT_CASC,'tools/config.tools')){
         while(<JT_CASC>){
            @jt_casc = split(/\^/, $_);
            if ($jt_casc[0] eq 'C'){
               $comm_str = $comm_str . ' [Cascade  =>\'' . $jt_casc[2] . '\',-menuitems => [ ' . "\n";
               open(JT_CASC_BUTTS,'tools/config.tools');
               while(<JT_CASC_BUTTS>){
                  @jt_casc_butts = split(/\^/, $_);
                  if (($jt_casc_butts[0] eq 'B') && ($jt_casc_butts[1] eq $jt_casc[1])){
                     $comm_str = $comm_str . 
                        ' [Button=>\'' . $jt_casc_butts[3] . '\',-command=>sub{main::bz(); main::f_clr(); ' . "\n" .
                        ' main::run_Jareds_tool(\'' . $jt_casc[1] . '\',\'' . $jt_casc_butts[2] . '\');main::ubz()}], ' . "\n";
                  }
               }
               close(JT_CASC_BUTTS);
               $comm_str = $comm_str . ' ],], ' . "\n";
            }
         }
         close(JT_CASC);
      }
      $comm_str = $comm_str . ' ])->pack(-side=>\'left\',-padx=>2) ; ';
      eval $comm_str ; warn $@ if $@;
   }
}
sub save_sql {

   # Pick up the SQL the user has entered, and
   # save it into the appropriate file

   my($filename) = @_;
   main::orac_copy($filename,"${filename}.old");
   open(SAV_SQL,">$filename");
   print SAV_SQL $sw_hand[$swc{ed_butt_win}]->get("1.0", "end");
   close(SAV_SQL);
   $ed_sql_txt_cnt++;
   $ed_sql_txt = "$ed_fl_txt: $filename $lg{saved}" . ' #' . $ed_sql_txt_cnt;
}
sub ed_butt {

   # Allow configuration of 'My Tools' menus, buttons, cascades, etc

   my($casc,$butt) = @_;
   $ed_fl_txt = main::get_butt_text($casc,$butt);
   $sql_file = 'tools/sql/' . $casc . '.' . $butt . '.sql';
   if(!defined($swc{ed_butt_win})){
      $swc{ed_butt_win} = $global_sub_win_count;
      $global_sub_win_count++;
   }
   $sw[$swc{ed_butt_win}] = MainWindow->new();
   $sw[$swc{ed_butt_win}]->title("$lg{cascade} $casc, $lg{button} $butt");
   $ed_sql_txt = "$ed_fl_txt: $lg{ed_sql_txt}";
   $ed_sql_txt_cnt = 0;
   $sw[$swc{ed_butt_win}]->Label( -textvariable  => \$ed_sql_txt, -anchor=>'n', -relief=>'groove')->pack(-expand=>'no');
   $sw_hand[$swc{ed_butt_win}] = $sw[$swc{ed_butt_win}]->Scrolled('Text',-wrap=>'none',-cursor=>undef,
                      -foreground=>$fc,-background=>$bc)->pack(-expand=>'yes',-fill=>'both');
   my(@lay) = qw/-side bottom -padx 5 -fill both -expand no/;
   my $f = $sw[$swc{ed_butt_win}]->Frame->pack(@lay);
   $f->Button(-text=>$lg{exit},
              -command=>sub{$sw[$swc{ed_butt_win}]->withdraw()})->pack(-side=>'right',-anchor=>'e');
   $f->Button(-text=>$lg{save},-command=>sub{main::save_sql($sql_file)})->pack(-side=>'right',-anchor=>'e');
   $f->Label(-text=>$lg{no_semi_colon},-relief=>'sunken')->pack(-side=>'left',-anchor=>'w');
   main::iconize($sw[$swc{ed_butt_win}]);

   if(open(SQL_SAV,$sql_file)){
      while(<SQL_SAV>){ $sw_hand[$swc{ed_butt_win}]->insert("end", $_); }
      close(SQL_SAV);
   }
}
sub config_Jared_tools {

   # More functionality required to allow on-the-fly configuration
   # of the 'My Tools' options.

   # This function is fairly overloaded, and may require some
   # detailed analysis, before it becomes clearer what it's doing.

   my($param,$loc_casc,$loc_butt) = @_;
   my $main_check;
   my $title;
   my $action;
   my $inp_text;
   if(($param == 1)||($param == 99)||($param == 69)||($param == 49)){
      $main_check = 'C';
      $title = $lg{add_cascade};
      my $main_field = 1;
      my $main_inp_value;
      my $add_text = $lg{casc_text};
      $action = $lg{add};
      if($param == 69){
         $title = $lg{upd_cascade};
         $action = $lg{upd};
      } elsif($param == 49) {
         $main_check = 'B';
         $title = "$lg{cascade} $loc_casc, $lg{button}";
         $add_text = $lg{upd_button};
         $action = $lg{upd};
      } elsif($param == 99) {
         $main_field = 2;
         $main_check = 'B';
         $title = "$lg{cascade} $loc_casc: $lg{add_button}";
         $add_text = $lg{butt_text};
      }
      if(($param == 69)||($param == 49)){
         $main_inp_value = $loc_casc;
      } else {
         my @inp_value;
         my $inp_count = 0;
         if(open(JT_CONFIG,'tools/config.tools')){
            while(<JT_CONFIG>){
               my @hold = split(/\^/, $_);
               if ((($param == 1) && ($hold[0] eq $main_check)) ||
                   (($param == 99) && ($hold[0] eq $main_check) && ($hold[1] eq $loc_casc))) {
      
                  $inp_value[ $inp_count ] = $hold[ $main_field ];
                  $inp_count++;
               }
            }
            close(JT_CONFIG);
         }
         if($inp_count > 0){
            $inp_count--;
            my $flag = 0;
            my $flag2 = 0;
            $main_inp_value = 1;
            while($flag == 0){
               my $i;
               $flag2 = 0;
               for ($i = 0;$i <= $inp_count;$i++){
                  if($main_inp_value == $inp_value[$i]){
                     $main_inp_value++;
                     $flag2 = 1;
                     last;
                  }
               }
               if ($flag2 == 0){
                  $flag = 1;
               }
            }
         } else {
            $main_inp_value = 1;
         }
         $main_inp_value = sprintf("%03d", $main_inp_value);
      }

      # Now get to main dialogue and pick up the reqd. info

      my $d = $mw->DialogBox(-title=>"$title $main_inp_value",-buttons=>[ $action,$lg{cancel} ]);
      my $l = $d->Label(-text=>$add_text . ':',-anchor=>'e',-justify=>'right');
      $inp_text = '';
      if(($param == 69)||($param == 49)){
         open(JT_CONFIG_READ,'tools/config.tools');
         while(<JT_CONFIG_READ>){
            my @hold = split(/\^/, $_);
            if($param == 69){
               if (($hold[0] eq $main_check) && ($hold[1] eq $loc_casc)){
                  $inp_text = $hold[2];
               }
            } elsif($param == 49){
               if (($hold[0] eq $main_check) && ($hold[1] eq $loc_casc) && ($hold[2] = $loc_butt)){
                  $inp_text = $hold[3];
               }
            }
         }
         close(JT_CONFIG_READ);
      }
      $cs = $d->add("Entry",-textvariable=>\$inp_text,-cursor=>undef,-foreground=>$fc,
                     -background=>$ec,-width=>40)->pack(side=>'right');
      Tk::grid($l,-row=>0,-column=>0,-sticky=>'e');
      Tk::grid($cs,-row=>0,-column=>1,-sticky=>'ew');

      $d->gridRowconfigure(1,-weight=>1);
      my $rp = $d->Show;
      if ($rp eq $action) {
         if (defined($inp_text) && length($inp_text)){
            if(($param == 69)||($param == 49)){
               return (1,$inp_text);
            } else {
               open(JT_CONFIG_APPEND,'>>tools/config.tools');
               if($param == 1){
                  print JT_CONFIG_APPEND $main_check . '^' . $main_inp_value . '^' . $inp_text . '^' . "\n";
               } elsif($param == 99) {
                  print JT_CONFIG_APPEND $main_check . '^' . $loc_casc . '^' . $main_inp_value . '^' . $inp_text . '^' . "\n";
               }
               close(JT_CONFIG_APPEND);
               main::sort_Jareds_file();
               if($param == 99){
                  main::ed_butt($loc_casc,$main_inp_value);
               }
            }
         } else {
            main::mes($d,$lg{no_val_def});
            if($param == 69){
               return (0,$inp_text);
            }
         }
      }
   } elsif(($param == 2)||($param == 3)||($param == 4)||
           ($param == 5)||($param == 6)||($param == 7)||
           ($param == 59)||($param == 79)||($param == 89)){
      my $d_inp;
      my $b_d;
      my $tl;
      my $l;
      my @casc1;
      my @casc2;
      my $d;
      my $message;

      $main_check = 'C';
      my $del_text = $lg{casc_text};
      if($param == 2){
         $title = $lg{del_cascade};
         $action = $lg{del};
         $message = $lg{del_message};
      } elsif($param == 3) {
         $title = $lg{add_button};
         $action = $lg{next};
         $message = $lg{add_butt_mess};
      } elsif($param == 4) {
         $title = $lg{del_button};
         $action = $lg{next};
         $message = $lg{del_butt_mess};
      } elsif($param == 5) {
         $title = $lg{config_edit_sql};
         $action = $lg{next};
         $message = $lg{ed_sql_mess};
      } elsif($param == 6){
         $title = $lg{config_edit_casc};
         $action = $lg{next};
         $message = $lg{choose_casc};
      } elsif($param == 7){
         $sec_check = 'B';
         $title = $lg{config_edit_butt};
         $action = $lg{next};
         $message = $lg{choose_casc};
      } elsif($param == 59) {
         $main_check = 'B';
         $title = $lg{config_edit_butt};
         $action = $lg{next};
         $message = "$lg{cascade} $loc_casc: $lg{choose_butt}";
         $del_text = $lg{choose_butt};
      } elsif($param == 79) {
         $main_check = 'B';
         $title = $lg{config_edit_sql};
         $action = $lg{next};
         $message = $lg{ed_sql_mess2};
      } elsif($param == 89) {
         $main_check = 'B';
         $title = $lg{del_button};
         $action = $lg{del};
         $message = "$lg{cascade} $loc_casc: $lg{del_butt_mess2}";
         $del_text = $lg{del_butt_text};
      }

      my $i_count = 0;
      if(open(JT_CONFIG,'tools/config.tools')){
         while(<JT_CONFIG>){
            my @hold = split(/\^/, $_);
            if(($param != 89) && ($param != 79) && ($param != 59)){
               if ($hold[0] eq $main_check){
                  $casc1[$i_count] = sprintf("%03d",$hold[1]) . ":$hold[2]";
                  $i_count++;
               }
            } else {
               if (($hold[0] eq $main_check) && ($hold[1] eq $loc_casc)){
                  $casc1[$i_count] = sprintf("%03d",$hold[2]) . ":$hold[3]";
                  $i_count++;
               }
            }
         }
      }
      if ($i_count > 0){
         @casc2 = sort @casc1;
         $i_count = 0;
         foreach(@casc2){
            if($i_count == 0){
               $d = $mw->DialogBox(-title=>$title,-buttons=>[ $action,$lg{cancel} ]);
               $t_l = $d->Label(-text=>$message,-anchor=>'n')->pack(-side=>'top');
               $l = $d->Label(-text=>$del_text . ':',-anchor=>'e',-justify=>'right');
               $d_inp = $casc2[$i_count];
               $b_d = $d->BrowseEntry(-cursor=>undef,-variable=>\$d_inp,-foreground=>$fc,-background=>$ec,-width=>40);
            }
            $b_d->insert('end', $casc2[$i_count]);
            $i_count++;
         }
         close(JT_CONFIG);
   
         Tk::grid($t_l,-row=>0,-column=>1,-sticky=>'e');
         Tk::grid($l,-row=>1,-column=>0,-sticky=>'e');
         Tk::grid($b_d,-row=>1,-column=>1,-sticky=>'ew');
         $d->gridRowconfigure(1,-weight=>1);
         my $rp = $d->Show;
         if ($rp eq $action) {
            my $fin_inp = sprintf("%03d", split(/:/,$d_inp));
            my $sec_inp;
            my $ed_txt;
            if (defined($fin_inp) && length($fin_inp)){
               if(($param == 2)||($param == 59)||($param == 89)||($param == 6)||($param == 7)) {
                  my $safe_flag = 0;
                  if($param == 6) {
                     ($safe_flag,$ed_txt) = main::config_Jared_tools(69,$fin_inp);
                  } elsif($param == 7) {
                     ($safe_flag,$sec_inp) = main::config_Jared_tools(59,$fin_inp);
                     if ((defined($safe_flag)) && (length($safe_flag)) && ($safe_flag == 1)){
                        ($safe_flag,$ed_txt) = main::config_Jared_tools(49,$fin_inp,$sec_inp);
                     }
                  } elsif($param == 59) {
                     $safe_flag = 0;
                     return (1,$fin_inp);
                  } else {
                     $safe_flag = 1;
                  }
                  if ((defined($safe_flag)) && (length($safe_flag)) && ($safe_flag == 1)){
                     main::orac_copy('tools/config.tools','tools/config.tools.old');
                     open(JT_CONFIG_READ,'tools/config.tools.old');
                     open(JT_CONFIG_WRITE,'>tools/config.tools');
                     while(<JT_CONFIG_READ>){
                        chomp;
                        my @hold = split(/\^/, $_);
                        if($param == 2){
                           unless ($hold[1] eq $fin_inp){
                              print JT_CONFIG_WRITE "$_\n";
                           }
                        } elsif($param == 6){
                           unless (($hold[0] eq $main_check) && ($hold[1] eq $fin_inp)){
                              print JT_CONFIG_WRITE "$_\n";
                           } else {
                              print JT_CONFIG_WRITE $hold[0] . '^' . $hold[1] . '^' . $ed_txt . '^' . "\n";
                           }
                        } elsif($param == 7){
                           unless (($hold[0] eq $sec_check) && ($hold[1] eq $fin_inp) && ($hold[2] eq $sec_inp)){
                              print JT_CONFIG_WRITE "$_\n";
                           } else {
                              print JT_CONFIG_WRITE $hold[0] . '^' . $hold[1] . '^' . $hold[2] . '^' . $ed_txt . '^' . "\n";
                           }
                        } else {
                           unless (($hold[0] eq $main_check) && ($hold[1] eq $loc_casc) && ($hold[2] eq $fin_inp)){ 
                              print JT_CONFIG_WRITE "$_\n";
                           }
                        }
                     }
                     close(JT_CONFIG_READ);
                     close(JT_CONFIG_WRITE);
                     main::sort_Jareds_file();
                  }
               } elsif($param == 3) {
                  main::config_Jared_tools(99,$fin_inp);
               } elsif($param == 5) {
                  main::config_Jared_tools(79,$fin_inp);
               } elsif($param == 79) {
                  my $filename = 'tools/sql/' . $loc_casc . '.' . $fin_inp . '.sql';
                  main::ed_butt($loc_casc,$fin_inp);
               } else {
                  main::config_Jared_tools(89,$fin_inp);
               }
            } else {
               main::mes($d,$lg{no_val_def});
            }
         }
      } else {
         main::mes($mw,$lg{no_cascs});
         if ($param == 59){
            return (0,'');
         }
      }
   }
   main::del_Jareds_tools();
   main::Jareds_tools();
}
sub sort_Jareds_file {
   main::orac_copy('tools/config.tools','tools/config.tools.sort');
   open(JT_CONFIG_READ,'tools/config.tools.sort');
   my @file_read;
   my @file_write;
   my $i_count = 0;
   while(<JT_CONFIG_READ>){
      chomp;
      $file_read[$i_count] = $_;
      $i_count++;
   }
   close(JT_CONFIG_READ);

   open(JT_CONFIG_WRITE,'>tools/config.tools');
   @file_write = sort @file_read;
   $i_count = 0;
   foreach(@file_write){
      print JT_CONFIG_WRITE "$file_write[$i_count]\n";
      $i_count++;
   }
   close(JT_CONFIG_WRITE);
}
sub get_butt_text {

   # Pick up more information on the configurable buttons

   my($casc,$butt) = @_;
   my $title = '';
   open(JARED_FILE,'tools/config.tools');
   while(<JARED_FILE>){
      my @hold = split(/\^/, $_);
      if(($hold[0] eq 'B') && ($hold[1] eq $casc) && ($hold[2] eq $butt)){
         $title = $hold[3];
      }
   }
   close(JARED_FILE);
   return $title;
}
sub run_Jareds_tool {

   # When user selects their own button, run the 
   # associated report

   my($casc,$butt) = @_;
   my $title = '';
   $title = main::get_butt_text($casc,$butt);
   main::prp_lp($title,'Jared_cascade_button','0','0',0,$casc,$butt);
}
sub del_Jareds_tools {

   # If the 'My Tools' menu currently exists, then
   # destroy it

   if(defined($jt)){
      $jt->destroy();
      $jt = undef;
   }
}
sub orac_copy {

   # This is to avoid Orac becoming OS dependent.
   # Obviously, on UNIX it would be easy to write
   # system("cp $file1 $file2");, but this would
   # make us dependent on UNIX.  Hopefully, this
   # function provided file copying functionality
   # without tying Orac down to the OS.

   my($ammo,$target) = @_;
   if(open(ORAC_AMMO,"$ammo")){
      if(open(ORAC_TARGET,">${target}")){
         while(<ORAC_AMMO>){
            print ORAC_TARGET $_;
         }
         close(ORAC_TARGET);
      }
      close(ORAC_AMMO);
   }
}
sub iconize {

   # Take a Window handle, and tie an icon 
   # to it.

   my($w) = @_;
   my $icon_img = $w->Photo('-file' => 'img/orac_med.gif');
   $w->Icon('-image' => $icon_img);
}
sub set_curr_db {

   # This allows user to select main database type.

   my $i = 0;
   my $file = 'config/what_db.txt';
   if(-e $file){
      open(DB_FIL,$file);
      while(<DB_FIL>){
         my @hold = split(/\^/, $_);
         $orac_curr_db = $hold[0];
         $sys_user = $hold[1];
         $v_db = $hold[3];
         $i = 1;
      }
      close(DB_FIL);
   }
   if ($i == 0){
      $orac_curr_db = main::select_dbtyp(1);
   }
}
sub get_backgr {
   my($col) = @_;

   # Find out the default colour.  If they're isn't one,
   # assign the one already given.

   my $file = 'config/what_db.txt';

   if(-e $file){
      open(DB_FIL, $file);
      while(<DB_FIL>){
         my @hold = split(/\^/, $_);
         $col = $hold[2];
      }
      close(DB_FIL);
   }
   return $col;
}
BEGIN {

   # If any non-fatal warnings/errors are detected by
   # Orac, this should ensure they come up in "look-and-feel"
   # window.  Particularly useful for reporting back
   # database error messages.

   # We have one program flag for suppressing error messages
   # on database connection, until the last variation
   # on database connection is attempted.

   $SIG{__WARN__} = sub{
      if ((!defined($conn_comm_flag)) || ($conn_comm_flag == 0)){
         if (defined $mw) {
            main::mes($mw,$_[0]);
         } else {
            print STDOUT join("\n",@_),"n";
         }
      }
   };
}
