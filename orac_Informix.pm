#use strict;
#use pretty_print; # for serious debugging
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
   # hmm, don't know what to do if we don't have these, can we croak to a 
   # dialog?
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
############# Database dependent code functions below here #####################
# show the list of the databases, and info about them
sub onstat_databases
{
    # Do your stuff
    orac_Base::show_sql(main::f_str("Databases", "1"));
}
# show the list of DBSpaces, and info about them
sub onstat_dbspaces
{
    # Do your stuff
    orac_Base::show_sql(main::f_str("DBSpaces", "1"));
}
# the the list of DB chunks and info about them
sub onstat_chunks
{
    # Do your stuff
    orac_Base::show_sql(main::f_str("Chunks", "1"));
}
# show the current $ONCONFIG file
sub onstat_onconfig_params
{
    # Do your stuff
    $main::v_text->insert('end', main::gf_str("$ENV{INFORMIXDIR}/etc/$ENV{ONCONFIG}"));
}
# show the extents being used & check for errors
sub oncheck_extents
{
    # Do your stuff
    #orac_Base::show_sql(main::f_str("Extents", "1"));
    # IT MAY not BE POSSIBLE TO DO THIS VIA THE SMI TABLES!!!
    execute_and_display("$ENV{INFORMIXDIR}/bin/oncheck -pe ", 1);
}
# show physical & logical log status
sub onstat_log_rep
{
    # Do your stuff
    orac_Base::show_sql(main::f_str("LogRpt", "1"));
    # IT MAY not BE POSSIBLE TO DO THIS VIA THE SMI TABLES!!!
    execute_and_display("$ENV{INFORMIXDIR}/bin/oninit -l ", 0);
}
# display a logical log [postponed]
#sub onlog_log
#{
#    # Do your stuff
#    orac_Base::show_sql(main::f_str("ShowLog", "1"));
#}
# show synonyms
sub dbschema_syns
{
    # Do your stuff
    orac_Base::show_sql(main::f_str("Synonyms", "1"));
}
#sub dbschema_procs
#{
#    # Do your stuff
#    orac_Base::show_sql(main::f_str("Procedures", "1"));
#}
#sub dbschema_proc_list
#{
#    # Do your stuff
#    orac_Base::show_sql(main::f_str("ProcedureBody", "1"));
#}
# show grants on this database (kevin: start here for getting sql)
sub dbschema_grants
{
    # Do your stuff
    orac_Base::show_sql(main::f_str("Grants", "1"));
}
sub dbschema_indices
{
    # Do your stuff
    orac_Base::show_sql(main::f_str("Indicies", "1"));
}
sub dbschema_schema
{
    # Do your stuff
    #orac_Base::show_sql(main::f_str("Schema", "1"));

    # IN THEORY, IT SHOULD BE POSSIBLE TO DO THIS VIA THE SMI TABLES, BUT HOW?!!!
    execute_and_display("$ENV{INFORMIXDIR}/bin/dbschema -d ", 1);
}
sub onstat_threads
{
    # Do your stuff
    orac_Base::show_sql(main::f_str("Threads", "1"));
}
sub onstat_curr_sql
{
    # Do your stuff
    #orac_Base::show_sql(main::f_str("CurrSQL", "1"));
    # IN THEORY, IT SHOULD BE POSSIBLE TO DO THIS VIA THE SMI TABLES, BUT HOW?!!!
    execute_and_display("$ENV{INFORMIXDIR}/bin/onstat -u ", 0);
}
sub onstat_blobs
{
    # Do your stuff
    orac_Base::show_sql(main::f_str("Blobs", "1"));
}
sub finderr_num
{
    # Do your stuff
    # IT IS not POSSIBLE TO DO THIS VIA THE SMI TABLES!!!
    execute_and_display("$ENV{INFORMIXDIR}/bin/dbschema -d ", 1);
}
sub onstat_io_profile
{
    # Do your stuff
    #orac_Base::show_sql(main::f_str("IOProfile", "1"));
    main::live_update(main::f_str("IOProfile", 1), $main::lg{oi_io_profile_title});
}
sub onstat_locks_held
{
    # Do your stuff
    main::live_update(main::f_str("Locks", 1), $main::lg{locks_held});
}
sub execute_and_display
{
    # Yes Andy, i know i'm cheating BIG TIME here, but i *REALLY* want
    # every button to do something useful.  I'll pull these out as fast
    # as i can!  but i just can't figure out how to do some of these!
    #
    # Late breaking news, i've found that a some of the informix info is
    # only available via the utility programs, as they read directly from
    # shared memory, or from binary encoded disk files. :-(  The ones
    # that fall in this category are so marked.

    my $db = $main::v_db;
    $db =~ s/@.*//o;
    my $cmd = $_[0];
    $cmd .= $db if ($_[1]);
    $cmd .= " 2>&1";
    $main::v_text->insert('end', "$cmd\n");
    open(IN, "$cmd|") or do { $main::v_text->insert('end', "FAILED!\n"); return; };
    while (<IN>) { $main::v_text->insert('end', $_); }
    close(IN);
}
###############################################################################
# Generic support functions
###############################################################################
sub gn_hl
{
   package main;

   # Main parent function for generic HLists for database objects.

   ($g_typ,$g_hlst,$gen_sep) = @_;

   $g_mw = $mw->DialogBox(-title=>"$g_hlst $v_db");
   $hlist = $g_mw->Scrolled('HList', -drawbranch=>1,
                                     -separator=>$gen_sep,
                                     -indent=>50,
                                     -width=>50,
                                     -height=>20,
                                     -foreground=>$fc,
                                     -background=>$bc);
   $hlist->configure(-command => sub { orac_Informix::show_or_hide_tab($_[0]) });
   $hlist->pack(fill=>'both', expand=>'y');
   
   $open_folder_bitmap = $g_mw->Bitmap(-file=>Tk->findINC('openfolder.xbm'));
   $closed_folder_bitmap = $g_mw->Bitmap(-file=>Tk->findINC('folder.xbm'));
   $file_bitmap = $g_mw->Bitmap(-file=>Tk->findINC('file.xbm'));

   my $no_txt;
   my $yes_txt;
   if ($g_hlst eq $lg{tabs}){
      $no_txt = $lg{orig_exts};
      $yes_txt = $lg{compr_extnts};
   } else {
      $no_txt = $lg{no_ln_nums};
      $yes_txt = $lg{ln_nums};
   }
   $v_yes_no_txt = 'N';
   $g_mw->Radiobutton(-variable=>\$v_yes_no_txt,-text=>$no_txt,-value=>'N')->pack (side=>'left');
   $g_mw->Radiobutton(-variable=>\$v_yes_no_txt,-text=>$yes_txt,-value=>'Y')->pack (side=>'left');
   
   undef %all_the_owners;

   my $cm = main::f_str( orac_Informix::hl_trans($g_hlst) ,'1');
print STDERR "prepare1: $cm\n" if ($main::debug > 0);
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;

   while (@res = $sth->fetchrow) {
      my $owner = $res[0];
      $hlist->add($owner,-itemtype=>'imagetext',-image=>$closed_folder_bitmap,-text=>$owner);
      $all_the_owners{"$owner"} = 'closed';
   }
   $sth->finish;
   main::orac_Show($g_mw);
}

sub show_or_hide_tab
{
   package main;

   # Works out which level of the Hierarchical list we're on,
   # and then displays the results accordingly.

   my $hlist_thing = $_[0];
   if(!$all_the_owners{"$hlist_thing"}){
      orac_Informix::do_a_generic($hlist_thing, 'Normal', 'dum');
      return;
   } else {
      if($all_the_owners{"$hlist_thing"} eq 'closed'){
         $hlist->info('next', $hlist_thing);
         $hlist->entryconfigure($hlist_thing,-image=>$open_folder_bitmap);
         $all_the_owners{"$hlist_thing"} = 'open';
         
         orac_Informix::add_generics($hlist_thing);
      } else {
         $hlist->entryconfigure($hlist_thing,-image=>$closed_folder_bitmap);
         $hlist->delete('offsprings', $hlist_thing);
         $all_the_owners{"$hlist_thing"} = 'closed';
      }
   }
}
sub add_generics {
   package main;

   # Adds more boxes to the HList widgets.
   # On the 2nd level of an HList

   $g_mw->Busy;
   my $owner = $_[0];
   if ($g_typ == 1){
      my $s = main::f_str( orac_Informix::hl_trans($g_hlst) ,'2');
print STDERR "prepare2: $s ($owner)\n" if ($main::debug > 0);
      my $sth = $dbh->prepare( $s ) || die $dbh->errstr; 
      $sth->bind_param(1,$owner);
      $sth->execute;
      while (@res = $sth->fetchrow) {
         # if the result has multiple columns, assume there will only be 1 row,
         # but we should display the columns as rows; but there there is only
         # 1 column, assume we'll get multiple rows/fetchs
         if ($#res > 0)
         {
             for (0 .. $#res)
             {
                 my $gen_thing = "$owner.$sth->{NAME}->[$_] = $res[$_]";
                 $hlist->add($gen_thing,-itemtype=>'imagetext',-image=>$file_bitmap,-text=>$gen_thing);
             }
             last;
         }
         else
         {
             my $gen_thing = "$owner" . $gen_sep . "$res[0]";
             $hlist->add($gen_thing,-itemtype=>'imagetext',-image=>$file_bitmap,-text=>$gen_thing);
         }
      }
      $sth->finish;
   } else {
      my $gen_thing = "$owner" . $gen_sep . 'sql';
      $hlist->add($gen_thing,-itemtype=>'imagetext',-image=>$file_bitmap,-text=>$gen_thing);
   }
   $g_mw->Unbusy;
}
sub do_a_generic {
   package main;

   # On the final (3rd) level of an HList, does the actual work required.

   my ($input,$do_what_flag,$second_hlist) = @_;
   $g_mw->Busy;
   my $owner;
   my $generic;
   my $dum;
   if ($gen_sep eq ":"){
      ($owner, $generic, $dum) = split(/:/, $input);
   } else {
      ($owner, $generic, $dum) = split(/\./, $input);
   }
   my $loc_g_hlst;
   if ($g_hlst eq $lg{rolegrnts}){
      $loc_g_hlst = $lg{usergrant};
   } else {
      if($do_what_flag eq 'Normal'){
         $loc_g_hlst = $g_hlst;
      } else {
         $loc_g_hlst = $second_hlist;
      }
   }
   my $cm = main::f_str( orac_Informix::hl_trans($loc_g_hlst) ,'3');

   #$dbh->func(1000000, 'dbms_output_enable');
print STDERR "prepare3: $cm\n" if ($main::debug > 0);
   my $second_sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   if($g_typ == 1){
      $second_sth->bind_param(1,$owner);
      $second_sth->bind_param(2,$generic);
      if (($loc_g_hlst eq $lg{tabs})){
         $second_sth->bind_param(3,$v_yes_no_txt);
      } 
      elsif ($loc_g_hlst eq $lg{comments}){
         $second_sth->bind_param(3,$owner);
         $second_sth->bind_param(4,$generic);
      }
   } else {
      unless ($loc_g_hlst eq $lg{usergrant}){
         $second_sth->bind_param(1,$owner);
      } else {
         my $i;
         for ($i = 1;$i <= 4;$i++){
            $second_sth->bind_param($i,$owner);
         }
      }
   }
   $second_sth->execute;

   my $d = $g_mw->DialogBox();

   $d->add("Label",-text=>"$loc_g_hlst $lg{sql_for} $owner.$generic")->pack(side=>'top');
   $l_txt = $d->Scrolled('Text',-height=>16,-wrap=>'none',-cursor=>undef,-foreground=>$fc,-background=>$bc);
   $l_txt->pack(-expand=>1,-fil=>'both');
   tie (*L_TEXT, 'Tk::Text', $l_txt);

   my $j = 0;
   my $full_list;
   my $i = 1;

   while($j < 10000){
      #$full_list = scalar $dbh->func('dbms_output_get');
      if(!defined($full_list)){
         last;
      }
      if((length($full_list)) == 0){
         last;
      }
      if (($v_yes_no_txt eq 'N') || ($g_hlst eq $lg{tabs})){
         print L_TEXT "$full_list\n";
      } else {
         printf L_TEXT "%5d: %s\n", $i, $full_list;
         $i++;
      }
      $j++;
   }
   print L_TEXT "\n\n  ";

   my @b;
   $b[0] = $l_txt->Button(-text=>$ssq,-command=>sub{main::see_sql($d,$cm)});
   $l_txt->window('create', 'end',-window=>$b[0]);

   if ($loc_g_hlst eq $lg{tabs}){
      print L_TEXT "\n\n  ";
      my(@tab_options) = qw/$lg{indexs} $lg{constrnts} $lg{trggrs} $lg{comments}/;
      my $i = 1;
      foreach ($lg{indexs},$lg{constrnts},$lg{trggrs},$lg{comments}){
         my $this_txt = $_;
         $b[$i] = $l_txt->Button(-text=>"$this_txt",-command=>sub{orac_Informix::do_a_generic($input,'Recursive',"$this_txt")});
         $l_txt->window('create', 'end',-window=>$b[$i]);
         print L_TEXT " ";
         $i++;
      }
      print L_TEXT "\n\n  ";
      $b[$i] = $l_txt->Button(-text=>$lg{form},
               -command=>sub{$d->Busy;orac_Oracle::univ_form($d,$owner,$generic,'form');$d->Unbusy });
      $l_txt->window('create', 'end',-window=>$b[$i]);
      $i++;
      print L_TEXT " ";
      $b[$i] = $l_txt->Button(-text=>$lg{build_index},
               -command=>sub{$d->Busy;orac_Oracle::univ_form($d,$owner,$generic,'index');$d->Unbusy });
      $l_txt->window('create','end',-window=>$b[$i]);
   } elsif ($loc_g_hlst eq $lg{views}){
      print L_TEXT "\n\n  ";
      $b[1] = $l_txt->Button(-text=>$lg{form},
              -command=>sub{$d->Busy;orac_Oracle::univ_form($d,$owner,$generic,'form');$d->Unbusy });
      $l_txt->window('create', 'end',-window=>$b[1]);
   }
   print L_TEXT "\n\n";
   main::orac_Show($d);
   $g_mw->Unbusy;
}
sub hl_trans {
   package main;

   # In case the users of Orac change the 
   # txt/language.txt file, unfortunately Orac
   # still needs to translate the new information
   # in order to pick up the right PL/SQL files.
   # This is where it does it.

   my($inp) = @_;
   my $out=$inp;
   if ($inp eq $lg{tabs}){ $out = 'Tables'; }
   elsif ($inp eq $lg{indexs}){ $out = 'Indexes'; }
   elsif ($inp eq $lg{views}){ $out = 'Views'; }
   elsif ($inp eq $lg{synyms}){ $out = 'Synonyms'; }
   elsif ($inp eq $lg{seqs}){ $out = 'Sequences'; }
   elsif ($inp eq $lg{usergrant}){ $out = 'UserGrants'; }
   elsif ($inp eq $lg{rolegrnts}){ $out = 'RoleGrants'; }
   elsif ($inp eq $lg{lnks}){ $out = 'Links'; }
   elsif ($inp eq $lg{users}){ $out = 'Users'; }
   elsif ($inp eq $lg{rols}){ $out = 'Roles'; }
   elsif ($inp eq $lg{profiles}){ $out = 'Profiles'; }
   elsif ($inp eq $lg{procs}){ $out = 'Procedures'; }
   elsif ($inp eq $lg{funcs}){ $out = 'Functions'; }
   elsif ($inp eq $lg{trggrs}){ $out = 'Triggers'; }
   elsif ($inp eq $lg{pck_hds}){ $out = 'PackageHeads'; }
   elsif ($inp eq $lg{pck_bods}){ $out = 'PackageBods'; }
   elsif ($inp eq $lg{snaps}){ $out = 'Snapshots'; }
   elsif ($inp eq $lg{snap_logs}){ $out = 'SnapshotLogs'; }
   elsif ($inp eq $lg{constrnts}){ $out = 'Constraints'; }
   elsif ($inp eq $lg{comments}){ $out = 'Comments'; }
   return $out;
}
###############################################################################
1;
# vi: set sw=4 ts=4 et:
