package orac_Oracle;

sub init0_orac_Oracle {
   # Does nothing in Oracle yet
}
sub init1_orac_Oracle {
   package main;

   # Set all environmental variable required for DBD::Oracle

   $ENV{TWO_TASK} = $v_db;
   $ENV{ORACLE_SID} = $v_db;
}
sub init2_orac_Oracle {
   package main;

   # Get the block size, as soon as we
   # logon to a database.  Saves us having to 
   # continually find it out again, and again.

   my $cm = main::f_str('get_db','1');
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $sth->execute;
   ($Block_Size) = $sth->fetchrow;
   $sth->finish;

   $cm = ' select user_id from dba_users ' .
         ' where username = \'' . $v_sys . '\' ';
   $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $sth->execute;
   ($v_user_id) = $sth->fetchrow;
   $sth->finish;

   # Enable the PL/SQL memory area, for this 
   # database connection

   $dbh->func(1000000,'dbms_output_enable');
}
sub init3_orac_Oracle {
   package main;

   my($cm,$sub,$frm) = @_;

   # Pick up secondary SQL select strings
   # for various more complex operations

   if($sub eq 'sel_addr'){
      $cm = orac_Oracle::get_sel_stat('sys','v_$session');
      $frm = main::get_frm($cm,8);
      $cm = $cm . ' where paddr = ? ';
   } elsif($sub eq 'database_info'){
      $cm = orac_Oracle::get_sel_stat('sys','v_$database');
      $frm = main::get_frm($cm,8);
   }
   return($cm,$frm);
}
sub init4_orac_Oracle {
   package main;

   my $flag = shift;

   # Add secondary buttons onto main worksheet
   # to allow user to drill down a bit more into
   # the target information

   if ($flag == 1){
      my $os_user = $_[7];
      my $oracl_user = $_[6];
      my $sid = $_[9];

      my $b = 
         $v_text->Button(
            -text=>$lg{sql_quest},-padx=>0,-pady=>0,
            -command=>sub{ $mw->Busy;
                           orac_Oracle::who_what( $flag,
                                                  $os_user,
                                                  $oracl_user,
                                                  $sid);
                           $mw->Unbusy }
                        );

      $v_text->window('create', 'end',-window=>$b);
   }
   elsif ($flag == 3){

      # Initialise to a number, as it comes through as a string

      my $stat = 0;

      $stat = $_[0];

      my $b = 
         $v_text->Button(
            -text=>"$lg{stat} $stat",
            -padx=>0,
            -pady=>0,
            -command=>sub{ $mw->Busy;
                           orac_Oracle::who_what($flag,$stat);
                           $mw->Unbusy }
                        );

      $v_text->window('create', 'end',-window=>$b);

   }
}

################ Database dependent code functions below here ##################

sub what_sql {
   package main;

   # This can be a long running report on what SQL is currently
   # being used.  Check with user they're prepared to sit
   # and wait

   my $d_txt = $lg{are_you_sure};
   my $chk_d = $mw->DialogBox(-buttons=>[ $lg{yes},$lg{no} ]);
   $chk_d->add("Label",-text=>$d_txt)->pack();
   my $b = $chk_d->Show;
   if($b eq $lg{yes} ){
      main::prp_lp($lg{what_sql},'what_sql','1',$rfm{r8_opt4},0);
   }
}
sub tune_wait {
   package main;

   # Works out if anything is waiting in the database

   main::prp_lp($lg{sess_wt_stats},'tune_wait','1',$rfm{r4_wait},0);
   main::about_orac('txt/Oracle/tune_wait.1.txt');
}
sub tune_pigs {
   package main;

   # This function gives you two differing reports
   # which measure the Shared Pool disk reads
   # for various SQL statements in the library

   my($type_flag)=@_;

   my $title;

   if($type_flag == 1){
      # If type 1, then we only want the highest 
      # summarised readings
      $title = $lg{mem_hogs1};
   }
   elsif($type_flag == 2){
      # If type 1, then we only want the highest 
      # summarised readings
      $title = $lg{mem_hogs2};
   }
   # Report for finding SQL monsters

   my $cm = main::f_str( 'tune_pigs' , $type_flag );
   orac_Base::show_sql( $cm , $title );

}
sub get_sel_stat {
   package main;

   # Returns a string of an on-the-fly
   # SQL select statement to get required
   # info out of a particular table

   my($owner,$table) = @_;

   my $cm = " select column_name from dba_tab_columns where " .
            " upper(owner) = upper('${owner}') and " .
            " upper(table_name) = upper('${table}') " . 
            " order by column_id ";

   my $ret = " select ";
   my $i = 0;
   my $bit_str;

   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $sth->execute;

   while (@res = $sth->fetchrow) {
      if ($i == 0){
         $bit_str = ' ';
         $i++;
      } else {
         $bit_str = ' , ';
      }
      $ret = $ret . $bit_str . $res[0] . ' ';
   }
   $sth->finish;
   $ret = $ret . "\n" . 'from ' . $owner . '.' . $table . " \n";
   return $ret;
}
sub who_what {
   package main;

   # Works out who is holding whom, so we can unblock
   # needless locking.

   my ($flag,$param1,$oracle_user,$sid) = @_;

   my $title;
   if($flag == 1){
      $title = "$param1 $lg{investgn}";
   } elsif ($flag == 3){
      $title = "$lg{statis} $param1";
   }
   my $d = $mw->DialogBox(-title=>$title
                         );

   my $loc_text = $d->Scrolled('Text',
                               -wrap=>'none',
                               -cursor=>undef,
                               -foreground=>$fc,
                               -background=>$bc
                              );

   $loc_text->pack(-expand=>1,-fil=>'both');

   tie (*TEXT, 'Tk::Text', $loc_text);
   my $cm;

   if($flag == 1){

      $cm = main::prp_lp(   $lg{hold_sql},
                            'who_what',
                            '1',
                            $rfm{r8_what},
                            2,
                            $param1,
                            $oracle_user,
                            $sid
                        );

   } elsif ($flag == 3){

      $cm = main::prp_lp(   "$lg{sess_mem}", 
                            "$lg{statis} $param1",
                            'statter',
                            '1',
                            $rfm{r3_split},
                            2,
                            $param1
                        );

   }
   my $b = $loc_text->Button(-text=>$ssq,
                             -command=>sub{main::see_sql($d,$cm)}
                            );

   $loc_text->window('create','end',-window=>$b);
   tie (*TEXT, 'Tk::Text', $v_text);
   main::orac_Show($d);
}
sub all_stf {
   package main;

   # Takes particular PL/SQL statements,
   # and generates DDL to recreate ALL of a 
   # particular object in the database.

   my $cm = main::f_str($_[0],$_[1]);
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   my $i;
   for ($i = 1;$i <= $_[2];$i++){
      $sth->bind_param($i,'%');
   }
   $sth->execute;
   $i = 0;
   my $ls;
   while($i < 20000){
      $ls = scalar $dbh->func('dbms_output_get');
      if ((!defined($ls)) || (length($ls) == 0)){
         last;
      }
      print TEXT "$ls\n";
      $i++;
   }
   main::see_plsql($cm);
}
sub orac_create_db {
   package main;

   # Generates a script with which you can
   # completely regenerate the skeleton of your
   # database

   my ($oracle_sid,$dum) = split(/\./, $v_db);
   my $cm = main::f_str('orac_create_db','1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->bind_param(1,$oracle_sid);
   $sth->execute;

   my $j = 0;
   while($j < 10000){
      $full_list = scalar $dbh->func('dbms_output_get');
      if ((!defined($full_list))|| (length($full_list) == 0)){
         last;
      }
      print TEXT "$full_list\n";
      $j++;
   }
   main::see_plsql($cm);
}
sub selected_error {
   package main;

   # Pumps out information on a particular error

   my ($err_bit) = @_;
   main::f_clr();
   my ($owner,$object) = split(/\./, $err_bit);

   main::prp_lp(   "$lg{comp_errs_for} $err_bit",
                   'selected_error',
                   '1',
                   $rfm{r5_errors},
                   0,
                   $owner,
                   $object
               );

}

sub univ_form { 

   package main;

   # A complex function for generating on-the-fly Forms
   # for viewing database information

   ($loc_d,$own,$obj,$uf_type) = @_;

   $m_t = "$lg{form_for} $obj";
   my $bd = $loc_d->DialogBox(-title=>$m_t,-buttons=>[ $lg{exit} ]);
   my $uf_txt;
   if ($uf_type eq 'index'){
      $uf_txt = "$own.$obj, $lg{sel_cols}";
   } else {
      $uf_txt = "$lg{prov_sql} $lg{sel_info}";
   }
   $bd->Label(-text=>$uf_txt,-anchor=>'n')->pack();

   my $t = $bd->Scrolled('Text',
                         -height=>16,
                         -wrap=>'none',
                         -cursor=>undef,
                         -foreground=>$fc,
                         -background=>$bc
                        );

   my $cm = main::f_str('selected_dba','1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr;
   $sth->bind_param(1,$own);
   $sth->bind_param(2,$obj);
   $sth->execute;

   my @h_t = ($lg{i_col},$lg{i_sel_sql},$lg{i_dat_typ},$lg{i_ord});
   for $i (0..3){
      unless (($uf_type eq 'index') && ($i == 2)){
         if ($i == 3){
            $w = $t->Entry(-textvariable=>\$h_t[$i],-cursor=>undef,-width=>3);
         } else {
            $w = $t->Entry(-textvariable=>\$h_t[$i],-cursor=>undef);
         }
         $w->configure(-background=>$fc,-foreground=>$ec);
         $t->windowCreate('end',-window=>$w);
      }
   }
   $t->insert('end', "\n");

   my @res;
   my @c_t;
   my @t_t;
   $ind_bd_cnt = 0;
   while (@res = $sth->fetchrow) {
      $c_t[$ind_bd_cnt] = $res[0];
      $w = $t->Entry(-textvariable=>\$c_t[$ind_bd_cnt],-cursor=>undef);
      $t->windowCreate('end',-window=>$w);

      unless ($uf_type eq 'index'){

         $sql_entry[$ind_bd_cnt] = "";

         $w = $t->Entry(   -textvariable=>\$sql_entry[$ind_bd_cnt],
                           -cursor=>undef,
                           -foreground=>$fc,
                           -background=>$ec
                       );

         $t->windowCreate('end',-window=>$w);

      }
      $t_t[$ind_bd_cnt] = "$res[1] $res[2]";

      $w = $t->Entry( -textvariable=>\$t_t[$ind_bd_cnt],
                      -cursor=>undef);

      $t->windowCreate('end',-window=>$w);

      $i_ac[$ind_bd_cnt] = "$res[0]";

      $i_uc[$ind_bd_cnt] = 0;

      $w = $t->Checkbutton( -variable=>\$i_uc[$ind_bd_cnt],
                            -relief=>'flat');

      $t->windowCreate('end',-window=>$w);

      $t->insert('end', "\n");
      $ind_bd_cnt++;
   }
   $ind_bd_cnt--;
   $sth->finish;
   $t->configure(-state=>'disabled');
   $t->pack(-expand =>1,-fill=>'both');

   my(@lb) = qw/-side bottom/;
   my $bb = $bd->Frame->pack(@lb);

   if ($uf_type eq 'index'){
      $uf_txt = 'Build Index';
   } else {
      $uf_txt = $lg{sel_info};
   }

   $bb->Button( -text=>$uf_txt,
                -command=>sub{ $bd->Busy;
                               orac_Oracle::selector($bd,$uf_type);
                               $bd->Unbusy}
              )->pack (-side=>'right', 
                       -anchor=>'e');

   main::orac_Show($bd);
}

sub selector {

   package main;

   # User may wish to narrow search for info, down to 
   # a particular set of rows, and order these rows.
   # This function allows them to do that.

   my($sel_d,$uf_type) = @_;

   if ($uf_type eq 'index'){
      orac_Oracle::build_ord($sel_d,$uf_type);
      return;
   }
   $l_sel_str = ' select ';
   for $i (0..$ind_bd_cnt){
      if ($i != $ind_bd_cnt){
         $l_sel_str = $l_sel_str . "$i_ac[$i], ";
      } else {
         $l_sel_str = $l_sel_str . "$i_ac[$i] ";
      }
   }
   $l_sel_str = $l_sel_str . "\nfrom ${own}.${obj} ";
   my $flag = 0;
   my $last_one = 0;
   for $i (0..$ind_bd_cnt){
      if ($i_uc[$i] == 1){
         $flag = 1;
         $last_one = $i;
      }
   }
   my $where_bit = "\nwhere ";
   for $i (0..$ind_bd_cnt){
      my $sql_bit = $sql_entry[$i];
      if (defined($sql_bit) && length($sql_bit)){
         $l_sel_str = $l_sel_str . $where_bit . "$i_ac[$i] $sql_bit ";
         $where_bit = "\nand ";
      }
   }
   orac_Oracle::build_ord($sel_d,$uf_type);
   orac_Oracle::and_finally($sel_d,$l_sel_str);
}
sub and_finally {
   package main;

   my($af_d,$cm) = @_;

   # Now we've built up our full SQL statement for this table,
   # fill a Perl array with everything and display it.

   $ary_ref = $dbh->selectall_arrayref($cm);
   $min_row = 0;
   $max_row = @$ary_ref;
   if ($max_row == 0){
      main::mes($af_d,$lg{no_rows});
   } else {
      $gc = $min_row;
      $c_d = $af_d->DialogBox(-title=>$m_t);
      my(@lb) = qw/-anchor n -side top -expand 1 -fill both/;
      my $top_frame = $c_d->Frame->pack(@lb);
   
      my $t = $top_frame->Scrolled('Text',
                                   -height=>16,
                                   -wrap=>'none',
                                   -cursor=>undef,
                                   -foreground=>$fc,
                                   -background=>$bc);

      for my $i (0..$ind_bd_cnt) {
         $lrg_t[$i] = "";
         $w = $t->Entry(-textvariable=>\$i_ac[$i],
                        -cursor=>undef);
         $t->windowCreate('end',-window=>$w);
   
         $w = $t->Entry(-textvariable=>\$lrg_t[$i],
                        -cursor=>undef,
                        -foreground=>$fc,
                        -background=>$ec,
                        -width=>40);

         $t->windowCreate('end',-window=>$w);
         $t->insert('end', "\n");
      }
      $t->configure(-state=>'disabled');
      $t->pack(@lb);

      $c_br = $c_d->Frame->pack(-before=>$top_frame,
                                -side=>'bottom',
                                -expand=>'no');
   
      $gen_sc = 
         $c_br->Scale( 
             -orient=>'horizontal',
             -label=>"$lg{rec_of} " . $max_row,
             -length=>400,
             -sliderrelief=>'raised',
             -from=>1,-to=>$max_row,
             -tickinterval=>($max_row/8),
             -command=>[ sub {orac_Oracle::calc_scale_record($gen_sc->get())} ]
                     )->pack(side=>'left');

      $c_br->Button(-text=>$ssq,-command=>sub{main::see_sql($c_d,$l_sel_str)}
                   )->pack(side=>'right');
      orac_Oracle::go_for_gold();
      main::orac_Show($c_d);
   }
   undef $ary_ref;
}
sub calc_scale_record {
   package main;

   # Whizz backwards and forwards through the records

   my($sv) = @_;
   $gc = $sv - 1;
   orac_Oracle::go_for_gold();
}
sub go_for_gold {
   package main;

   # Work out which row of information to display,
   # and then display it.

   my $curr_ref = $ary_ref->[$gc];
   for my $i (0..$ind_bd_cnt) {
      $lrg_t[$i] = $curr_ref->[$i];
   }
   $gen_sc->set(($gc + 1));
}
sub build_ord {
   package main;

   # It all gets a bit nasty here.  This works out
   # the user's intentions on how to order their
   # required information.

   my($bl_d,$uf_type) = @_;
   my $l_chk = 0;
   for $i (0..$ind_bd_cnt){
      if ($i_uc[$i] == 1){
         $l_chk = 1;
      }
   }
   if ($l_chk == 1){
      orac_Oracle::now_build_ord($bl_d,$uf_type);
      if ($uf_type eq 'index'){
         orac_Oracle::really_build_index($bl_d,$own,$obj);
      } else {
         $l_sel_str = $l_sel_str . "\norder by ";
         for my $cl (1..$tot_i_cnt){
            $l_sel_str = $l_sel_str . "$tot_ind_ar[$ih[$cl]] ";
            if ($dsc_n[$ih[$cl]] == 1){
               $l_sel_str = $l_sel_str . "desc ";
            }
            if ($cl != $tot_i_cnt){
               $l_sel_str = $l_sel_str . ", ";
            }
         }
      }
   } else {
      if ($uf_type eq 'index'){
         main::mes($bl_d,$lg{no_cols_sel});
      }
   }
}
sub now_build_ord {
   package main;

   # This helps build up the ordering SQL string.

   my($nbo_d,$uf_type) = @_;
   $tot_i_cnt = 0;
   for $i (0..$ind_bd_cnt){
      if ($i_uc[$i] == 1){
         $tot_i_cnt++;
         $tot_ind_ar[$tot_i_cnt] = $i_ac[$i];
      }
   }
   my $b_d = $nbo_d->DialogBox(-title=>$m_t); 
   $b_d->Label(-text=>$lg{ind_ord_arrng},-anchor=>'n')->pack(-side=>'top');

   my $t = $b_d->Scrolled('Text',
                          -height=>16,
                          -wrap=>'none',
                          -cursor=>undef,
                          -foreground=>$fc,
                          -background=>$bc);

   if ($uf_type eq 'index'){

      # User may be wanting to generate DDL to create new Index.
      # If so, this picks up the other information required.

      my $id_name = $lg{ind_name} . ':';

      $w = $t->Entry(-textvariable=>\$id_name,
                     -background=>$fc,
                     -foreground=>$ec);

      $t->windowCreate('end',-window=>$w);

      $ind_name = 'INDEX_NAME';
      $w = $t->Entry(-textvariable=>\$ind_name,
                     -cursor=>undef,
                     -foreground=>$fc,
                     -background=>$ec);
      $t->windowCreate('end',-window=>$w);
      $t->insert('end', "\n");

      my $tabp_name = $lg{tabsp} . ':';

      $w = $t->Entry(-textvariable=>\$tabp_name,
                     -background=>$fc,
                     -foreground=>$ec);

      $t->windowCreate('end',-window=>$w);

      $t_n = "TABSPACE_NAME";
      $t_l = $t->BrowseEntry(-cursor=>undef,
                             -variable=>\$t_n,
                             -foreground=>$fc,
                             -background=>$ec);

      $t->windowCreate('end',-window=>$t_l);
      $t->insert('end', "\n");
   
      my $sth = 
         $dbh->prepare(main::f_str('now_build_ord','1'))||die $dbh->errstr; 
      $sth->execute;

      my $i = 0;
      my @tot_obj;
      while (@res = $sth->fetchrow) {
         $tot_obj[$i] = $res[0];
         $i++;
      }
      $sth->finish;

      my @h_ar = sort @tot_obj;
      foreach(@h_ar){
         $t_l->insert('end', $_);
      }
      $t->insert('end', "\n");
   }
   my @pos_txt;
   for $i (1..($tot_i_cnt + 2)){
      if ($i <= $tot_i_cnt){
         $pos_txt[$i] = "Pos $i";
         $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                        -width=>7,
                        -background=>$fc,
                        -foreground=>$ec);
      } else {
         if ($i == ($tot_i_cnt + 1)){
            $pos_txt[$i] = $lg{i_col};
            $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                           -background=>$fc,
                           -foreground=>$ec);
         } else {
            unless ($uf_type eq 'index'){
               $pos_txt[$i] = $lg{i_desc};
               $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                              -width=>8,
                              -background=>$fc,
                              -foreground=>$ec);
            }
         }
      }
      $t->windowCreate('end',-window=>$w);
   }
   $t->insert('end', "\n");

   # The following is all a bit horrible.  I'm afraid 
   # you're going to have to work it out for yourself.
   # It's not nice, you may not want to bother.

   for $j_row (1..$tot_i_cnt){
      $ih[$j_row] = $j_row;
      $dsc_n[$j_row] = 0;
      $o_ih[$j_row] = $ih[$j_row];
      for $j_col (1..($tot_i_cnt + 2)){
         if ($j_col <= $tot_i_cnt){

            $w = $t->Radiobutton(
                        -relief=>'flat',
                        -value=>$j_row,
                        -variable=>\$ih[$j_col],
                        -width=>4,
                        -command=>[ sub {orac_Oracle::j_inri()}]);

            $t->windowCreate('end',-window=>$w);
         } else {
            if ($j_col == ($tot_i_cnt + 1)){

               $w = $t->Entry( -textvariable=>\$tot_ind_ar[$j_row],
                               -cursor=>undef,
                               -foreground=>$fc,
                               -background=>$ec
                             );

               $t->windowCreate('end',-window=>$w);
            } else {
               unless ($uf_type eq 'index'){

                  $w = $t->Checkbutton( -variable=>\$dsc_n[$j_row],
                                        -relief=>'flat',
                                        -width=>6);

                  $t->windowCreate('end',-window=>$w);
               }
            }
         }
      }
      $t->insert('end', "\n");
   }
   $t->configure(-state=>'disabled');
   $t->pack();
   $b_d->Show;
}
sub really_build_index {
   package main;

   # Picks up everything finally reqd. to build
   # up the DDL for index creation

   my($rbi_d,$own,$obj) = @_;

   my $d = $rbi_d->DialogBox();

   $d->add( "Label",
            -text=>"$lg{ind_crt_for} $own.$obj"
          )->pack(side=>'top');

   my $l_text = $d->Scrolled( 'Text',
                              -wrap=>'none',
                              -cursor=>undef,
                              -foreground=>$fc,
                              -background=>$bc
                            );

   $l_text->pack(-expand=>1,-fil=>'both');

   tie (*L_TXT, 'Tk::Text', $l_text);

   my $cm = main::f_str('build_ind','1');

   for my $cl (1..$tot_i_cnt){
      my $bs = " v_this_build($cl) := '$tot_ind_ar[$ih[$cl]]'; ";
      $cm = $cm . $bs;
   }

   my $cm_part2 = main::f_str('build_ind','2');
   $cm = $cm . "\n" . $cm_part2;

   $dbh->func(1000000, 'dbms_output_enable');

   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->bind_param(1,$own);
   $sth->bind_param(2,$obj);
   $sth->bind_param(3,$tot_i_cnt);
   $sth->execute;

   my $full_list;
   $full_list = scalar $dbh->func('dbms_output_get');
   if (length($full_list) != 0){
      $avg_entry_size = $full_list + 0.00;

      ($pct_free,$initrans) = orac_Oracle::ind_prep(main::f_str('build_ind','3'),$own,$obj);
      ($n_rows) =             orac_Oracle::ind_prep(main::f_str('build_ind','4') . ' ' . $own . '.' . $obj . ' ');
      ($avail_data_space) =   orac_Oracle::ind_prep(main::f_str('build_ind','5'),$Block_Size,$initrans,$pct_free);
      ($space) = orac_Oracle::ind_prep(main::f_str('build_ind','6'),$avail_data_space,$avg_entry_size,$avg_entry_size);
      ($blocks_req) =         orac_Oracle::ind_prep(main::f_str('build_ind','7'),$n_rows,$avg_entry_size,$space);
      ($initial_extent) =     orac_Oracle::ind_prep(main::f_str('build_ind','8'),$blocks_req,$Block_Size);
      ($next_extent) =        orac_Oracle::ind_prep(main::f_str('build_ind','9'),$initial_extent);

      print L_TXT "\nrem  Index Script for new index ${ind_name} on ${own}.${obj}\n\n";
      print L_TXT "create index ${own}.${ind_name} on\n";
      print L_TXT "   ${own}.${obj} (\n";
      for my $cl (1..$tot_i_cnt){
         my $bs = "      $tot_ind_ar[$ih[$cl]]\n";
         if ($cl != $tot_i_cnt){
            $bs = $bs . ', ';
         }
         print L_TXT $bs;
      }
      print L_TXT "   ) tablespace ${t_n}\n";
      print L_TXT "   storage (initial ${initial_extent}K next ${next_extent}K pctincrease 0)\n";
      print L_TXT "   pctfree ${pct_free};\n\n";
      print L_TXT "\nrem Average Index Entry Size:  ${avg_entry_size}   ";

      my $b = $l_text->Button(-text=>"Calculation SQL",-command=>sub{main::see_sql($d,$cm)});
      $l_text->window('create','end',-window=>$b);

      print L_TXT "\nrem Database Block Size:       ${Block_Size}\n";
      print L_TXT "rem Current Table Row Count:   ${n_rows}\n";
      print L_TXT "rem Available Space Per Block: ${avail_data_space}\n";
      print L_TXT "rem Space For Each Index:      ${space}\n";
      print L_TXT "rem Blocks Required:           ${blocks_req}\n\n";
   }
   main::orac_Show($d);
}

sub ind_prep {

   package main;

   # Helper function for working out Index DDL

   my $cm = shift;
   my @bindees = @_;
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $num_bindees = @bindees;
   if ($num_bindees > 0){
      my $i;
      for ($i = 1;$i <= $num_bindees;$i++){
         $sth->bind_param($i,$bindees[($i - 1)]);
      }
   }
   $sth->execute;
   my @res = $sth->fetchrow;
   $sth->finish;
   return @res;
}
sub j_inri {
   package main;

   # Here lies the end of sanity.  Welcome!

   my $i = 0;
   my $cl = 0;
   for $cl (1..$tot_i_cnt){
      if ($o_ih[$cl] != $ih[$cl]){
         $i = $cl;
         last;
      }
   }
   if ($i > 0){
      for $cl (1..$tot_i_cnt){
         unless ($cl == $i){
            if ($ih[$cl] == $ih[$i]){
                $ih[$cl] = $o_ih[$i];
                $o_ih[$cl] = $ih[$cl];
                last;
            }
         }
      }
      $o_ih[$i] = $ih[$i];
   }
}
sub tab_det_orac {
   package main;

   # Produces simple graphical representations of complex
   # percentage style reports.

   my ($title,$func) = @_;
   my $d = $mw->DialogBox(-title=>"$title: $v_db ($lg{blk_siz} $Block_Size)");
   my $cf = $d->Frame;
   $cf->pack(-expand=>'1',-fill=>'both');

   my $c = $cf->Scrolled( 'Canvas',
                          -relief=>'sunken',
                          -bd=>2,
                          -width=>500,
                          -height=>280,
                          -background=>$bc
                        );

   $keep_tablespace = 'XXXXXXXXXXXXXXXXX';

   my $cm = main::f_str($func,'1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   if($func eq 'tab_det_orac'){
      my $i;
      for ($i = 1;$i <= 6;$i++){
         $sth->bind_param($i,$Block_Size);
      }
   }
   $sth->execute;

   $i = 1;
   $Grand_Total = 0.00;
   $Grand_Used_Mg = 0.00;
   $Grand_Free_Mg = 0.00;

   while (@res = $sth->fetchrow) {
     if($func eq 'tabspace_diag'){
        if($res[0] eq 'free'){
           $Free_Mg = $res[2];
           next;
        } else {
           $T_Space = $res[1];
           $Fname = '';
           $Total = $res[2];
           $Used_Mg = $Total - $Free_Mg;
           $Use_Pct = ($Used_Mg/$Total)*100;
        }
     } else {
        ($T_Space,$Fname,$Total,$Used_Mg,$Free_Mg,$Use_Pct) = @res;
     }
     if ((!defined($Used_Mg)) || (!defined($Use_Pct))){
        $Used_Mg = 0.00;
        $Use_Pct = 0.00;
     }
     $Grand_Total = $Grand_Total + $Total;
     $Grand_Used_Mg = $Grand_Used_Mg + $Used_Mg;
     if (defined($Free_Mg)){
        $Grand_Free_Mg = $Grand_Free_Mg + $Free_Mg;
     }
     if($func ne 'tab_det_orac'){
        $Fname = '';
     } 
     if($func eq 'tune_health'){
        $Use_Pct = $Total;
     }
     orac_Oracle::add_item( $func,
                            $c,
                            $i,
                            $T_Space,
                            $Fname,
                            $Total,
                            $Used_Mg,
                            $Free_Mg,
                            $Use_Pct
                          );
     $i++;
   }
   $sth->finish;

   if($func ne 'tune_health'){
      $Grand_Use_Pct = (($Grand_Used_Mg/$Grand_Total)*100.00);

      orac_Oracle::add_item(  $func,
                              $c,
                              0,
                              '',
                              '',
                              $Grand_Total,
                              $Grand_Used_Mg,
                              $Grand_Free_Mg,
                              $Grand_Use_Pct
                           );
   }

   my $b = $c->Button( -text=>$ssq,-command=>sub{main::see_sql($d,$cm)});
   my $y_start = orac_Oracle::work_out_why($i);

   $c->create(  'window', 
                '1c',
                "$y_start" . 'c',
                -window=>$b,
                -anchor=>'nw',
                -tags=>'item'
             );

   $c->configure(-scrollregion=>[ $c->bbox("all") ]);
   $c->pack(-expand=>'yes',-fill=>'both');
   main::orac_Show($d);

}

sub work_out_why {
   package main;
   return (0.8 + (1.2 * $_[0]));
}

sub add_item {

   package main;

   # Produces bar line on canvas for simple charts.

   my (  $func,
         $c,
         $i,
         $T_Space,
         $Fname,
         $Total,
         $Used_Mg,
         $Free_Mg,
         $Use_Pct) = @_;

   unless($i == 0){
      if ($keep_tablespace eq $T_Space){
         $tab_str = sprintf("%${old_length}s ", '');
      } else {
         $old_length = length($T_Space);
         $tab_str = sprintf("%${old_length}s ", $T_Space);
      }
      $keep_tablespace = $T_Space;
   }
   my $thickness = 0.4;
   my $y_start = orac_Oracle::work_out_why($i);
   my $y_end = $y_start + 0.4;
   my $chopper;
   if($func ne 'tune_health'){
      $chopper = 20.0;
   } else {
      $chopper = 10.0;
   }
   $dst_f = ($Use_Pct/$chopper) + 0.4;

   $c->create( ( 'rectangle', 
                 "$dst_f" . 'c',
                 "$y_start". 'c',
                 '0.4c',
                 "$y_end" . 'c'),

               -fill=>$hc

             );
  
   $y_start = $y_start - 0.4;

   if($i == 0){

      my $bit = '';

      $this_text = "$lg{db} " . 
                   sprintf("%5.2f", $Use_Pct) . 
                   '% '. 
                   $lg{full} . 
                   $bit;
   } else {

      $this_text = "$tab_str $Fname " . 
                   sprintf("%5.2f", $Use_Pct) . 
                   '%';

   }

   $c->create(   (   'text',
                     '0.4c',
                     "$y_start" . 'c',
                     -anchor=>'nw',
                     -justify=>'left',
                     -text=>$this_text  
                 )
             );

   $y_start = $y_start + 0.4;

   if($func ne 'tune_health'){

      $c->create( ( 'text',
                    '5.2c',
                    "$y_start" . 'c',
                    -anchor=>'nw',
                    -justify=>'left',
                    -text=>sprintf("%10.2fM Total %10.2fM Used %10.2fM Free",
                                   $Total, 
                                   $Used_Mg, 
                                   $Free_Mg
                                  )
                  )
                );
   }
}
sub dbwr_fileio {
   package main;

   # Works out File/IO and produces graphical report.

   my $t_tit = "$lg{file_io} $v_db";
   my $d = $mw->DialogBox(-title=>$t_tit);
   my $cf = $d->Frame;
   $cf->pack(-expand=>'1',-fill=>'both');

   my $c = $cf->Scrolled(  'Canvas',
                           -relief=>'sunken',
                           -bd=>2,
                           -width=>500,
                           -height=>280,
                           -background=>$bc
                        );

   my $cm = main::f_str('dbwr_fileio','1');

   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;
   my $max_value = 0;
   my $i = 0;
   while (@res = $sth->fetchrow) {
      $dbwr_fi[$i] = [ @res ];
      $i++;
      for $i (1 .. 6){
         if ($res[$i] > $max_value){
            $max_value = $res[$i];
         }
      }
   }
   $sth->finish;

   if($i > 0){

      $i--;

      for $i (0 .. $i){

         orac_Oracle::dbwr_print_fileio(  $c, 
                                          $max_value, 
                                          $i,
                                          $dbwr_fi[$i][0],
                                          $dbwr_fi[$i][1],
                                          $dbwr_fi[$i][2],
                                          $dbwr_fi[$i][3],
                                          $dbwr_fi[$i][4],
                                          $dbwr_fi[$i][5],
                                          $dbwr_fi[$i][6]
                                       );
      }
   }
   my $b = $c->Button(-text=>$ssq,-command=>sub{main::see_sql($d,$cm)});
   my $y_start = orac_Oracle::this_pak_get_y(($i + 1));

   $c->create(  'window', 
                '1c', 
                "$y_start" . 'c',
                -window=>$b,
                -anchor=>'nw',
                -tags=>'item'
             );

   $c->configure(-scrollregion=>[ $c->bbox("all") ]);

   $c->pack(-expand=>'yes',-fill=>'both');
   main::orac_Show($d);
}
sub this_pak_get_y {
   package main;
   return (($_[0] * 2.5) + 0.2);
}
sub dbwr_print_fileio {
   package main;

   # Prints out lines required for File/IO graphical report.

   my (  $c,
         $max_value,
         $y_start,
         $name,
         $phyrds,
         $phywrts,
         $phyblkrd,
         $phyblkwrt,
         $readtim,
         $writetim    ) = @_;

   @stf = ('', $phyrds,$phywrts,$phyblkrd,$phyblkwrt,$readtim,$writetim);

   my $local_max = $stf[1];
   for $i (2 .. 6){
      if($stf[$i] > $local_max){
         $local_max = $stf[$i];
      }
   }
   @txt_stf = (   '', 
                  'phyrds',
                  'phywrts',
                  'phyblkrd',
                  'phyblkwrt',
                  'readtim',
                  'writetim'
              );


   my $screen_ratio = 0.00;
   $screen_ratio = ($max_value/10.00);
   $txt_name = 0.1;

   $x_start = 2;
   $y_start = orac_Oracle::this_pak_get_y($y_start);
   $act_figure_pos = $x_start + ($local_max/$screen_ratio) + 0.5;
   my $i;
   for $i (1 .. 6){
      $x_stop = $x_start + ($stf[$i]/$screen_ratio);
      $y_end = $y_start + 0.2;

      $c->create(   (  'rectangle',
                       "$x_start" . 'c',
                       "$y_start" . 'c',
                       "$x_stop" . 'c',
                       "$y_end" . 'c'
                    ),

                    -fill=>$hc

                );

      $txt_y_start = $y_start - 0.15;

      $c->create(   (   'text', 
                        "$txt_name" . 'c', 
                        "$txt_y_start" . 'c',
                        -anchor=>'nw',
                        -justify=>'left',
                        -text=>"$txt_stf[$i]"
                    )
                );


      $c->create(   (   'text', 
                        "$act_figure_pos" . 'c', 
                        "$txt_y_start" . 'c',
                        -anchor=>'nw',
                        -justify=>'left',
                        -text=>"$stf[$i]"
                    )
                );

      $y_start = $y_start + 0.3;
   }
   $txt_y_start = $y_start - 0.10;

   $c->create(   (   'text', 
                     "$x_start" . 'c', 
                     "$txt_y_start" . 'c',
                     -anchor=>'nw',
                     -justify=>'left',
                     -text=>"$name"
                 )
             );

}

sub gn_hl {

   package main;

   # Main parent function for generic HLists for database objects.

   ($g_typ,$g_hlst,$gen_sep) = @_;

   $g_mw = $mw->DialogBox(-title=>"$g_hlst $v_db");

   my $top_frame = $g_mw->Frame->pack(-anchor=>'n',
                                      -side=>'top',
                                      -expand=>'1',
                                      -fill=>'both');

   my $bot_frame = $g_mw->Frame->pack(-anchor=>'s',
                                      -side=>'bottom',
                                      -before=>$top_frame,
                                      -expand=>'1',
                                      -fill=>'both');

   $hlist = $top_frame->Scrolled('HList',
                                 -drawbranch=>1,
                                 -separator=>$gen_sep,
                                 -indent=>50,
                                 -width=>50,
                                 -height=>20,
                                 -foreground=>$fc,
                                 -background=>$bc);

   $hlist->configure(-command=> sub{orac_Oracle::show_or_hide_tab($_[0])});
   $hlist->pack(-fill=>'both', 
                -expand=>'y');
   
   $open_folder_bitmap = 
      $top_frame->Bitmap(-file=>Tk->findINC('openfolder.xbm'));

   $closed_folder_bitmap = 
      $top_frame->Bitmap(-file=>Tk->findINC('folder.xbm'));

   $file_bitmap = $top_frame->Bitmap(-file=>Tk->findINC('file.xbm'));

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

   $bot_frame->Radiobutton(-variable=>\$v_yes_no_txt,
                           -text=>$no_txt,
                           -value=>'N'
                          )->pack (side=>'left');

   $bot_frame->Radiobutton(-variable=>\$v_yes_no_txt,
                           -text=>$yes_txt,
                           -value=>'Y'
                          )->pack (side=>'left');
   
   undef %all_the_owners;

   my $cm = main::f_str( orac_Oracle::hl_trans($g_hlst) ,'1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;

   while (@res = $sth->fetchrow) {
      my $owner = $res[0];

      $hlist->add($owner,
                  -itemtype=>'imagetext',
                  -image=>$closed_folder_bitmap,
                  -text=>$owner);

      $all_the_owners{"$owner"} = 'closed';
   }
   $sth->finish;
   main::orac_Show($g_mw);
}
sub show_or_hide_tab {
   package main;

   # Works out which level of the Hierarchical list we're on,
   # and then displays the results accordingly.

   my $hlist_thing = $_[0];
   if(!$all_the_owners{"$hlist_thing"}){
      orac_Oracle::do_a_generic($hlist_thing, 'Normal', 'dum');
      return;
   } else {
      if($all_the_owners{"$hlist_thing"} eq 'closed'){
         $hlist->info('next', $hlist_thing);
         $hlist->entryconfigure($hlist_thing,-image=>$open_folder_bitmap);
         $all_the_owners{"$hlist_thing"} = 'open';
         
         orac_Oracle::add_generics($hlist_thing);
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

   $g_mw->Busy;
   my $owner = $_[0];
   if ($g_typ == 1){

      my $sth = 
         $dbh->prepare(main::f_str(orac_Oracle::hl_trans($g_hlst),'2')) 
            || die $dbh->errstr; 

      $sth->bind_param(1,$owner);
      $sth->execute;
      while (@res = $sth->fetchrow) {
         my $gen_thing = "$owner" . $gen_sep . "$res[0]";
         $hlist->add($gen_thing,
                     -itemtype=>'imagetext',
                     -image=>$file_bitmap,
                     -text=>$gen_thing);
      }
      $sth->finish;
   } else {
      my $gen_thing = "$owner" . $gen_sep . 'sql';
      $hlist->add($gen_thing,
                  -itemtype=>'imagetext',
                  -image=>$file_bitmap,
                  -text=>$gen_thing);
   }
   $g_mw->Unbusy;
}
sub do_a_generic {
   package main;

   # On the final level of an HList, does the actual work
   # required.

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
   my $cm = main::f_str( orac_Oracle::hl_trans($loc_g_hlst) ,'3');

   $dbh->func(1000000, 'dbms_output_enable');
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

   $d->add("Label",
           -text=>"$loc_g_hlst $lg{sql_for} $owner.$generic"
          )->pack(side=>'top');

   $l_txt = $d->Scrolled('Text',
                         -height=>16,
                         -wrap=>'none',
                         -cursor=>undef,
                         -foreground=>$fc,
                         -background=>$bc
                        )->pack(-expand=>1,-fil=>'both');

   tie (*L_TEXT, 'Tk::Text', $l_txt);

   my $j = 0;
   my $full_list;
   my $i = 1;

   while($j < 10000){
      $full_list = scalar $dbh->func('dbms_output_get');
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
      my(@tab_options) = 
         qw/$lg{indexs} $lg{constrnts} $lg{trggrs} $lg{comments}/;
      my $i = 1;
      foreach ($lg{indexs},$lg{constrnts},$lg{trggrs},$lg{comments}){
         my $this_txt = $_;

         $b[$i] = 
            $l_txt->Button(
               -text=>"$this_txt",
               -command=>sub{orac_Oracle::do_a_generic($input,
                                                       'Recursive',
                                                       "$this_txt")});

         $l_txt->window('create', 'end',-window=>$b[$i]);
         print L_TEXT " ";
         $i++;
      }
      print L_TEXT "\n\n  ";

      $b[$i] = 
         $l_txt->Button(-text=>$lg{form},
                        -command=>
                           sub{$d->Busy;
                               orac_Oracle::univ_form($d,
                                                      $owner,
                                                      $generic,
                                                      'form');
                               $d->Unbusy }
                       );

      $l_txt->window('create', 'end',-window=>$b[$i]);
      $i++;
      print L_TEXT " ";

      $b[$i] = 
         $l_txt->Button(
            -text=>$lg{build_index},
            -command=> sub{$d->Busy;
                           orac_Oracle::univ_form($d,$owner,$generic,'index');
                           $d->Unbusy }
                       );

      $l_txt->window('create','end',-window=>$b[$i]);
   } elsif ($loc_g_hlst eq $lg{views}){
      print L_TEXT "\n\n  ";

      $b[1] = 
         $l_txt->Button(
            -text=>$lg{form},
            -command=>sub{  $d->Busy;
                            orac_Oracle::univ_form(  $d,
                                                     $owner,
                                                     $generic,
                                                     'form'
                                                  );
                            $d->Unbusy }
                       );

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
   my $out;
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
sub errors_orac {
   package main;

   # Creates DBA Viewer window

   my $cm = main::f_str('errors_orac','1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;
   my $detected = 0;
   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){
         $sw[$swc{errors_orac}] = MainWindow->new();
         $sw[$swc{errors_orac}]->title($lg{err_obj});

         my(@err_lay) = qw/-side top -padx 5 -expand no -fill both/;
         $err_menu = $sw[$swc{errors_orac}]->Frame->pack(@err_lay);
         my $orac_li = $sw[$swc{errors_orac}]->Pixmap(-file=>'img/orac.bmp');

         $err_menu->Label(-image=>$orac_li,
                          -borderwidth=>2,
                          -relief=>'flat'
                         )->pack(-side=>'left',-anchor=>'w');

         $err_menu->Button(
              -text=>$lg{exit},
              -command=> 
                  sub{$sw[$swc{errors_orac}]->withdraw();
                      $sw_flg[$swc{errors_orac}]->configure(-state=>'active')}
                          )->pack(-side=>'left');

         $err_top = $sw[$swc{errors_orac}]->Frame->pack(-side=>'top',
                                                        -padx=>5,
                                                        -expand=>'yes',
                                                        -fill=>'both');

         $sw_hand[$swc{errors_orac}] = 
             $err_top->ScrlListbox(-width=>50,
                                   -background=>$bc,
                                   -foreground=>$fc
                                  )->pack(-side=>'top',
                                          -expand=>'yes',
                                          -fill=>'both');

         $err_top->Label(-text=>$lg{doub_click},
                         -anchor=>'s',
                         -relief=>'groove'
                        )->pack(-side=>'bottom',
                                -before=>$sw_hand[$swc{errors_orac}],
                                -expand=>'no');
         main::iconize($sw[$swc{errors_orac}]);
      }
      $sw_hand[$swc{errors_orac}]->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $mw->Busy;
      main::mes($mw,$lg{no_rows_found});
      $mw->Unbusy;
   } else {
      $sw_flg[$swc{errors_orac}]->configure(-state=>'disabled');
      $sw_hand[$swc{errors_orac}]->pack();
      $sw_hand[$swc{errors_orac}]->bind('<Double-1>', 
         sub{$sw[$swc{errors_orac}]->Busy;
            orac_Oracle::selected_error(
               $sw_hand[$swc{errors_orac}]->get('active'));
            $sw[$swc{errors_orac}]->Unbusy});
   }
}
sub dbas_orac {
   package main;

   # Creates DBA Viewer window

   my $cm = main::f_str('dbas_orac','1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;
   my $detected = 0;
   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){
         $sw[$swc{dbas_orac}] = MainWindow->new();
         $sw[$swc{dbas_orac}]->title($lg{dba_views});

         my(@dba_lay) = qw/-side top -padx 5 -expand no -fill both/;
         $dba_menu = $sw[$swc{dbas_orac}]->Frame->pack(@dba_lay);
         my $orac_li = $sw[$swc{dbas_orac}]->Pixmap(-file=>'img/orac.bmp');
         $dba_menu->Label(-image=>$orac_li,
                          -borderwidth=>2,
                          -relief=>'flat')->pack(-side=>'left',-anchor=>'w');

         $dba_menu->Button(
                  -text=>$lg{exit},
                  -command=>
                     sub{$sw[$swc{dbas_orac}]->withdraw();
                         $sw_flg[$swc{dbas_orac}]->configure(-state=>'active')} 
                          )->pack(-side=>'left');
      
         (@err_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         $dba_top = $sw[$swc{dbas_orac}]->Frame->pack(@err_lay);

         $sw_hand[$swc{dbas_orac}] = 
            $dba_top->ScrlListbox(-width=>50,
                                  -background=>$bc,
                                  -foreground=>$fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         $dba_top->Label(-text=>$lg{doub_click},
                         -anchor=>'s',
                         -relief=>'groove'
                        )->pack(-expand=>'no',
                                -side=>'bottom',
                                -before=>$sw_hand[$swc{dbas_orac}]);

         main::iconize($sw[$swc{dbas_orac}]);
      }
      $sw_hand[$swc{dbas_orac}]->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $mw->Busy;
      main::mes($mw,$lg{no_rows_found});
      $mw->Unbusy;
   } else {
      $sw_flg[$swc{dbas_orac}]->configure(-state=>'disabled');
      $sw_hand[$swc{dbas_orac}]->pack();

      $sw_hand[$swc{dbas_orac}]->bind(
         '<Double-1>',
         sub{ $sw[$swc{dbas_orac}]->Busy;
            orac_Oracle::univ_form($sw[$swc{dbas_orac}],
                                   'SYS',
                                   $sw_hand[$swc{dbas_orac}]->get('active'),
                                   'form'
                                  );
            $sw[$swc{dbas_orac}]->Unbusy}

                                     );
   }
}
sub addr_orac {
   package main;

   # Creates DBA Viewer window

   my $cm = main::f_str('addr_orac','1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;
   my $detected = 0;
   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){
         $sw[$swc{addr_orac}] = MainWindow->new();
         $sw[$swc{addr_orac}]->title($lg{spec_addrss});

         my(@adr_lay) = qw/-side top -padx 5 -expand no -fill both/;
         $addr_menu = $sw[$swc{addr_orac}]->Frame->pack(@adr_lay);
         my $orac_li = $sw[$swc{addr_orac}]->Pixmap(-file=>'img/orac.bmp');


         $addr_menu->Label( -image=>$orac_li,
                            -borderwidth=>2,
                            -relief=>'flat'
                          )->pack(-side=>'left',
                                  -anchor=>'w');

         $addr_menu->Button(
            -text=>$lg{exit},
            -command=> 
               sub{ $sw[$swc{addr_orac}]->withdraw();
                        $sw_flg[$swc{addr_orac}]->configure(-state=>'active')} 

                           )->pack(-side=>'left');


         (@adr_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         $adr_top = $sw[$swc{addr_orac}]->Frame->pack(@adr_lay);

         $sw_hand[$swc{addr_orac}] = 
            $adr_top->ScrlListbox(-width=>20,
                                  -background=>$bc,
                                  -foreground=>$fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         $adr_top->Label(-text=>$lg{doub_click},
                         -anchor=>'s',
                         -relief=>'groove'
                        )->pack(-expand=>'no',
                                -side=>'bottom',
                                -before=>$sw_hand[$swc{addr_orac}]);

         main::iconize($sw[$swc{addr_orac}]);
      }
      $sw_hand[$swc{addr_orac}]->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $mw->Busy;
      main::mes($mw,$lg{no_rows_found});
      $mw->Unbusy;
   } else {
      $sw_flg[$swc{addr_orac}]->configure(-state=>'disabled');
      $sw_hand[$swc{addr_orac}]->pack();

      $sw_hand[$swc{addr_orac}]->bind(
         '<Double-1>', 
         sub{  $sw[$swc{addr_orac}]->Busy;
               my $loc_addr = $sw_hand[$swc{addr_orac}]->get('active');

               main::prp_lp( 'Paddr Results',
                             'sel_addr',
                             '',
                             '',
                             0,
                             $loc_addr);

               $sw[$swc{addr_orac}]->Unbusy   }

                                     );

   }
}

sub sids_orac {

   package main;

   # Creates DBA Viewer window

   my $cm = main::f_str('sids_orac','1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;
   my $detected = 0;
   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){
         $sw[$swc{sids_orac}] = MainWindow->new();
         $sw[$swc{sids_orac}]->title($lg{spec_sids});

         my(@sid_lay) = qw/-side top -padx 5 -expand no -fill both/;
         $sid_menu = $sw[$swc{sids_orac}]->Frame->pack(@sid_lay);
         my $orac_li = $sw[$swc{sids_orac}]->Pixmap(-file=>'img/orac.bmp');

         $sid_menu->Label(
                           -image=>$orac_li,
                           -borderwidth=>2,
                           -relief=>'flat'

                         )->pack( -side=>'left',
                                  -anchor=>'w' );

         $sid_menu->Button(  
            -text=>$lg{exit},
            -command=> 
               sub{ $sw[$swc{sids_orac}]->withdraw();
                    $sw_flg[$swc{sids_orac}]->configure(-state=>'active') } 

                          )->pack(-side=>'left');

         (@sid_lay) = qw/-side top -padx 5 -expand yes -fill both/;
         $sid_top = $sw[$swc{sids_orac}]->Frame->pack(@sid_lay);

         $sw_hand[$swc{sids_orac}] = 
            $sid_top->ScrlListbox(-width=>20,
                                  -background=>$bc,
                                  -foreground=>$fc
                                 )->pack(-expand=>'yes',-fill=>'both');

         $sid_top->Label(-text=>$lg{doub_click},
                         -anchor=>'s',
                         -relief=>'groove'
                        )->pack(-expand=>'no',
                                -side=>'bottom',
                                -before=>$sw_hand[$swc{sids_orac}]);

         main::iconize($sw[$swc{sids_orac}]);
      }
      $sw_hand[$swc{sids_orac}]->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $mw->Busy;
      main::mes($mw,$lg{no_rows_found});
      $mw->Unbusy;
   } else {
      $sw_flg[$swc{sids_orac}]->configure(-state=>'disabled');
      $sw_hand[$swc{sids_orac}]->pack();

      $sw_hand[$swc{sids_orac}]->bind(
         '<Double-1>', 
         sub { $sw[$swc{sids_orac}]->Busy;
               main::prp_lp( 'Sid Stats',
                             'sel_sid',
                             '1',
                             $rfm{r4_mid_big},
                             0,
                             $sw_hand[$swc{sids_orac}]->get('active')
                           );
               $sw[$swc{sids_orac}]->Unbusy}
                                     );
   }
}
sub gh_roll_name {
   package main;
   main::rep_tit($lg{roll_seg_stats});

   my $cm = main::f_str('time','2');
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $sth->execute;
   my($sample_time) = $sth->fetchrow;
   $sth->finish;
   print TEXT "$sample_time\n\n";

   main::prp_lp('','roll_orac','2',$rfm{rl2_7},0);
   main::about_orac('txt/Oracle/rollback.1.txt');
}
sub gh_roll_stats {
   package main;
   main::rep_tit($lg{roll_seg_stats});

   my $cm = main::f_str('time','2');
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $sth->execute;
   my($sample_time) = $sth->fetchrow;
   $sth->finish;
   print TEXT "$sample_time\n\n";

   main::prp_lp('','roll_orac','1',$rfm{rl_5},0);
   main::about_orac('txt/Oracle/rollback.2.txt');
}
sub gh_pool_frag {
   package main;
   main::about_orac('txt/Oracle/pool_frag.1.txt');
   main::prp_lp($lg{pool_frag},'pool_frag','1',$rfm{r2_l27_r10},0);
   main::about_orac('txt/Oracle/pool_frag.2.txt');
}
sub explain_plan {
   package main;

   # First of all, check if we have the correct PLAN_TABLE
   # on board?

   my $explain_ok = 0;
   if (orac_Oracle::check_exp_plan() == 0){
      main::mes($mw,$lg{use_utlxplan});
   } else {
      $explain_ok = 1;
   }
   if(!defined($swc{explain_plan})){
      $swc{explain_plan} = $global_sub_win_count;
      $global_sub_win_count++;
   }

   $sw[$swc{explain_plan}] = MainWindow->new();
   $sw[$swc{explain_plan}]->title($lg{explain_plan});

   my(@exp_lay) = qw/-side top -padx 5 -expand no -fill both/;
   $dmb = $sw[$swc{explain_plan}]->Frame->pack(@exp_lay);
   my $orac_li = $sw[$swc{explain_plan}]->Pixmap(-file=>'img/orac.bmp');

   $dmb->Label( -image=>$orac_li,
                -borderwidth=>2,
                -relief=>'flat'
             )->pack( -side=>'left',
                      -anchor=>'w' );

   # Add buttons.  Add a holder for the actual explain plan
   # button so we can enable/disable it later

   if($explain_ok){
      $expl_butt = $dmb->Button(-text=>$lg{explain},
                                -command=>sub{ orac_Oracle::explain_it() }
                               )->pack(side=>'left');

      $dmb->Button(-text=>$lg{clear},-command=>sub{
                         $sw[$swc{explain_plan}]->Busy;
                         $sql_txt->delete('1.0','end');
                         $w_user_name = $v_sys;
                         $expl_butt->configure(-state=>'normal');
                         $sw[$swc{explain_plan}]->Unbusy;
                                                  }
                  )->pack(side=>'left');
   }

   $dmb->Button(-text=>$lg{exit},
                -command=> sub{
                      $sw[$swc{explain_plan}]->withdraw();
                      $sw_flg[$swc{explain_plan}]->configure(-state=>'active');
                      undef $sql_browse_arr} 
               )->pack(-side=>'left');


   (@exp_lay) = qw/-side top -padx 5 -expand yes -fill both/;
   $top_slice = $sw[$swc{explain_plan}]->Frame->pack(@exp_lay);

   my $sql_txt_width = 50;
   my $sql_txt_height = 13;

   $sw_hand[$swc{explain_plan}] = 
      $top_slice->Scrolled('Text',
                           -wrap=>'none',
                           -cursor=>undef,
                           -height=>($sql_txt_height + 4),
                           -width=>($sql_txt_width + 4),
                           -foreground=>$fc,
                           -background=>$bc
                          );

   # Set the holding variables

   $w_user_name = '';
   $w_orig_sql_string = '';

   $w_user_id = 
      $sw_hand[$swc{explain_plan}]->Entry( -textvariable=>\$w_user_name,
                                           -cursor=>undef,
                                           -width=>30
                                         );

   $w_user_id->configure(-background=>$ec,-foreground=>$fc);
   $sw_hand[$swc{explain_plan}]->windowCreate('end',-window=>$w_user_id);
   $sw_hand[$swc{explain_plan}]->insert('end', "\n");
   
   $sql_txt = 
      $sw_hand[$swc{explain_plan}]->Scrolled( 'Text',
                                              -wrap=>'none',
                                              -cursor=>undef,
                                              -height=>$sql_txt_height,
                                              -width=>$sql_txt_width,
                                              -foreground=>$fc,
                                              -background=>$ec
                                            );
   tie (*SQL_TXT, 'Tk::Text', $sql_txt);

   $sw_hand[$swc{explain_plan}]->windowCreate('end',-window=>$sql_txt);
   $sw_hand[$swc{explain_plan}]->insert('end', "\n");

   $sw_hand[$swc{explain_plan}]->pack(-expand=>1,-fil=>'both');

   # Now build up the slider, which will trawl through v$sqlarea to
   # paste up various bits of SQL text currently in database.

   my $cm = main::f_str('explain_plan','2');
   $sql_browse_arr = $dbh->selectall_arrayref($cm);
   $sql_min_row = 0;
   $sql_max_row = @$sql_browse_arr;
   unless ($sql_max_row == 0){
      $sql_row_count = $sql_min_row;

      # Build up scale slider button, and splatt onto window.

      $bot_slice = $sw[$swc{explain_plan}]->Frame->pack(-before=>$top_slice,
                                                        -side=>'bottom',
                                                        -padx=>5,
                                                        -expand=>'no',
                                                        -fill=>'both');

      $sql_slider = 
         $bot_slice->Scale( 
            -orient=>'horizontal',
            -label=>"$lg{rec_of} " . $sql_max_row,
            -length=>400,
            -sliderrelief=>'raised',
            -from=>1,
            -to=>$sql_max_row,
            -tickinterval=>($sql_max_row/8),
            -command=>[ sub {orac_Oracle::calc_scale_sql($sql_txt_width,
                                                         $sql_slider->get(),
                                                         $explain_ok)} ]
                          )->pack(side=>'left');

      $bot_slice->Button(
         -text=>$ssq,
         -command=>sub { main::see_sql($sw[$swc{explain_plan}],$cm)}

                        )->pack(side=>'right');

      orac_Oracle::pick_up_sql($sql_txt_width,$explain_ok);

   } else {
      # There are no rows (very unlikely) so blatt out memory
      undef $sql_browse_arr;
   }
   $sw_flg[$swc{explain_plan}]->configure(-state=>'disabled');
   main::iconize($sw[$swc{explain_plan}]);
   return;
}
sub explain_it {
   package main;

   # Takes the SQL statement directly from the screen
   # and tries an 'Explain Plan' on it.  I'm leaving the
   # SQL hard-coded here so you can see EXACTLY what's
   # going on, particularly as we're dipping our toes
   # into DML.

   # BTW We're automatically set up for autocommit, with  
   # DBI, so there's no need to commit the 'delete'
   # transaction

   my $sql_bit = $sql_txt->get("1.0", "end");

   # The following is the first (and hopefully only)
   # DML in the whole of Orac.

   my $ex_sql = ' explain plan set statement_id ' .
                '= \'orac_explain_plan\' for ' . $sql_bit . ' ';

   my $del_sql = ' delete from plan_table ' .
                 'where statement_id = \'orac_explain_plan\' ';

   my $rc  = $dbh->do( $del_sql );
   $rc  = $dbh->do( $ex_sql );

   my $cm =   ' select rtrim(lpad(\'  \',2*level)|| ' . "\n" .
              ' rtrim(operation)||\' \'|| ' . "\n" .
              ' rtrim(options)||\' \'|| ' . "\n" .
              ' object_name) query_plan ' . "\n" .
              ' from plan_table ' . "\n" .
              ' where statement_id = \'orac_explain_plan\' ' . "\n" .
              ' connect by prior id = parent_id ' .
              ' and statement_id = \'orac_explain_plan\' ' . "\n" .
              ' start with id = 0 and statement_id = \'orac_explain_plan\' ';

   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;

   # Clear screen where required.
   main::f_clr();

   while (@res = $sth->fetchrow) {
      print TEXT "$res[0]\n";
   }
   $sth->finish;
   see_plsql( $cm );

}
sub calc_scale_sql {
   package main;

   # Whizz backwards and forwards through the 
   # v$sqlarea records

   my($width,$sv,$expl_ok) = @_;
   $sql_row_count = $sv - 1;
   orac_Oracle::pick_up_sql($width,$expl_ok);
}
sub pick_up_sql {
   package main;

   my($width,$expln_ok) = @_;

   # Work out which row of information to display,
   # and then display it.

   my $curr_ref = $sql_browse_arr->[$sql_row_count];

   # Now chop it up for formatting purposes.

   my $format = '^';
   for($i = 1;$i < $width;$i++){
      $format = $format . '<';
   }
   $format = $format . 'xyzzyxxyzzyx ~~';

   # Put up the name in the holding variable
   $w_user_name = $curr_ref->[0];

   # Format output the string.  Also, hold
   # it in another variable for the original.

   $w_orig_sql_string = $curr_ref->[1];
   my $string = crt_rp_do($format, $w_orig_sql_string);
   $string =~ s/xyzzyxxyzzyx/\n/g;
   
   $sql_txt->delete('1.0','end');
   $sql_txt->insert('1.0',$string);
   $sql_slider->set(($sql_row_count + 1));

   # Enable the 'Explain Plan' button, if the logged on
   # user, is the same as the SQL's user

   if($expln_ok){
      if($v_sys eq $w_user_name){
         $expl_butt->configure(-state => 'normal');
      } else {
         $expl_butt->configure(-state => 'disabled');
      }
   }
   return;
}
sub check_exp_plan {
   package main;

   # Check if the currently logged on DBA user
   # has a valid PLAN_TABLE table to put
   # 'Explain Plan' results to insert into.

   my $cm = main::f_str('explain_plan','1');
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $sth->execute;
   my $detected = 0;
   while (@res = $sth->fetchrow) {
      $detected = $res[0];
   }
   $sth->finish;
   return $detected;
}
1;
