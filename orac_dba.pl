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
use Tk;
use Carp;
use FileHandle;
use Cwd;
use Time::Local;
use DBI;
use Tk::DialogBox;
use Tk::HList;
require Tk::BrowseEntry;

&read_language;

$bc = $lg{def_backgr_col};
$hc = $lg{bar_col};
$ssq = $lg{see_sql};
$ec = $lg{def_fill_fld_col};
$fc = $lg{def_fg_col};
$sys_user = $lg{typ_sys};

$mw = MainWindow->new();

my $li = $mw->Pixmap(-file=>'img/orac.bmp');
my(@layout_mb) = qw/-side top -padx 5 -expand no -fill both/;
$mb = $mw->Frame->pack(@layout_mb);
$mb->Label(-image=>$li,-borderwidth=>2,-relief=>'flat')->pack(-side=>'left',-anchor=>'w');

$file_mb = $mb->Menubutton(-text=>$lg{file},-relief=>'raised')->pack(-side=>'left',-padx=>2);
$file_mb->command(-label=>$lg{reconn},-command=>sub{&get_db()});
$file_mb->command(-label=>$lg{about_orac},-command=>sub{&bz;&f_clr;&about_orac();&ubz});
$file_mb->separator();

$bc_txt = $lg{back_col_menu};
$file_mb->cascade(-label=>$bc_txt);
$bc_men = $file_mb->cget(-menu);
$bc_cols = $bc_men->Menu;

$file_mb->entryconfigure($bc_txt,-menu=>$bc_cols);
open(COLOUR_FILE, "txt/colours.txt");
while(<COLOUR_FILE>){
   chomp;
   eval {
      $bc_cols->radiobutton(-label=>$_,-background=>$_,-command=>[\&bc_upd],-variable=>\$bc,-value=>$_);
   };
}
close(COLOUR_FILE);

$file_mb->separator();
$file_mb->command(-label=>$lg{exit},-command=>sub{&back_orac});

$ts_mb = $mb->Menubutton(-text=>$lg{struct},-relief=>'raised')->pack(-side=>'left',-padx=>2);
$ts_mb->command(-label=>$lg{summ_tabsp},-command=>sub{&bz;&tab_det_orac($lg{summ_tabsp},'tabspace_diag');&ubz});
$ts_mb->command(-label=>$lg{det_tab_datafil},-command=>sub{&bz;&tab_det_orac($lg{det_tab_datafil},'tab_det_orac');;&ubz});
$ts_mb->separator();
$ts_mb->command(-label=>$lg{db_files},-command=>sub{&bz;&f_clr;&prp_lp($lg{db_files},'datafile_orac','1',$rp_5_opt2,0);&ubz});
$ts_mb->command(-label=>$lg{ext_rep},-command=>sub{&bz;&f_clr;&prp_lp($lg{ext_rep},'ext_orac','1',$rp_8_opt3,0);&ubz});
$ts_mb->command(-label=>$lg{max_exts_free},-command=>sub{&bz;&f_clr;my @params;my $i;
   for ($i = 0;$i < 9;$i++){$params[$i] = $Block_Size;};&prp_lp($lg{max_exts_free},'max_ext_orac','1',$rp_8a_bits,0,@params);&ubz});
$sw_flg[0] = $ts_mb->command(-label=>$lg{dba_views},-command=>sub{&f_clr;&sub_win(0,$mw,'dbas_orac','1',$lg{dba_views},50)});

$sql_gen_mb = $mb->Menubutton(-text=>$lg{obj},-relief=>'raised',-borderwidth=>2,-menuitems=>
    [[Button=>$lg{tabs},-command=>sub{&bz;&gn_hl(1,$lg{tabs},'.');&ubz}],
     [Button=>$lg{views},-command=>sub{&bz;&gn_hl(1,$lg{views},'.');&ubz}],
     [Button   =>$lg{synyms},-command=>sub{&bz;&gn_hl(1,$lg{synyms},'.');&ubz}],
     [Button   =>$lg{seqs},-command=>sub{&bz;&gn_hl(1,$lg{seqs},'.');&ubz}],
     [Separator=>''],
     [Cascade  =>$lg{grants_etc},-menuitems =>
      [[Button=>$lg{usergrant},-command=>sub{&bz;&gn_hl(2,$lg{usergrant},'.');&ubz}],
       [Button=>$lg{rolegrnts},-command=>sub{&bz;&gn_hl(2,$lg{rolegrnts},'.');&ubz}],
       [Button=>$lg{lnks},-command=>sub{&bz;&gn_hl(1,$lg{lnks},':');&ubz}],
       [Button=>$lg{users},-command=>sub{&bz;&gn_hl(2,$lg{users},'.');&ubz}],
       [Button=>$lg{rols},-command=>sub{&bz;&gn_hl(2,$lg{rols},'.');&ubz}],
       [Button=>$lg{profiles},-command=>sub{&bz;&gn_hl(2,$lg{profiles},'.');&ubz}],],
     ],
     [Separator=>''],
     [Cascade=>$lg{pl_sql},-menuitems =>
      [[Button=>$lg{procs},-command=>sub{&bz;&gn_hl(1,$lg{procs},'.');&ubz}],
       [Button=>$lg{funcs},-command=>sub{&bz;&gn_hl(1,$lg{funcs},'.');&ubz}],
       [Button=>$lg{trggrs},-command=>sub{&bz;&gn_hl(1,$lg{trggrs},'.');&ubz}],
       [Button=>$lg{pck_hds},-command=>sub{&bz;&gn_hl(1,$lg{pck_hds},'.');&ubz},],
       [Button=>$lg{pck_bods},-command=>sub{&bz;&gn_hl(1,$lg{pck_bods},'.');&ubz},],],
     ],
     [Cascade=>$lg{snaps},-menuitems =>
      [[Button=>$lg{snaps},-command=>sub{&bz;&gn_hl(1,$lg{snaps},'.');&ubz},],
       [Button =>$lg{snap_logs},-command=>sub{&bz;&gn_hl(1,$lg{snap_logs},'.');&ubz}],],
     ],
     [Separator=>''],
     [Cascade=>$lg{sql_crt_states},-menuitems =>
      [[Button=>$lg{constrnts},-command=>sub{&bz;&f_clr;&all_stf($lg{constrnts},'3',2);&ubz},],
       [Button=>$lg{usergrant},-command=>sub{&bz;&f_clr;&all_stf($lg{usergrant},'3',4);&ubz},],
       [Button=>$lg{synyms},-command=>sub{&bz;&f_clr;&all_stf($lg{synyms},'3',2);;&ubz},],],
     ],
     [Cascade=>$lg{db_recr_sql},-menuitems =>
      [[Button=>$lg{recrt_base_sql},-command=>sub{&bz;&f_clr;&orac_create_db();&ubz}],
       [Button=>$lg{raw_db_sql},-command=>sub{&bz;&f_clr;&prp_lp($lg{raw_db_sql},'steps','1',$rp_big_one_tince,0);&ubz}],],
     ],
    ])->pack(-side=>'left',-padx=>2);
$sql_gen_mb->separator();
$sql_gen_mb->command(-label=>$lg{inval_obj},-command=>sub{&bz;&f_clr;&prp_lp($lg{inval_obj},'alter_comp_orac','1',$rp_big_lft,0);&ubz});
$sw_flg[1] = $sql_gen_mb->command(-label=>$lg{err_obj},-command=>sub{&f_clr;&sub_win(1,$mw,'errors_orac','1', $lg{err_obj},50)});

$user_mb = $mb->Menubutton(-text=>$lg{user},-relief=>'raised',-borderwidth=>2,-menuitems =>
    [[Button=>$lg{logdon_usrs},-command=>sub{&bz;&f_clr;&prp_lp($lg{logdon_usrs},'curr_users_orac','1',$rp_9_opt7,0);&ubz},],
     [Button=>$lg{reg_usrs},-command=>sub{&bz;&f_clr;&prp_lp($lg{reg_usrs},'user_rep_orac','1',$rp_6_opt4,0);&ubz},],
     [Separator=>''],
     [Button=>$lg{user_upd_db},-command=>sub{&bz;&f_clr;&prp_lp($lg{user_upd_db},'user_upd_orac','1',$rp_10_opt3,0);&ubz},],
     [Button=>$lg{user_proc_io},-command=>sub{&bz;&f_clr;&prp_lp($lg{user_proc_io},'user_io_orac','1',$rp_7_opt4,0);&ubz},],
     [Button=>$lg{what_sql_users},-command=>sub{&bz;&f_clr;&what_sql;&ubz},],
     [Button=>$lg{curr_procs},-command=>sub{&bz;&f_clr;&prp_lp($lg{curr_procs},'spin_orac','1',$rp_10_bits,0);&ubz},],
     [Button =>$lg{conn_times},-command=>sub{&bz;&f_clr;&prp_lp($lg{conn_times},'conn_orac','1',$rp_7_opt2,0);&ubz},],
     [Separator=>''],
     [Button =>$lg{rols_db},-command=>sub{&bz;&f_clr;&prp_lp($lg{rols_db},'role_rep_orac','1',$rp_5_opt5,0);&ubz},],
     [Button =>$lg{profiles_db},-command=>sub{&bz;&f_clr;&prp_lp($lg{profiles_db},'prof_rep_orac','1',$rp_3_front_big,0);&ubz},],
     [Button =>$lg{quots},-command=>sub{&bz;&f_clr;&prp_lp($lg{quots},'quot_rep_orac','1',$rp_4_big_front,0);&ubz},],
     [Separator=>''],
    ])->pack(-side=>'left',-padx=>2);
$sw_flg[2] = $user_mb->command(-label=>'Specific Addresses',-command=>sub{&sub_win(2,$mw,'addr_orac','1','Specific Addresses',20)});
$sw_flg[3] = $user_mb->command(-label=>'Specific Sids',-command=>sub{&sub_win(3,$mw,'sids_orac','1','Specific Sids',20)});

$mb->Menubutton(-text=>$lg{tune},-relief=>'raised',-borderwidth=>2,-menuitems =>
    [[Button=>$lg{rollbk_stats},-command=>sub{&bz;&f_clr;&prp_lp($lg{rollbk_stats},'roll_orac','1',$rp_big_lft,0);
       &prp_lp('','roll_orac','2',$rp_biz_roll_2,0);
       &prp_lp('','roll_orac','3',$rp_3_biggish,0);
       &prp_lp('','roll_orac','4',$rp_big_one_tiny,0);&orac_print('print_roll_txt');&ubz},],
     [Button =>$lg{hits},-command=>sub{&bz;&tab_det_orac($lg{hits},'tune_health');&ubz},],
     [Separator=>''],
     [Cascade=>$lg{params},-menuitems =>
      [[Button =>$lg{nls_prms},-command=>sub{&bz;&f_clr();&prp_lp($lg{nls_prms},'nls','1',$rp_3_split,0);&ubz},],
       [Button =>$lg{db_info},-command=>sub{&bz;&f_clr();&prp_lp($lg{db_info},'database_info','','',0);&ubz},],
       [Button =>$lg{vers_info},-command=>sub{&bz;&f_clr();&prp_lp($lg{vers_info},'vdoll_version','1',$rp_big_lft,0);&ubz},],
       [Button =>$lg{sga_stats},-command=>sub{&bz;&f_clr();&prp_lp($lg{sga_stats},'sgastat','1',$rp_3_mid_big,0);&ubz},],
       [Button  =>$lg{sh_prms},-command=>sub{&bz;&f_clr();&prp_lp($lg{sh_prms},'vdoll_param_simp','1',$rp_two_splits,0);&ubz},],],
     ],
     [Cascade=>$lg{back_procs},-menuitems =>
      [[Cascade=>$lg{dbwr},-menuitems =>
        [[Button=>$lg{file_io},-command=>sub{&bz;&f_clr();&dbwr_fileio;&ubz},],
         [Button =>$lg{dbwr_mon},-command=>sub{&bz;&f_clr();&prp_lp($lg{dbwr_mon},'dbwr_monitor','1',$rp_two_splits,0);&ubz}],
         [Button =>$lg{dbwr_lru_ltch},-command=>sub{&bz;&f_clr();&prp_lp($lg{dbwr_lru_ltch},'dbwr_lru_latch','1',$rp_6_opt8,0);&ubz}],],
       ],
       [Cascade  =>$lg{lgwr},-menuitems =>
        [[Button =>$lg{lgwr_mon},-command=>sub{&bz;&f_clr();&prp_lp($lg{lgwr_mon},'lgwr_monitor','1',$rp_two_splits,0);&ubz}],
         [Button =>$lg{lgwr_redo_ltchs},-command=>sub{&bz;&f_clr();
          &prp_lp($lg{lgwr_redo_ltchs},'lgwr_buff_latch','1',$rp_5_spread,0);&ubz},],],
       ],
       [Cascade  =>$lg{dbwr_lgwr},-menuitems =>
        [[Button =>$lg{dbwr_lgwr_wts},-command=>sub{&bz;&f_clr();
          &prp_lp($lg{dbwr_lgwr_wts},'lgwr_and_dbwr_wait','1',$rp_3_front_big,0);&ubz},],],
       ],
       [Cascade  =>$lg{sorts},-menuitems =>
        [[Button =>$lg{sort_mon},-command=>sub{&bz;&f_clr();&prp_lp($lg{sort_mon},'where_sorts','1',$rp_two_splits,0);&ubz},],
         [Button =>$lg{id_srt_usrs},-command=>sub{&bz;&f_clr();&prp_lp($lg{id_srt_usrs},'who_sorts','1',$rp_4_big_front,0);&ubz},],],
       ],],],
     [Cascade  =>$lg{ltchs},-menuitems =>
      [[Button =>$lg{lw_ratio},-command=>sub{&bz;&f_clr;
        &prp_lp($lg{lw_ratio},'latch_hit_ratio','1',$rp_3_front_big,0);&orac_print('print_latch_wait');&ubz },],
       [Button =>$lg{lt_wtrs},-command=>sub{&bz;&f_clr;&prp_lp($lg{lt_wtrs},'act_latch_hit_ratio','1',$rp_3_front_big,0);&ubz},],
      ],],
     [Cascade  =>$lg{tabsp_tune},-menuitems =>
      [[Button =>$lg{tabsp_frag},-command=>sub{&bz;&f_clr;&prp_lp($lg{tabsp_frag},'defragger','1',$rp_8_bits,0);&ubz},],
       [Button =>$lg{tabsp_sp_shorts},-command=>sub{&bz;&f_clr;my @params;my $i;
        for ($i = 0;$i < 2;$i++){$params[$i] = $Block_Size;};
        &prp_lp($lg{tabsp_sp_shorts},'tab_shortage','1',$rp_6_opt9,0,@params);&ubz},],],
     ],
     [Separator=>''],
     [Cascade  =>$lg{mts},-menuitems =>
      [[Button=>$lg{mts_mem},-command=>sub{&bz;&f_clr;&prp_lp($lg{mts_mem},'sess_curr_max_mem','1',$rp_4_stats,3);&ubz},],
       [Button=>$lg{mts_bzy},-command=>sub{&bz;&f_clr;&prp_lp($lg{mts_bzy},'dispatch_stuff','1',$rp_two_splits,0);&ubz},],
       [Button=>$lg{mts_wt_disp},-command=>sub{&bz;&f_clr;&prp_lp($lg{mts_wt_disp},'dispatch_stuff','2',$rp_two_splits,0);&ubz},],
       [Button=>$lg{mts_wait_srv},-command=>sub{&bz;&f_clr;&prp_lp($lg{mts_wait_srv},'dispatch_stuff','3',$rp_big_lft,0);&ubz},],
       [Button=>$lg{tot_sess_uga},-command=>sub{&bz;&f_clr;&prp_lp($lg{tot_sess_uga},'sess_curr_max_mem','2',$rp_big_lft,0);&ubz},],
       [Button=>$lg{sess_uga_max},-command=>sub{&bz;&f_clr;&prp_lp($lg{sess_uga_max},'sess_curr_max_mem','3',$rp_big_lft,0);&ubz},],],
     ],
    ])->pack(-side=>'left',-padx=>2);

$mb->Menubutton(-text=>$lg{lck},-relief=>'raised',-borderwidth=>2,-menuitems =>
    [[Button =>$lg{lcks_held},-command=>sub{&bz;&f_clr;&prp_lp($lg{lcks_held},'lock_orac','1',$rp_9_opt2,0);&ubz},],
     [Button =>$lg{who_hold},-command=>sub{&bz;&f_clr;&prp_lp($lg{who_hold},'wait_hold','1',$rp_hold_11,1);&ubz},],
     [Button =>$lg{who_accs_obj},-command=>sub{&bz;&f_clr;&prp_lp($lg{who_accs_obj},'lock_objects','1',$rp_6_opt7,0);&ubz},],
     [Button =>$lg{rollbk_lcks},-command=>sub{&bz;&f_clr;&prp_lp($lg{rollbk_lcks},'rollback_locks','1',$rp_11_spread,0);&ubz },],
     [Button =>$lg{sess_wt_stats},-command=>sub{&bz;&f_clr;&tune_wait;&ubz },],
     [Button =>$lg{mem_hogs},-command=>sub{&bz;&f_clr;&tune_pigs;&ubz },],
    ])->pack(-side=>'left',-padx=>2);

&Jareds_tools;

$l_top_t = $lg{not_conn};
$mb->Label(-textvariable=>\$l_top_t,-relief=>'flat')->pack(-side=>'right',-anchor=>'e');
$v_text = $mw->Scrolled('Text',-wrap=>'none',-cursor=>undef,-foreground=>$fc,-background=>$bc);
$v_text->pack(-expand=>1,-fil=>'both');
tie (*TEXT,'Tk::Text',$v_text);

$mw->Button(-text=>$lg{clear},-command=>sub{&bz;&must_f_clr;&ubz})->pack(side=>'left');
$v_clr = 'Y';
$mw->Radiobutton(variable=>\$v_clr,text=>$lg{man_clear},value=>'N')->pack (side=>'left');
$mw->Radiobutton ( variable=>\$v_clr,text=>$lg{auto_clear},value=>'Y')->pack (side=>'left');
$mw->Button(-text=>$lg{reconn},-command=>sub{&bz;&get_db;&ubz})->pack(side=>'right');

$this_title = 'Orac-' . $lg{orac_pan};
$mw->title($this_title);
$val_con = 0;
&get_db();
&set_printouts();

MainLoop();

&back_orac();
sub f_clr {
   if($v_clr eq 'Y'){
      &must_f_clr();
   }
}
sub must_f_clr {
   $v_text->delete('1.0','end');
}
sub back_orac {
   if ($val_con){
      $rc  = $dbh->disconnect;
   }
   exit 0;
}
sub get_connected {
   my $dn = 0;
   if ($val_con == 1){
      &must_f_clr();
      $rc = $dbh->disconnect;
      $l_top_t = $lg{disconn};
      $val_con = 0;
   }
   do {
      $c_d = $mw->DialogBox(-title=>$lg{login_txt},-buttons=>[ $lg{connect},$lg{exit} ]);
      my $l1 = $c_d->Label(-text=>$lg{db} . ':',-anchor=>'e',-justify=>'right');
      $db_list = $c_d->BrowseEntry(-cursor=>undef,-variable=>\$v_db,-foreground=>$fc,-background=>$ec);
      my %ls_db;

      my @h = DBI->data_sources('dbi:Oracle:');
      my $h = @h;
      my @ic;
      my $ic;
      for ($i = 1;$i < $h;$i++){
         @ic = split(/:/,$h[$i]);
         $ic = @ic;
         $ls_db{$ic[($ic - 1)]} = 101;
      }
      open(DBFILE,"txt/orac_db_list.txt");
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
      my $l2 = $c_d->Label(-text=>$lg{sys_user} . ':',-anchor=>'e',-justify=>'right');
      $ps_u = $c_d->add("Entry",-cursor=>undef,-textvariable=>\$sys_user,-foreground=>$fc,-background=>$ec)->pack(side=>'right');
      my $l3 = $c_d->Label(-text=>$lg{sys_pass} . ':',-anchor=>'e',-justify=>'right');
      $ps_e = $c_d->add("Entry",-cursor=>undef,-show=>'*',-foreground=>$fc,-background=>$ec)->pack(side=>'right');

      Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
      Tk::grid($db_list,-row=>0,-column=>1,-sticky=>'ew');
      Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
      Tk::grid($ps_u,-row=>1,-column=>1,-sticky=>'ew');
      Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');
      Tk::grid($ps_e,-row=>2,-column=>1,-sticky=>'ew');

      $c_d->gridRowconfigure(1,-weight=>1);
      $db_list->focusForce;
      $mn_b = $c_d->Show;
      if ($mn_b eq $lg{connect}) {
         my $v_sys = $ps_u->get;
         if (defined($v_sys) && length($v_sys)){
            my $v_ps = $ps_e->get;
            if (defined($v_ps) && length($v_ps)){
               $ENV{TWO_TASK} = $v_db;
               $ENV{ORACLE_SID} = $v_db;
               $l_top_t = $lg{connecting};
               &bz;
               $dbh = DBI->connect('dbi:Oracle:',$v_sys,$v_ps);
               if (!defined($DBI::errstr)){
                  $dn = 1;
                  $val_con = 1;
                  $dbh->func(1000000,'dbms_output_enable');
                  if ((!defined($ls_db{$v_db})) || ($ls_db{$v_db} != 102)){
                     open(DBFILE,">>txt/orac_db_list.txt");
                     print DBFILE "$v_db\n";
                     close(DBFILE);
                  }
                  $l_top_t = "$v_db";
                  $sys_user = $v_sys;
               } else {
                  $l_top_t = "";
               }
               &ubz;
            } else {
               &mes($mw,$lg{system_please});
            }
         } else {
            &mes($mw,$lg{user_please});
         }
      } else {
         $dn = 1;
      }
   } until $dn;
}
sub get_db {
   &get_connected();
   unless ($val_con){
     &back_orac();
   }
   my $cm = &f_str('get_db','1');
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $sth->execute;
   ($Block_Size) = $sth->fetchrow;
   $sth->finish;
}
sub see_plsql {
   my ($res,$dum) = @_;
   my $b = $v_text->Button(-text=>$ssq,-command=>sub{&see_sql($mw,$res)});
   print TEXT "\n\n  ";
   $v_text->window('create','end',-window=>$b);
   print TEXT "\n\n";
}
sub see_sql {
   $_[0]->Busy;
   my $d = $_[0]->DialogBox(-title=>$ssq);
   my $t = $d->Scrolled('Text',-height=>16,-width=>60,-wrap=>'none',-cursor=>undef,-foreground=>$fc,-background=>$bc);
   $t->pack(-expand=>1,-fil=>'both');
   tie (*THIS_TEXT,'Tk::Text',$t);
   print THIS_TEXT "$_[1]\n";
   orac_Show($d);
   $_[0]->Unbusy;
}
sub about_orac {
   open(TXT_FILE,"README");
   while(<TXT_FILE>){
      print TEXT $_;
   }
   close(TXT_FILE);
}
sub bz {
   $mw->Busy;
}
sub ubz {
   $mw->Unbusy;
}
sub orac_print {
   my ($file) = @_;
   open (ORAC_PRINT,"txt/$file.txt");
   while(<ORAC_PRINT>){
      print TEXT $_;
   }
   close(ORAC_PRINT);
}
sub what_sql {
   my $d_txt = $lg{are_you_sure};
   my $chk_d = $mw->DialogBox(-buttons=>[ $lg{yes},$lg{no} ]);
   $chk_d->add("Label",-text=>$d_txt)->pack();
   my $b = $chk_d->Show;
   if($b eq $lg{yes} ){
      &prp_lp($lg{what_sql},'what_sql','1',$rp_8_opt4,0);
   }
}
sub set_printouts {
   $rp_big_lft = 'l:80';
   $rp_big_one_tince = 'r:7,l:72';
   $rp_big_one_tiny = 'r:5,l:74';
   $rp_two_splits = 'r:38,l:38';
   $rp_3_split = 'l:25,r:25,l:25';
   $rp_3_mid_big = 'r:12,r:45,r:12';
   $rp_4_mid_big = 'l:5,r:12,r:60,r:12';
   $rp_3_biggish = 'r:25,r:25,r:25';
   $rp_3_front_big = 'r:32,r:22,r:22';
   $rp_4_mid_big = 'l:5,r:12,r:40,r:12';
   $rp_4_big_front = 'l:18,l:18,l:18,r:18';
   $rp_4_end_big = 'l:11,l:15,l:5,l:42';
   $rp_4_stats = 'l:10,l:32,l:5,r:16';
   $rp_5_opt2 = 'l:4,l:20,r:31,r:6,r:6';
   $rp_5_opt5 = 'l:27,r:9,r:27,r:6,r:7';
   $rp_5_spread = 'r:20,r:11,r:11,r:12,r:11';
   $rp_5_errors = 'l:12,r:4,r:4,r:4,l:50';
   $rp_6_spread = 'r:12,r:10,r:10,r:12,r:5,r:23';
   $rp_6_opt4 = 'l:15,r:7,r:20,r:12,l:9,r:9';
   $rp_6_opt7 = 'l:10,l:12,r:5,r:5,l:28,l:12';
   $rp_6_opt8 = 'r:20,r:11,r:10,r:10,r:11,r:11';
   $rp_6_opt9 = 'l:18,r:7,r:8,r:11,r:11,r:8';
   $rp_7_opt2 = 'l:5,r:5,r:5,r:12,r:10,r:18,r:18';
   $rp_7_opt4 = 'r:4,l:15,l:17,r:9,r:9,r:8,r:10';
   $rp_8_bits = 'l:15,r:11,r:11,r:6,r:8,r:8,r:8,l:6';
   $rp_8a_bits = 'l:15,l:12,r:6,r:10,r:10,r:10,r:10,r:10';
   $rp_8_opt3 = 'l:10,l:20,l:5,l:20,r:4,r:4,r:6,r:3';
   $rp_8_opt4 = 'r:3,l:8,l:11,l:9,l:12,r:7,r:7,l:34';
   $rp_8_what = 'l:5,l:10,l:8,l:10,l:10,l:5,l:5,l:20';
   $rp_9_opt2 = 'l:10,r:5,l:12,r:5,r:5,l:7,l:15,r:9,r:9';
   $rp_9_opt7 = 'l:15,l:10,r:5,l:5,l:4,r:5,l:11,l:8,r:8';
   $rp_10_bits = 'l:8,r:5,r:5,r:8,r:5,r:10,r:18,r:4,r:3,r:3';
   $rp_10_opt3 = 'r:3,l:10,l:8,l:12,r:5,r:6,r:6,r:5,r:6,r:4';
   $rp_11_spread = 'l:4,l:12,l:10,l:12,r:5,r:5,r:5,r:5,r:4,r:4,r:4';
   $rp_hold_11 = 'l:10,l:8,r:5,r:5,r:5,r:2,l:10,l:8,r:5,r:5,r:5';
   $rp_biz_roll_2 = 'r:9,r:4,r:5,r:5,r:5,r:5,r:6,r:9,r:5,r:4,r:10,r:4,r:3,r:3,r:6';
}
sub f_str {
   my($sub,$number) = @_;
   my $file = sprintf("%s.%s.sql",$sub,$number);
   my $rt = "/* $file */\n";
   open(SQL,"sql/$file");
   while(<SQL>){
      $rt = $rt . $_;
   }
   close(SQL);
   return $rt;
}
sub crt_rp_do {
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
   for($i = 1;$i < $len_arr;$i++){
      ($part_1,$part_2) = split(/:/, $arr[$i]);
      if ($part_1 eq 'l'){
         $sub_bit = '<';
      } else {
         $sub_bit = '>';
      }
      for($j = 1;$j < $part_2;$j++){
         $sub_form = $sub_form . $sub_bit;
      }
      $format = $format . $sub_form;
      $sub_form = ' ^';
   }
   $format = $format . 'xyzzyxxyzzyx ~~';
   $j = @_;
   for($i = 0;$i < $j;$i++){
      if(!defined($_[$i])){
         $_[$i] = ' ';
      }
   }
   &cr_prt($format,$flag,$ln,@_);
   if($arr[0] eq 't'){
      @lines = crt_lines(@_);
      &cr_prt($format,$flag,$ln,@lines);
   }
}
sub crt_lines {
   my @ret = @_;
   my $len = @ret;
   my $i;
   for ($i = 0;$i < $len;$i++){
      $ret[$i] =~ s/./-/g;
   }
   return @ret;
}
sub cr_prt {
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
         if ($flag == 1){
            my $os_user = $_[7];
            my $oracl_user = $_[6];
            my $sid = $_[9];
            my $b = $v_text->Button(-text=>$lg{sql_quest},-padx=>0,-pady=>0,
                   -command=>sub{ $mw->Busy;&who_what($flag,$os_user,$oracl_user,$sid);$mw->Unbusy });
            $v_text->window('create', 'end',-window=>$b);
         }
         elsif ($flag == 3){
            my $stat = $_[0];
            my $b = $v_text->Button(-text=>"$lg{stat} $stat",-padx=>0,-pady=>0,
                   -command=>sub{ $mw->Busy;&who_what($flag,$stat);$mw->Unbusy });
            $v_text->window('create', 'end',-window=>$b);
         }
      }
      print TEXT "\n";
   }
}
sub get_Jared_sql {
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
   $tit = shift;
   $sub = shift;
   $num = shift;
   $frm = shift;
   $flag = shift;
   my @bindee = @_;
   my $num_bind = @bindee;
   my $cm;
   if($sub eq 'sel_addr'){
      $cm = &get_sel_stat('sys','v_$session');
      $frm = &get_frm($cm,8);
      $cm = $cm . ' where paddr = ? ';
   } elsif($sub eq 'database_info'){
      $cm = &get_sel_stat('sys','v_$database');
      $frm = &get_frm($cm,8);
   } elsif($sub eq 'Jared_cascade_button'){

      $cm = &get_Jared_sql($bindee[0],$bindee[1]);
      $frm = &get_frm($cm,5);
      $num_bind = 0;
   } else {
      $cm = &f_str($sub,$num);
   }
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 

   if ($num_bind > 0){
      my $i;
      for ($i = 1;$i <= $num_bind;$i++){
         $sth->bind_param($i,$bindee[($i - 1)]);
      }
   }
   $sth->execute;
   my $detected = 0;
   while (@res = $sth->fetchrow) {
      if (($detected == 0) &&($flag >= 0)){
         &tit_do($detected,$tit,$frm,$sth,$flag);
      }
      $detected++;
      &crt_frm(('b,' . $frm),$flag,$detected,@res);
   }
   if (($detected == 0) &&($flag >= 0)){
      &tit_do($detected,$tit,$frm,$sth);
      print TEXT "$lg{no_rows_found}\n";
   }
   if(($flag == 0)||($flag == 1)||($flag == -2)||($flag == 3)){
      see_plsql( $sth->{"Statement"} );
   }
   $sth->finish;
   return $cm;
} 
sub tit_do {
   my($detect,$tit,$frm,$sth,$flag) = @_;
   if((defined($tit)) && ((length($tit) > 0))){
      print TEXT "$lg{report} $tit ($v_db):\n\n";
   }
   my @tit_vals;
   my $i;
   for ($i = 0;$i < $sth->{NUM_OF_FIELDS};$i++){
      $tit_vals[$i] = $sth->{NAME}->[$i];
   }
   &crt_frm(('t,' . $frm),$flag,$detect,@tit_vals);
}
sub tune_wait {
   my $cm = &f_str('tune_wait','1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;
   my $j = 0;
   my $blnks = 0;
   my $get_str;
   while($j < 5000){
      $get_str = scalar $dbh->func('dbms_output_get');
      if(defined($get_str)){
         print TEXT "$get_str\n";
      }
      if ((!defined($get_str)) || (length($get_str) == 0)){
         $blnks++;
         if ($blnks > 10){
            last;
         }
      } else {
         $blnks = 0;
      }
      $j++;
   }
   &see_plsql($cm);
}
sub tune_pigs {
   my $cm = &f_str('tune_pigs','1');
   my $sth = $dbh->prepare($cm) || die $dbh->errstr; 
   $sth->execute;

   my $j = 0;
   my @banana;
   my $iopigs_fill_counter = 0;
   my $mempigs_fill_counter = 0;
   my $we_have_iopigs = 0;
   my $we_have_mempigs = 0;
   my $get_str;
   while($j < 2000){
      $get_str = scalar $dbh->func('dbms_output_get');
      if((defined($get_str)) && ($get_str =~ /\^/)){
         @banana = split(/\^/, $get_str);
         if ($banana[0] == 99){
            $the_top_title = "$banana[1]: $banana[2]\n\n";
         } elsif ($banana[0] == 3){
            $the_memory_title1 = "$banana[1]\n";
         } elsif ($banana[0] == 4){
            $the_memory_title2 = "$banana[1]\n\n";
         } elsif ($banana[0] == 5){
            $the_io_title1 = "\n\n$banana[1]\n";
         } elsif ($banana[0] == 6){
            $the_io_title2 = "$banana[1]\n\n";
         } elsif ($banana[0] > 200000){
            $mempigs_fill[$mempigs_fill_counter] = $get_str;
            $mempigs_fill_counter++;
            $we_have_mempigs = 1;
         } elsif ($banana[0] > 100000){
            $iopigs_fill[$iopigs_fill_counter] = $get_str;
            $iopigs_fill_counter++;
            $we_have_iopigs = 1;
         }
      }
      if ((defined($get_str)) || (length($get_str)) == 0){
         last;
      }
      $j++;
   }
   print TEXT $the_top_title;
   if (($we_have_mempigs == 0) && ($we_have_iopigs == 0)){
       print TEXT "$lg{no_hogs}";
   } else {
      if ($we_have_mempigs == 1){
         print TEXT $the_memory_title1;
         print TEXT $the_memory_title2;
         &crt_frm(('t,' . $rp_4_end_big),0,0,'Buffer Gets', 'Username', 'SID', 'SQL Text');
         for ($i = 0;$i < $mempigs_fill_counter;$i++){
            my @ar = split(/\^/, $mempigs_fill[$i]);
            &crt_frm(('b,' . $rp_4_end_big),0,0,$ar[3],$ar[1],$ar[2],$ar[6]);
         }
      }
      if ($we_have_iopigs == 1){
         print TEXT $the_io_title1;
         print TEXT $the_io_title2;
         &crt_frm(('t,' . $rp_6_spread),0,0,'Disk Reads','Execs','Reads/Exec','Username','SID','SQL Text');
         for ($i = 0;$i < $iopigs_fill_counter;$i++){
            my @ar = split(/\^/, $iopigs_fill[$i]);
            &crt_frm(('b,' . $rp_6_spread),0,0,$ar[3],$ar[4],$ar[5],$ar[1],$ar[2],$ar[6]);
         }
      }
   }
   &see_plsql($cm);
}
sub get_sel_stat {
   my($owner,$table) = @_;
   my $cm = "select column_name from dba_tab_columns where " .
            "upper(owner) = upper('${owner}') and upper(table_name) = upper('${table}') order by column_id ";
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
sub get_frm {
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
sub who_what {
   my ($flag,$param1,$oracle_user,$sid) = @_;
   my $title;
   if($flag == 1){
      $title = "$param1 $lg{investgn}";
   } elsif ($flag == 3){
      $title = "$lg{statis} $param1";
   }
   my $d = $mw->DialogBox(-title=>$title);
   my $loc_text = $d->Scrolled('Text',-wrap=>'none',-cursor=>undef,-foreground=>$fc,-background=>$bc);
   $loc_text->pack(-expand=>1,-fil=>'both');
   tie (*TEXT, 'Tk::Text', $loc_text);
   my $cm;
   if($flag == 1){
      $cm = &prp_lp($lg{hold_sql},'who_what','1',$rp_8_what,2,$param1,$oracle_user,$sid);
   } elsif ($flag == 3){
      $cm = &prp_lp("$lg{sess_mem}, $lg{statis} $param1",'statter','1',$rp_3_split,2,$param1);
   }
   my $b = $loc_text->Button(-text=>$ssq,-command=>sub{&see_sql($d,$cm)});
   $loc_text->window('create','end',-window=>$b);
   tie (*TEXT, 'Tk::Text', $v_text);
   &orac_Show($d);
}
sub all_stf {
   my $cm = &f_str($_[0],$_[1]);
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
   &see_plsql($cm);
}
sub orac_create_db {
   my ($oracle_sid,$dum) = split(/\./, $v_db);
   my $cm = &f_str('orac_create_db','1');
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
   &see_plsql($cm);
}
sub selected_error {
   my ($err_bit) = @_;
   &f_clr();
   my ($owner,$object) = split(/\./, $err_bit);
   &prp_lp("$lg{comp_errs_for} $err_bit",'selected_error','1',$rp_5_errors,0,$owner,$object);
}
sub univ_form { 
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
   my $t = $bd->Scrolled('Text',-height=>16,-wrap=>'none',-cursor=>undef,-foreground=>$fc,-background=>$bc);
   my $cm = &f_str('selected_dba','1');
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
         $w = $t->Entry(-textvariable=>\$sql_entry[$ind_bd_cnt],-cursor=>undef,-foreground=>$fc,-background=>$ec);
         $t->windowCreate('end',-window=>$w);
      }
      $t_t[$ind_bd_cnt] = "$res[1] $res[2]";
      $w = $t->Entry(-textvariable=>\$t_t[$ind_bd_cnt],-cursor=>undef);
      $t->windowCreate('end',-window=>$w);

      $i_ac[$ind_bd_cnt] = "$res[0]";

      $i_uc[$ind_bd_cnt] = 0;
      $w = $t->Checkbutton(-variable=>\$i_uc[$ind_bd_cnt],-relief=>'flat');
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
   $bb->Button(-text=>$uf_txt,-command=>sub{$bd->Busy;&selector($bd,$uf_type);$bd->Unbusy}
              )->pack(-side=>'right',-anchor=>'e');
   &orac_Show($bd);
}
sub selector {
   my($sel_d,$uf_type) = @_;

   if ($uf_type eq 'index'){
      &build_ord($sel_d,$uf_type);
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
   &build_ord($sel_d,$uf_type);
   &and_finally($sel_d,$l_sel_str);
}
sub and_finally {
   my($af_d,$cm) = @_;

   $ary_ref = $dbh->selectall_arrayref($cm);
   $min_row = 0;
   $max_row = @$ary_ref;
   if ($max_row == 0){
      &mes($af_d,$lg{no_rows});
   } else {
      $gc = $min_row;
      $c_d = $af_d->DialogBox(-title=>$m_t);
      my(@lb) = qw/-anchor n -side top -expand 1 -fill both/;
      my $top_frame = $c_d->Frame->pack(@lb);
   
      my $t = $top_frame->Scrolled('Text',-height=>16,-wrap=>'none',-cursor=>undef,-foreground=>$fc,-background=>$bc);
      for my $i (0..$ind_bd_cnt) {
         $lrg_t[$i] = "";
         $w = $t->Entry(-textvariable=>\$i_ac[$i],-cursor=>undef);
         $t->windowCreate('end',-window=>$w);
   
         $w = $t->Entry(-textvariable=>\$lrg_t[$i],-cursor=>undef,-foreground=>$fc,-background=>$ec,-width=>40);
         $t->windowCreate('end',-window=>$w);
         $t->insert('end', "\n");
      }
      $t->configure(-state=>'disabled');
      $t->pack(@lb);

      (@lb) = qw/-side bottom -expand no/;
      $c_br = $c_d->Frame->pack(@lb);
   
      $gen_sc = $c_br->Scale( -orient=>'horizontal',-label=>"$lg{rec_of} " . $max_row,-length=>400,
                              -sliderrelief=>'raised',-from=>1,-to=>$max_row,-tickinterval=>($max_row/8),
                              -command=>[ \&calc_scale_record ])->pack(side=>'left');
      $c_br->Button(-text=>$ssq,-command=>sub{&see_sql($c_d,$l_sel_str)}
                   )->pack(side=>'right');
      &go_for_gold();
      &orac_Show($c_d);
   }
   undef $ary_ref;
}
sub calc_scale_record {
   my($sv) = @_;
   $gc = $sv - 1;
   &go_for_gold();
}
sub go_for_gold {
   my $curr_ref = $ary_ref->[$gc];
   for my $i (0..$ind_bd_cnt) {
      $lrg_t[$i] = $curr_ref->[$i];
   }
   $gen_sc->set(($gc + 1));
}
sub build_ord {
   my($bl_d,$uf_type) = @_;
   my $l_chk = 0;
   for $i (0..$ind_bd_cnt){
      if ($i_uc[$i] == 1){
         $l_chk = 1;
      }
   }
   if ($l_chk == 1){
      &now_build_ord($bl_d,$uf_type);
      if ($uf_type eq 'index'){
         &really_build_index($bl_d,$own,$obj);
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
         &mes($bl_d,$lg{no_cols_sel});
      }
   }
}
sub now_build_ord {
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
   my $t = $b_d->Scrolled('Text',-height=>16,-wrap=>'none',-cursor=>undef,-foreground=>$fc,-background=>$bc);
   if ($uf_type eq 'index'){
      my $id_name = $lg{ind_name} . ':';
      $w = $t->Entry(-textvariable=>\$id_name,-background=>$fc,-foreground=>$ec);
      $t->windowCreate('end',-window=>$w);

      $ind_name = 'INDEX_NAME';
      $w = $t->Entry(-textvariable, \$ind_name,-cursor=>undef,-foreground=>$fc,-background=>$ec);
      $t->windowCreate('end',-window=>$w);
      $t->insert('end', "\n");

      my $tabp_name = $lg{tabsp} . ':';
      $w = $t->Entry(-textvariable=>\$tabp_name,-background=>$fc,-foreground=>$ec);
      $t->windowCreate('end',-window=>$w);

      $t_n = "TABSPACE_NAME";
      $t_l = $t->BrowseEntry(-cursor=>undef,-variable=>\$t_n,-foreground=>$fc,-background=>$ec);
      $t->windowCreate('end',-window=>$t_l);
      $t->insert('end', "\n");
   
      my $sth = $dbh->prepare( &f_str('now_build_ord','1') ) || die $dbh->errstr; 
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
         $w = $t->Entry(-textvariable=>\$pos_txt[$i],-width=>7,-background=>$fc,-foreground=>$ec);
      } else {
         if ($i == ($tot_i_cnt + 1)){
            $pos_txt[$i] = $lg{i_col};
            $w = $t->Entry(-textvariable=>\$pos_txt[$i],-background=>$fc,-foreground=>$ec);
         } else {
            unless ($uf_type eq 'index'){
               $pos_txt[$i] = $lg{i_desc};
               $w = $t->Entry(-textvariable=>\$pos_txt[$i],-width=>8,-background=>$fc,-foreground=>$ec);
            }
         }
      }
      $t->windowCreate('end',-window=>$w);
   }
   $t->insert('end', "\n");

   for $j_row (1..$tot_i_cnt){
      $ih[$j_row] = $j_row;
      $dsc_n[$j_row] = 0;
      $o_ih[$j_row] = $ih[$j_row];
      for $j_col (1..($tot_i_cnt + 2)){
         if ($j_col <= $tot_i_cnt){
            $w = $t->Radiobutton(-relief=>'flat',-value=>$j_row,-variable=>\$ih[$j_col],-width=>4,-command=>[\&j_inri]);
            $t->windowCreate('end',-window=>$w);
         } else {
            if ($j_col == ($tot_i_cnt + 1)){
               $w = $t->Entry(-textvariable=>\$tot_ind_ar[$j_row],-cursor=>undef,-foreground=>$fc,-background=>$ec);
               $t->windowCreate('end',-window=>$w);
            } else {
               unless ($uf_type eq 'index'){
                  $w = $t->Checkbutton(-variable=>\$dsc_n[$j_row],-relief=>'flat',-width=>6);
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
   my($rbi_d,$own,$obj) = @_;

   my $d = $rbi_d->DialogBox();
   $d->add("Label",-text=>"$lg{ind_crt_for} $own.$obj")->pack(side=>'top');
   my $l_text = $d->Scrolled('Text',-wrap=>'none',-cursor=>undef,-foreground=>$fc,-background=>$bc);
   $l_text->pack(-expand=>1,-fil=>'both');
   tie (*L_TXT, 'Tk::Text', $l_text);

   my $cm = &f_str('build_ind','1');
   for my $cl (1..$tot_i_cnt){
      my $bs = " v_this_build($cl) := '$tot_ind_ar[$ih[$cl]]'; ";
      $cm = $cm . $bs;
   }
   my $cm_part2 = &f_str('build_ind','2');
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

      ($pct_free,$initrans) = &ind_prep(&f_str('build_ind','3'),$own,$obj);
      ($n_rows) =             &ind_prep(&f_str('build_ind','4') . ' ' . $own . '.' . $obj . ' ');
      ($avail_data_space) =   &ind_prep(&f_str('build_ind','5'),$Block_Size,$initrans,$pct_free);
      ($space) =              &ind_prep(&f_str('build_ind','6'),$avail_data_space,$avg_entry_size,$avg_entry_size);
      ($blocks_req) =         &ind_prep(&f_str('build_ind','7'),$n_rows,$avg_entry_size,$space);
      ($initial_extent) =     &ind_prep(&f_str('build_ind','8'),$blocks_req,$Block_Size);
      ($next_extent) =        &ind_prep(&f_str('build_ind','9'),$initial_extent);

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

      my $b = $l_text->Button(-text=>"Calculation SQL",-command=>sub{&see_sql($d,$cm)});
      $l_text->window('create','end',-window=>$b);

      print L_TXT "\nrem Database Block Size:       ${Block_Size}\n";
      print L_TXT "rem Current Table Row Count:   ${n_rows}\n";
      print L_TXT "rem Available Space Per Block: ${avail_data_space}\n";
      print L_TXT "rem Space For Each Index:      ${space}\n";
      print L_TXT "rem Blocks Required:           ${blocks_req}\n\n";
   }
   &orac_Show($d);
}
sub ind_prep {
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
   my ($title,$func) = @_;
   my $d = $mw->DialogBox(-title=>"$title: $v_db ($lg{blk_siz} $Block_Size)");
   my $cf = $d->Frame;
   $cf->pack(-expand=>'1',-fill=>'both');
   my $c = $cf->Scrolled('Canvas',-relief=>'sunken',-bd=>2,-width=>500,-height=>280,-background=>$bc);
   $keep_tablespace = 'XXXXXXXXXXXXXXXXX';

   my $cm = &f_str($func,'1');
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
     &add_item( $func,$c,$i,$T_Space,$Fname,$Total,$Used_Mg,$Free_Mg,$Use_Pct);
     $i++;
   }
   $sth->finish;

   if($func ne 'tune_health'){
      $Grand_Use_Pct = (($Grand_Used_Mg/$Grand_Total)*100.00);
      &add_item($func,$c,0,'','',$Grand_Total,$Grand_Used_Mg,$Grand_Free_Mg,$Grand_Use_Pct);
   }

   my $b = $c->Button( -text=>$ssq,-command=>sub{&see_sql($d,$cm)});
   my $y_start = &work_out_why($i);
   $c->create('window', '1c',"$y_start" . 'c',-window=>$b,qw/-anchor nw -tags item/);
   $c->configure(-scrollregion=>[ $c->bbox("all") ]);
   $c->pack(-expand=>'yes',-fill=>'both');
   &orac_Show($d);
}
sub work_out_why {
    return (0.8 + (1.2 * $_[0]));
}
sub add_item
{
   my ($func,$c,$i,$T_Space,$Fname,$Total,$Used_Mg,$Free_Mg,$Use_Pct) = @_;
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
   my $y_start = &work_out_why($i);
   my $y_end = $y_start + 0.4;
   my $chopper;
   if($func ne 'tune_health'){
      $chopper = 20.0;
   } else {
      $chopper = 10.0;
   }
   $dst_f = ($Use_Pct/$chopper) + 0.4;
   $c->create(('rectangle', "$dst_f" . 'c',"$y_start". 'c','0.4c',"$y_end" . 'c'),-fill=>$hc);
  
   $y_start = $y_start - 0.4;
   if($i == 0){
      my $bit = '';
      $this_text = "$lg{db} " . sprintf("%5.2f", $Use_Pct) . '% '. $lg{full} . $bit;
   } else {
      $this_text = "$tab_str $Fname " . sprintf("%5.2f", $Use_Pct) . '%';
   }
   $c->create(('text','0.4c',"$y_start" . 'c',-anchor=>'nw',-justify=>'left',-text=>$this_text));
   $y_start = $y_start + 0.4;
   if($func ne 'tune_health'){
      $c->create(('text','5.2c',"$y_start" . 'c',-anchor=>'nw',-justify=>'left',
             -text=>sprintf("%10.2fM Total %10.2fM Used %10.2fM Free",$Total, $Used_Mg, $Free_Mg)));
   }
}
sub dbwr_fileio {
   my $this_title = "$lg{file_io} $v_db";
   my $d = $mw->DialogBox(-title=>$this_title);
   my $cf = $d->Frame;
   $cf->pack(-expand=>'1',-fill=>'both');

   my $c = $cf->Scrolled('Canvas',-relief=>'sunken',-bd=>2,-width=>500,-height=>280,-background=>$bc);
   my $cm = &f_str('dbwr_fileio','1');

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
         &dbwr_print_fileio($c, $max_value, $i,$dbwr_fi[$i][0],$dbwr_fi[$i][1],$dbwr_fi[$i][2],
         $dbwr_fi[$i][3],$dbwr_fi[$i][4],$dbwr_fi[$i][5],$dbwr_fi[$i][6]);
      }
   }
   my $b = $c->Button(-text=>$ssq,-command=>sub{&see_sql($d,$cm)});
   my $y_start = &this_pak_get_y(($i + 1));
   $c->create('window', '1c', "$y_start" . 'c',-window=>$b,qw/-anchor nw -tags item/);
   $c->configure(-scrollregion=>[ $c->bbox("all") ]);
   $c->pack(-expand=>'yes',-fill=>'both');
   &orac_Show($d);
}
sub this_pak_get_y {
   return (($_[0] * 2.5) + 0.2);
}
sub dbwr_print_fileio {
   my ($c,$max_value,$y_start,$name,$phyrds,$phywrts,$phyblkrd,$phyblkwrt,$readtim,$writetim) = @_;
   @stf = ('', $phyrds,$phywrts,$phyblkrd,$phyblkwrt,$readtim,$writetim);
   my $local_max = $stf[1];
   for $i (2 .. 6){
      if($stf[$i] > $local_max){
         $local_max = $stf[$i];
      }
   }
   @txt_stf = ('', 'phyrds','phywrts','phyblkrd','phyblkwrt','readtim','writetim');

   my $screen_ratio = 0.00;
   $screen_ratio = ($max_value/10.00);
   $txt_name = 0.1;

   $x_start = 2;
   $y_start = &this_pak_get_y($y_start);
   $act_figure_pos = $x_start + ($local_max/$screen_ratio) + 0.5;
   my $i;
   for $i (1 .. 6){
      $x_stop = $x_start + ($stf[$i]/$screen_ratio);
      $y_end = $y_start + 0.2;

      $c->create(('rectangle',"$x_start" . 'c',"$y_start" . 'c',"$x_stop" . 'c',"$y_end" . 'c'),-fill=>$hc);
      $txt_y_start = $y_start - 0.15;

      $c->create(('text', "$txt_name" . 'c', "$txt_y_start" . 'c',-anchor=>'nw',-justify=>'left',-text=>"$txt_stf[$i]"));
      $c->create(('text', "$act_figure_pos" . 'c', "$txt_y_start" . 'c',-anchor=>'nw',-justify=>'left',-text=>"$stf[$i]"));
      $y_start = $y_start + 0.3;
   }
   $txt_y_start = $y_start - 0.10;

   $c->create(('text', "$x_start" . 'c', "$txt_y_start" . 'c',-anchor=>'nw',-justify=>'left',-text=>"$name"));
}
sub gn_hl {
   ($g_typ,$g_hlst,$gen_sep) = @_;

   $g_mw = $mw->DialogBox(-title=>"$g_hlst $v_db");
   $hlist = $g_mw->Scrolled('HList',-drawbranch=>1,-separator=>$gen_sep,-indent=>50,-width=>50,-height=>20,
                            -command=>\&show_or_hide_tab,-foreground=>$fc,-background=>$bc);
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

   my $cm = &f_str( &hl_trans($g_hlst) ,'1');
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;

   while (@res = $sth->fetchrow) {
      my $owner = $res[0];
      $hlist->add($owner,-itemtype=>'imagetext',-image=>$closed_folder_bitmap,-text=>$owner);
      $all_the_owners{"$owner"} = 'closed';
   }
   $sth->finish;
   &orac_Show($g_mw);
}
sub show_or_hide_tab {
   my $hlist_thing = $_[0];
   if(!$all_the_owners{"$hlist_thing"}){
      &do_a_generic($hlist_thing, 'Normal', 'dum');
      return;
   } else {
      if($all_the_owners{"$hlist_thing"} eq 'closed'){
         $hlist->info('next', $hlist_thing);
         $hlist->entryconfigure($hlist_thing,-image=>$open_folder_bitmap);
         $all_the_owners{"$hlist_thing"} = 'open';
         
         &add_generics($hlist_thing);
      } else {
         $hlist->entryconfigure($hlist_thing,-image=>$closed_folder_bitmap);
         $hlist->delete('offsprings', $hlist_thing);
         $all_the_owners{"$hlist_thing"} = 'closed';
      }
   }
}
sub add_generics {
   $g_mw->Busy;
   my $owner = $_[0];
   if ($g_typ == 1){
      my $sth = $dbh->prepare( &f_str( &hl_trans($g_hlst) ,'2') ) || die $dbh->errstr; 
      $sth->bind_param(1,$owner);
      $sth->execute;
      while (@res = $sth->fetchrow) {
         my $gen_thing = "$owner" . $gen_sep . "$res[0]";
         $hlist->add($gen_thing,-itemtype=>'imagetext',-image=>$file_bitmap,-text=>$gen_thing);
      }
      $sth->finish;
   } else {
      my $gen_thing = "$owner" . $gen_sep . 'sql';
      $hlist->add($gen_thing,-itemtype=>'imagetext',-image=>$file_bitmap,-text=>$gen_thing);
   }
   $g_mw->Unbusy;
}
sub do_a_generic {
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
   my $cm = &f_str( &hl_trans($loc_g_hlst) ,'3');

   $dbh->func(1000000, 'dbms_output_enable');
   my $second_sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   if($g_typ == 1){
      $second_sth->bind_param(1,$owner);
      $second_sth->bind_param(2,$generic);
      if (($loc_g_hlst eq $lg{tabs})||($loc_g_hlst eq $lg{indexs})){
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
   $b[0] = $l_txt->Button(-text=>$ssq,-command=>sub{&see_sql($d,$cm)});
   $l_txt->window('create', 'end',-window=>$b[0]);

   if ($loc_g_hlst eq $lg{tabs}){
      print L_TEXT "\n\n  ";
      my(@tab_options) = qw/$lg{indexs} $lg{constrnts} $lg{trggrs} $lg{comments}/;
      my $i = 1;
      foreach ($lg{indexs},$lg{constrnts},$lg{trggrs},$lg{comments}){
         my $this_txt = $_;
         $b[$i] = $l_txt->Button(-text=>"$this_txt",-command=>sub{&do_a_generic($input,'Recursive',"$this_txt")});
         $l_txt->window('create', 'end',-window=>$b[$i]);
         print L_TEXT " ";
         $i++;
      }
      print L_TEXT "\n\n  ";
      $b[$i] = $l_txt->Button(-text=>$lg{form},-command=>sub{$d->Busy;&univ_form($d,$owner,$generic,'form');$d->Unbusy });
      $l_txt->window('create', 'end',-window=>$b[$i]);
      $i++;
      print L_TEXT " ";
      $b[$i] = $l_txt->Button(-text=>$lg{build_index},-command=>sub{$d->Busy;&univ_form($d,$owner,$generic,'index');$d->Unbusy });
      $l_txt->window('create','end',-window=>$b[$i]);
   }
   print L_TEXT "\n\n";
   &orac_Show($d);
   $g_mw->Unbusy;
}
sub mes {
   my $d = $_[0]->DialogBox();
   $d->Label(text=>$_[1])->pack();
   &orac_Show($d);
}
sub sub_win {
   my($flg,$lw,$mod,$pack,$tit,$width) = @_;
   my $cm = &f_str($mod,$pack);
   my $sth = $dbh->prepare( $cm ) || die $dbh->errstr; 
   $sth->execute;
   my $detected = 0;
   while (@res = $sth->fetchrow) {
      $detected++;
      if($detected == 1){
         $sw[$flg] = MainWindow->new();
         $sw[$flg]->title($tit);
         $sw[$flg]->Label( text  =>$lg{doub_click}, anchor=>'n', relief=>'groove')->pack(-expand=>'no');
         $sw_hand[$flg] = $sw[$flg]->ScrlListbox(-width=>$width,-background=>$bc,
              -foreground=>$fc)->pack(-expand=>'yes',-fill=>'both');
         my(@lay_exf) = qw/-side bottom -anchor se -padx 5 -expand no/;
         my $exf = $sw[$flg]->Frame->pack(@lay_exf);
         $exf->Button(-text=>$lg{exit},-command=>sub{$sw[$flg]->withdraw();$sw_flg[$flg]->configure(-state=>'active')} 
             )->pack(-side=>'bottom',-anchor=>'se');
      }
      $sw_hand[$flg]->insert('end', @res);
   }
   $sth->finish;
   if($detected == 0){
      $lw->Busy;
      &mes($lw,$lg{no_rows_found});
      $lw->Unbusy;
   } else {
      $sw_flg[$flg]->configure(-state=>'disabled');
      $sw_hand[$flg]->pack();
      if ($flg == 0){
         $sw_hand[$flg]->bind('<Double-1>',
           sub{ $sw[$flg]->Busy;&univ_form($sw[$flg],'SYS',$sw_hand[$flg]->get('active'),'form');$sw[$flg]->Unbusy});
      } elsif ($flg == 1){
         $sw_hand[$flg]->bind('<Double-1>', 
             sub{$sw[$flg]->Busy;&selected_error($sw_hand[$flg]->get('active'));$sw[$flg]->Unbusy});
      } elsif ($flg == 2){
         $sw_hand[$flg]->bind('<Double-1>', sub{$sw[$flg]->Busy;
             &prp_lp('Paddr Results','sel_addr','','',0,$sw_hand[$flg]->get('active'));$sw[$flg]->Unbusy});
      } elsif ($flg == 3){
         $sw_hand[$flg]->bind('<Double-1>', sub{$sw[$flg]->Busy;
             &prp_lp('Sid Stats','sel_sid','1',$rp_4_mid_big,0,$sw_hand[$flg]->get('active'));$sw[$flg]->Unbusy});
      }
   }
}
sub orac_Show {
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
   eval {
      $v_text->configure(-background=>$bc);
   };
   my $comp_str = "";
   my $i;
   for ($i = 0;$i < 5;$i++){
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
   open(TITLES_FILE, "txt/language.txt");
   my @language;
   undef %lg;
   while(<TITLES_FILE>){
      chomp;
      @language = split(/\^/, $_);
      $lg{$language[0]} = $language[1];
   }
   close(TITLES_FILE);
}
sub hl_trans {
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
sub Jareds_tools {
   if(!defined($jt)){
      $comm_str = 
          ' $jt = $mb->Menubutton(-text=>$lg{my_tools},-relief=>\'raised\',-borderwidth=>2,-menuitems=> ' . "\n" .
     ' [[Button=>$lg{help_with_tools},-command=>sub{&bz;&f_clr;&orac_print(\'help_with_tools\');&ubz}], ' . "\n" .
     '  [Cascade=>$lg{config_tools},-menuitems => ' . "\n" .
     '   [[Button=>$lg{config_add_casc},-command=>sub{&bz;&config_Jared_tools(1);&ubz},], ' . "\n" .
     '    [Button=>$lg{config_edit_casc},-command=>sub{&bz;&config_Jared_tools(6);&ubz},], ' . "\n" .
     '    [Button=>$lg{config_del_casc},-command=>sub{&bz;&config_Jared_tools(2);&ubz},], ' . "\n" .
     '    [Separator=>\'\'], ' . "\n" .
     '    [Button=>$lg{config_add_butt},-command=>sub{&bz;&config_Jared_tools(3);&ubz},], ' . "\n" .
     '    [Button=>$lg{config_edit_butt},-command=>sub{&bz;&config_Jared_tools(7);&ubz},], ' . "\n" .
     '    [Button=>$lg{config_del_butt},-command=>sub{&bz;&config_Jared_tools(4);&ubz},], ' . "\n" .
     '    [Separator=>\'\'], ' . "\n" .
     '    [Button=>$lg{config_edit_sql},-command=>sub{&bz;&config_Jared_tools(5);&ubz},],], ' . "\n" .
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
                        ' [Button=>\'' . $jt_casc_butts[3] . '\',-command=>sub{&bz; &f_clr; ' . "\n" .
                        ' &run_Jareds_tool(\'' . $jt_casc[1] . '\',\'' . $jt_casc_butts[2] . '\');&ubz}], ' . "\n";
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
   my($filename) = @_;
   &orac_copy($filename,"${filename}.old");
   open(SAV_SQL,">$filename");
   print SAV_SQL $sw_hand[4]->get("1.0", "end");
   close(SAV_SQL);
   $ed_sql_txt_cnt++;
   $ed_sql_txt = "$ed_fl_txt: $filename $lg{saved}" . ' #' . $ed_sql_txt_cnt;
}
sub ed_butt {
   my($casc,$butt) = @_;
   $ed_fl_txt = &get_butt_text($casc,$butt);
   $sql_file = 'tools/sql/' . $casc . '.' . $butt . '.sql';
   $sw[4] = MainWindow->new();
   $sw[4]->title("$lg{cascade} $casc, $lg{button} $butt");
   $ed_sql_txt = "$ed_fl_txt: $lg{ed_sql_txt}";
   $ed_sql_txt_cnt = 0;
   $sw[4]->Label( -textvariable  => \$ed_sql_txt, -anchor=>'n', -relief=>'groove')->pack(-expand=>'no');
   $sw_hand[4] = $sw[4]->Scrolled('Text',-wrap=>'none',-cursor=>undef,
                      -foreground=>$fc,-background=>$bc)->pack(-expand=>'yes',-fill=>'both');
   my(@lay) = qw/-side bottom -padx 5 -fill both -expand no/;
   my $f = $sw[4]->Frame->pack(@lay);
   $f->Button(-text=>$lg{exit},-command=>sub{$sw[4]->withdraw()})->pack(-side=>'right',-anchor=>'e');
   $f->Button(-text=>$lg{save},-command=>sub{&save_sql($sql_file)})->pack(-side=>'right',-anchor=>'e');
   $f->Label(-text=>$lg{no_semi_colon},-relief=>'sunken')->pack(-side=>'left',-anchor=>'w');

   if(open(SQL_SAV,$sql_file)){
      while(<SQL_SAV>){ $sw_hand[4]->insert("end", $_); }
      close(SQL_SAV);
   }
}
sub config_Jared_tools {
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
               &sort_Jareds_file();
               if($param == 99){
                  &ed_butt($loc_casc,$main_inp_value);
               }
            }
         } else {
            &mes($d,$lg{no_val_def});
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
                     ($safe_flag,$ed_txt) = &config_Jared_tools(69,$fin_inp);
                  } elsif($param == 7) {
                     ($safe_flag,$sec_inp) = &config_Jared_tools(59,$fin_inp);
                     if ((defined($safe_flag)) && (length($safe_flag)) && ($safe_flag == 1)){
                        ($safe_flag,$ed_txt) = &config_Jared_tools(49,$fin_inp,$sec_inp);
                     }
                  } elsif($param == 59) {
                     $safe_flag = 0;
                     return (1,$fin_inp);
                  } else {
                     $safe_flag = 1;
                  }
                  if ((defined($safe_flag)) && (length($safe_flag)) && ($safe_flag == 1)){
                     &orac_copy('tools/config.tools','tools/config.tools.old');
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
                     &sort_Jareds_file();
                  }
               } elsif($param == 3) {
                  &config_Jared_tools(99,$fin_inp);
               } elsif($param == 5) {
                  &config_Jared_tools(79,$fin_inp);
               } elsif($param == 79) {
                  my $filename = 'tools/sql/' . $loc_casc . '.' . $fin_inp . '.sql';
                  &ed_butt($loc_casc,$fin_inp);
               } else {
                  &config_Jared_tools(89,$fin_inp);
               }
            } else {
               &mes($d,$lg{no_val_def});
            }
         }
      } else {
         &mes($mw,$lg{no_cascs});
         if ($param == 59){
            return (0,'');
         }
      }
   }
   &del_Jareds_tools;
   &Jareds_tools;
}
sub sort_Jareds_file {
   &orac_copy('tools/config.tools','tools/config.tools.sort');
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
   my($casc,$butt) = @_;
   my $title = '';
   $title = &get_butt_text($casc,$butt);
   &prp_lp($title,'Jared_cascade_button','0','0',0,$casc,$butt);
}
sub del_Jareds_tools {
   if(defined($jt)){
      $jt->destroy();
      $jt = undef;
   }
}
sub orac_copy {
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
BEGIN {
   $SIG{__WARN__} = sub{
      if (defined $mw) {
         &mes($mw,$_[0]);
      } else {
         print STDOUT join("\n",@_),"n";
      }
   };
}
