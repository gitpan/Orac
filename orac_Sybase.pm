package orac_Sybase;
use strict;

@orac_Sybase::ISA = qw{orac_Base};

my @dbs;
my $cur_db;
my $sql_text;


my @w_holders;
my @w_titles;
my @w_explain;


my $l_sel_str;
my $loc_d;

my $expl_butt;
my $gen_sc;
my $gc;
my $max_row;
my $min_row;
my $uf_type;

my $ind_name;
my $t_n;
my $tot_i_cnt;
my $ind_bd_cnt;

my @o_ih;
my @sql_entry;
my @i_uc;
my @i_ac;
my @lrg_t;
my @ih;
my @dsc_n;
my @tot_ind_ar;

my $ary_ref;
my $w;
my $m_t;

my $own;
my $obj;

my $col_count;
my $sql_txt;

sub new
{
   my $proto = shift;
   my $class = ref($proto) || $proto;

   my ($l_window, $l_text) = @_;

   my $self  = orac_Base->new("Sybase", $l_window, $l_text);

   bless($self, $class);
   return $self;
}

sub init1{
   my $self = shift;
}

sub init2 {
   my $self = shift;
   $self->{Database_conn} = $_[0];
   $self->Dump;

   my $cm = $self->f_str('get_db','1');
   my $sth = $self->{Database_conn}->prepare($cm) || 
                 die $self->{Database_conn}->errstr;
   $sth->execute;

   while ($cur_db = $sth->fetchrow) {
       push @dbs, $cur_db;
   }  
   $sth->finish;
}

sub add_cascade_button {

    my $self = shift;

    local ($_);
    my($cmd_menu);

    for (@_) {
	/^tbl_rev$/ && do { $cmd_menu = '$main::current_db->syb_reverse_tbl("'; next;};
	/^diag_ind$/ && do { $cmd_menu = '$main::current_db->syb_bad_index("'; next;};
	/.*?/ && do { return;} ;
    }

    my ($cmd);
    for (@dbs) {
      $cmd .= '$main::casc_item->radiobutton(-label=>"'.$_.'",-command=>sub{$main::current_db->f_clr($main::v_clr);'.$cmd_menu.$_.'");});'."\n";
    }
    return $cmd;
}

sub syb_bad_index {
    my $self = shift;

    my($db) = @_;

    $self->{Database_conn}->do("use $db");
    $self->show_sql('bad_index','1',$main::lg{diag_ind});
}

sub syb_reverse_db {
   my $self = shift;

   # Generates a script with which you can
   # completely regenerate the skeleton of your
   # database
   my $row;
   my $cm = 'exec sp__revdb';
   my $sth = $self->{Database_conn}->prepare( $cm ) || 
              die $self->{Database_conn}->errstr;
   $sth->execute;
   my $j = 0;
   while($row = $sth->fetchrow){
       $row = ($row =~ /^Create/ &&  $j++ > 0) ? "\n".$row."\n" : $row."\n";
       $self->{Text_var}->insert('end', $row);
   }  
   $sth->finish;
   $self->see_plsql($self->f_str('rev_db','1'));
}
sub syb_reverse_login {
    my $self = shift;
   # Generates a script with which you can
   # completely regenerate the skeleton of your
   # database

   my $cm = 'exec sp__revlogin';
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
               die $self->{Database_conn}->errstr;
   $sth->execute;
   my $j = 0;
   my $row;
   while($row = $sth->fetchrow){
       $self->{Text_var}->insert('end', $row."\n");
   }
   $sth->finish;
   $self->see_plsql($self->f_str('login_rev','1'));
}

sub syb_reverse_dev{
   my $self = shift;

   # Generates a script with which you can
   # completely regenerate the skeleton of your
   # database

   my $cm = 'exec sp__revdevice';
   my $sth =  $self->{Database_conn}->prepare( $cm ) || die $self->{Database_conn}->errstr; 
   $sth->execute;
   my $j = 0;
   my $row;
   while($row = $sth->fetchrow){
     $self->{Text_var}->insert('end', $row."\n");
   }  
   $sth->finish;
   $self->see_plsql($self->f_str('rev_dev','1'));
}

sub syb_reverse_tbl {
    my $self = shift;
    my($db) = @_;

    $self->{Database_conn}->do("use $db");
    my $cm = 'select name from sysobjects where type =\'U\' order by name';
    my $sth = $self->{Database_conn}->prepare($cm) || 
	        die $self->{Database_conn}->errstr; 
    $sth->execute;
    my @tables = ();
    my $row;
    while($row = $sth->fetchrow){
	push @tables, $row;
    }
    $sth->finish;
    
    $self->{Text_var}->insert('end', "/* Script for recreation of user objects in $db database */\n\n");
    my $another_row;
    for (@tables) {
	$sth = $self->{Database_conn}->prepare("exec sp_table $_") || 
	        die $self->{Database_conn}->errstr; 
	$sth->execute;
	do {
	    while($another_row = $sth->fetchrow){
		$self->{Text_var}->insert('end', $another_row."\n");
	    }       
	} while($sth->{syb_more_results});
	$self->{Text_var}->insert('end', "\n\n");
    }
    $sth->finish;

    $cm = 'select name from sysobjects where type in ("P", "TR", "V") order by name';
    $sth = $self->{Database_conn}->prepare($cm) || die $self->{Database_conn}->errstr; 
    $sth->execute;
    my @procs = ();
    while($row = $sth->fetchrow){
	push @procs, $row;
    }
    $sth->finish;

    $main::conn_comm_flag = 999;
    for (@procs) {
	undef $main::store_msgs;
	$self->{Database_conn}->do("use $db");
	$sth = $self->{Database_conn}->prepare("exec sp__helptext $_"); 
	$sth->execute;
	$main::store_msgs =~ s/^\s//g;
	$self->{Text_var}->insert('end', $main::store_msgs."\n");
	$self->{Text_var}->insert('end', "\n\n");
	$sth->finish;
    }
    undef $main::conn_comm_flag;
    undef $main::store_msgs;

  $self->see_plsql($self->f_str('rev_tbl','1'));
}


sub do_a_generic {
   my $self = shift;

   # On the final level of an HList, does the actual work
   # required.

   my ($l_mw, $l_gen_sep, $l_hlst, $input) = @_;

   print STDERR "do_a_generic: l_mw      >$l_mw<\n" if ($main::debug > 0);
   print STDERR "do_a_generic: l_gen_sep >$l_gen_sep<\n" if ($main::debug > 0);
   print STDERR "do_a_generic: l_hlst    >$l_hlst<\n" if ($main::debug > 0);
   print STDERR "do_a_generic: input     >$input<\n" if ($main::debug > 0);

   $l_mw->Busy;
   my $owner;
   my $generic;
   my $dum;
   my $gen_sep;

   ($owner, $generic, $dum) = split("\\$l_gen_sep", $input);
   
   my $loc_g_hlst;
   my $cm = $self->f_str($l_hlst ,'99');

   if ($l_hlst eq 'Segments' || $l_hlst eq 'All Objects') {
       $self->f_clr( $main::v_clr );
       $self->{Database_conn}->do("use $owner");
       my $reportHeader = ($l_hlst eq 'Segments') ? "Segment Allocation" : "All Objects in $owner";
       $self->show_sql($l_hlst, '99', $reportHeader, $generic, $owner);
       $l_mw->Unbusy;
       return;
   } else {
       $cm = ($l_hlst eq 'Groups') ? sprintf($cm, $generic, $generic) : sprintf($cm, $generic);
   }

   my $second_sth = $self->{Database_conn}->prepare( $cm ) ||
                      die $self->{Database_conn}->errstr; 
   # Deal with SQL print returns through the global message handler
   $main::conn_comm_flag = 999;
   $second_sth->execute;
   $main::conn_comm_flag = 0;
   my $d = $l_mw->DialogBox();

   $d->add("Label",
	   -text=>"$l_hlst $main::lg{sql_for} $owner.$generic"
	   )->pack(side=>'top');

   my $l_txt = $d->Scrolled('Text',
			    -width=>95,
			    -height=>24,
			    -wrap=>'none',
			    -cursor=>undef,
			    -foreground=>$main::fc,
			    -background=>$main::bc
			    )->pack(-expand=>1,-fil=>'both');

   tie (*L_TEXT, 'Tk::Text', $l_txt);

   my $j = 0;
   my $full_list;
   my $i = 1;
   $main::store_msgs =~ s/^\s//g;
   $main::store_msgs =~ s/go//mig;
   print L_TEXT $main::store_msgs if ($l_hlst eq 'Triggers' ||
				      $l_hlst eq 'Procedures' ||
				      $l_hlst eq 'RelatedProcedures' ||
				      $l_hlst eq 'RelatedTriggers' ||
				      $l_hlst eq 'Views');
   undef($main::store_msgs);
   my $another_row;
   do {
       while($another_row = $second_sth->fetchrow){
	   print L_TEXT $another_row, "\n";
       }       
   } while($second_sth->{syb_more_results});

   $second_sth->finish;
   my @b;
   $l_txt->window('create', 'end',-window=>$b[0]);

   if ($l_hlst eq 'Tables' || $l_hlst eq 'System Tables'){
       print L_TEXT "\n\n  ";
       my(@tab_options) = qw/$main::lg{indexs} $main::lg{constrnts} $main::lg{trggrs_dep} $main::lg{procs_dep} $main::lg{oi_grants}/;
       my $i = 1;
       foreach ($main::lg{indexs},$main::lg{constrnts},$main::lg{trggrs_dep}, $main::lg{procs_dep}, $main::lg{oi_grants}){
	   my $this_txt = $_;
	   $b[$i] = $l_txt->Button(-text=>"$this_txt",
				   -command=>sub {$self->do_a_generic($d, '.', $this_txt, $input);});
	   $l_txt->window('create', 'end',-window=>$b[$i]);

	   print L_TEXT " ";
	   $i++;
       }
       print L_TEXT "\n\n  ";

       $b[$i] = $l_txt->Button(-text=>$main::lg{form},
			       -command=>
			              sub{$d->Busy;
					  $self->univ_form($d,$owner,$generic,'form');$d->Unbusy });
       $l_txt->window('create', 'end',-window=>$b[$i]);
       $i++;
       print L_TEXT " ";
       $l_txt->window('create','end',-window=>$b[$i]);
   } elsif ($l_hlst eq 'Views'){
      print L_TEXT "\n\n  ";
      $b[1] = $l_txt->Button(-text=>$main::lg{form},
			     -command=>sub{$d->Busy; $self->univ_form($d,$owner,$generic,'form');$d->Unbusy });
      $l_txt->window('create', 'end',-window=>$b[1]);
   }
   print L_TEXT "\n\n";
   $d->Show($d);
   $l_mw->Unbusy;
}

sub explain_plan {
   my $self = shift;


   $main::swc{explain_plan} = MainWindow->new();
   $main::swc{explain_plan}->title($main::lg{explain_plan});

   my(@exp_lay) = qw/-side top -padx 5 -expand no -fill both/;
   my $dmb = $main::swc{explain_plan}->Frame->pack(@exp_lay);
   my $orac_li = $main::swc{explain_plan}->Photo(-file=>"$FindBin::RealBin/img/orac.gif");

   $dmb->Label(-image=>$orac_li,
	       -borderwidth=>2,
	       -relief=>'flat'
	       )->pack(-side=>'left',
		       -anchor=>'w');

   # Add buttons.  Add a holder for the actual explain plan
   # button so we can enable/disable it later

   my $expl_butt = $dmb->Button(-text=>$main::lg{explain},
				-command=>sub{ $self->explain_it();}
				)->pack(side=>'left');

   $dmb->Button(-text=>$main::lg{clear},
		-command=>sub{
                      $main::swc{explain_plan}->Busy;
                      $sql_txt->delete('1.0','end');
                      my $w_user_name = $main::v_sys;
                      $expl_butt->configure(-state=>'normal');
                      $main::swc{explain_plan}->Unbusy;
		  }
               )->pack(side=>'left');

   $dmb->Button(-text=>$main::lg{exit},
		-command=> sub{
                      $main::swc{explain_plan}->withdraw();
                      $main::swc{explain_plan}->Busy;
 		      my $cm = $self->f_str('explain_plan','3');
		      $self->{Database_conn}->do($cm);
		      $cm = $self->f_str('explain_plan','4');
		      $self->{Database_conn}->do($cm);
                      $main::swc{explain_plan}->Unbusy;
		      $main::sub_win_but_hand{explain_plan}->configure(-state=>'active');
		      undef $main::conn_comm_flag;
		  } 
               )->pack(-side=>'left');

   $dmb->Label(-text=>"     Use ",-borderwidth=>2,-relief=>'flat')->pack(-side=>'left',-anchor=>'w');

   # need to get a db list for dropdown
   my $sth;
   my $cm = "select db_name()";
   my @list = ();
   $sth = $self->{Database_conn}->prepare( $cm ) ||
             die $self->{Database_conn}->errstr; 
   $sth->execute;
   my $tmp = $sth->fetchrow;

   push @list, $tmp;
   $cm = $self->f_str('Tables' ,'1');
   $sth = $self->{Database_conn}->prepare( $cm ) || 
            die $self->{Database_conn}->errstr; 
   $sth->execute;
   my $row;
   while($row = $sth->fetchrow){
       push @list, $row unless ($row eq $tmp);
   }       
   $sth->finish;

   $dmb->Optionmenu(-options=> [@list],
		    -command=> sub{
		      $main::conn_comm_flag = 999;
		      my $cm = $self->f_str('explain_plan','3');
		      $self->{Database_conn}->do($cm);
		      $cm =  $self->f_str('explain_plan','4');
		      $self->{Database_conn}->do($cm);
		      $cm = "use ".shift;
		      $self->{Database_conn}->do($cm);
		      $cm = $self->f_str('explain_plan','1');
		      $self->{Database_conn}->do($cm);
		      $cm = $self->f_str('explain_plan','2');
		      $self->{Database_conn}->do($cm);},
		    -variable=> \$tmp
               )->pack(-side=>'left');

   @exp_lay = qw/-side top -padx 5 -expand yes -fill both/;
   my $top_slice = $main::swc{explain_plan}->Frame->pack(@exp_lay);

   my $sql_txt_width = 50;
   my $sql_txt_height = 15;
   $main::swc{explain_plan}->{text} = $top_slice->Scrolled('Text',
						   -wrap=>'none',
						   -cursor=>undef,
						   -height=>($sql_txt_height + 4),
						   -width=>($sql_txt_width + 10),
						   -foreground=>$main::fc,
						   -background=>$main::bc);
   # Set the holding variables

   my $w_user_name = '';
   my $w_orig_sql_string = '';

   $sql_txt = $main::swc{explain_plan}->{text}->Scrolled('Text',
							 -wrap=>'none',
							 -cursor=>undef,
							 -height=>$sql_txt_height,
							 -width=>$sql_txt_width+5,
							 -foreground=>$main::fc,
							 -background=>$main::ec);
   tie (*SQL_TXT, 'Tk::Text', $sql_txt);

   $main::swc{explain_plan}->{text}->windowCreate('end',-window=>$sql_txt);
   $main::swc{explain_plan}->{text}->insert('end', "\n");
   $main::swc{explain_plan}->{text}->pack(-expand=>1,-fil=>'both');
   $main::conn_comm_flag = 999;
   $cm = $self->f_str('explain_plan','1');
   $self->{Database_conn}->do($cm);
   $cm = $self->f_str('explain_plan','2');
   $self->{Database_conn}->do($cm);
   $main::swc{explain_plan}->{text}->configure(-state=>'disabled');
   $self->iconize($main::swc{explain_plan});
   return;
}

sub explain_it {
   my $self = shift;

   # Takes the SQL statement directly from the screen
   # and tries an 'Explain Plan' on it. 
   undef($main::store_msgs);
   my $cm = $sql_txt->get("1.0", "end");
   $cm =~ s/\s+$//g;
   return unless $cm;
   my $sth = $self->{Database_conn}->prepare( $cm ) ||
               die $self->{Database_conn}->errstr; 
   $sth->execute;

   # Clear screen where required.
   $self->f_clr( $main::v_clr );

   # Now clean up the output since it actually believes
   # that the execution has failed
   
   $main::store_msgs =~ s/^(.*?)text=//mg;
   $main::store_msgs =~ s/^\s//g;
   $main::store_msgs =~ s/go//mig;
   $self->{Text_var}->insert('end', $main::store_msgs);
   undef($main::store_msgs);
   $sth->finish;
   $self->see_plsql( $cm );
}

# Undocumented and dangerous !!!!!!!!!!
# requires sybase_ts_role
sub dbcc_pss {
    # DO NOT CODE LIKE THIS EVER !!!
    my $self = shift;
    my (@row, @result);
    $main::conn_comm_flag = 999;
    $self->f_clr( $main::v_clr );
    my $cm = 'select distinct spid, suid, suser_name(suid) from master..sysprocesses where suid > 0';
    my $sth = $self->{Database_conn}->prepare($cm) ||
	       die $self->{Database_conn}->errstr; 
    $sth->execute;
    while(@row = $sth->fetchrow){
	push @result, join(":",@row);
    }
    $sth->finish;
    $self->{Database_conn}->do("dbcc traceon (3604)");

    my ($suid, $spid, $uname, @tempArray, @tempArray2);
    for (@result) {
	($spid, $suid, $uname) = split(/:/, $_);
	$self->{Text_var}->insert('end', "SQL executed by $uname (Session ID $spid): \n\n");
	undef($main::store_msgs);
	$self->{Database_conn}->do("dbcc pss ($suid, $spid, 0)");
	@tempArray =  split(/T-SQL command \(may be truncated\):/, $main::store_msgs);
	$tempArray[1] =~ s/^(.*?)DBD.*/$1/mg;
	$tempArray[1] =~ s/^(.*?)\}.*/$1/mg;
	$tempArray[1] =~ s/^\s+(.*?)/$1/mg;
        @tempArray2 = split (/\n/, $tempArray[1]);
	for (@tempArray2) {
	    $self->{Text_var}->insert('end', "$_\n") if ($_ ne '');
	}
	$self->{Text_var}->insert('end', "\n************************************************************************************\n\n");
	undef($main::store_msgs);
    }

    undef($main::conn_comm_flag);
}

sub create_device {
    my $self = shift;
    my ($lname, $pname,$vdevno, $size, $ctrlnum) = @_;
    
    main::bz();
    $vdevno = ($vdevno > 2) ? $vdevno : 2;
    $ctrlnum = ($ctrlnum != 0) ? $ctrlnum : 0;

    my $d = $main::mw->DialogBox(-title => $main::lg{dev_crt}, -buttons => ["Create", "Cancel", "Show SQL"]);
    my $l1 = $d->Label(-text=> "Logical Name:", justify=>"right");
    my $ps_l = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$lname,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l2 = $d->Label(-text=>"Physical name:", justify=>"right");
    my $ps_p = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$pname,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l3 = $d->Label(-text=>"Virtual Device Number:", justify=>"right");
    my $ps_v = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$vdevno,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l4 = $d->Label(-text=>"Size (MB):", justify=>"right");
    my $ps_s = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$size,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l5 = $d->Label(-text=>"Controller Number:", justify=>"right");
    my $ps_c = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$ctrlnum,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();



    Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
    Tk::grid($ps_l,-row=>0,-column=>1,-sticky=>'ew');
    Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
    Tk::grid($ps_p,-row=>1,-column=>1,-sticky=>'ew');
    Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');
    Tk::grid($ps_v,-row=>2,-column=>1,-sticky=>'ew');
    Tk::grid($l4,-row=>2,-column=>2,-sticky=>'e');
    Tk::grid($ps_s,-row=>2,-column=>3,-sticky=>'ew');
    Tk::grid($l5,-row=>1,-column=>2,-sticky=>'e');
    Tk::grid($ps_c,-row=>1,-column=>3,-sticky=>'ew');
                
        
    $d->gridRowconfigure(1,-weight=>1);
    my $button = $d->Show;

    my($cmd) = sprintf "DISK INIT\nNAME='%s',\nPHYSNAME='%s',\nVDEVNO=%d,\nSIZE=%d,\nCNTRLTYPE=%d\n",
	                                                                                                $lname,
	                                                                                                $pname,
	                                                                                                $vdevno,
	                                                                                                $size,
 	                                                                                                $ctrlnum;
    if ($button eq 'Show SQL') {
	$self->show_sql_dialog($main::lg{dev_crt}, $cmd, $d);
	$self->create_device($lname, $pname, $vdevno, $size, $ctrlnum);
    } elsif ($button eq 'Create') {
	print $cmd;
	$self->f_clr( $main::v_clr );
    }
}

sub create_dump_device {
    my $self = shift;
    my ($dtype, $lname, $pname, $size) = @_;
    
    main::bz();

    my $d = $main::mw->DialogBox(-title => $main::lg{dev_dump_crt}, -buttons => ["Create", "Cancel", "Show SQL"]);
    my $l1 = $d->Label(-text=> "Logical Name:", justify=>"right");
    my $ps_l = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$lname,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l2 = $d->Label(-text=>"Physical name:", justify=>"right");
    my $ps_p = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$pname,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l3 = $d->Label(-text=>"Size (MB):", justify=>"right");
    my $ps_s = $d->add("Entry",-cursor=>undef, 
		    -textvariable=>\$size, 
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l4 = $d->Label(-text=>"Device type:", justify=>"right");
  
    my $ps_d = $d->Radiobutton(variable=>\$dtype,
		    text=>$main::lg{disk},
		    value=>'disk')->pack(); 

    my $ps_d1 = $d->Radiobutton(variable=>\$dtype,
		    text=>$main::lg{tape},
		    value=>'tape')->pack(); 

    Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
    Tk::grid($ps_l,-row=>0,-column=>1,-sticky=>'ew');
    Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
    Tk::grid($ps_p,-row=>1,-column=>1,-sticky=>'ew');
    Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');
    Tk::grid($ps_s,-row=>2,-column=>1,-sticky=>'ew');
    Tk::grid($l4,-row=>2,-column=>2,-sticky=>'e');
    Tk::grid($ps_d,-row=>2,-column=>3,-sticky=>'ew');
    Tk::grid($ps_d1,-row=>3,-column=>3,-sticky=>'ew');                                
        
    $d->gridRowconfigure(1,-weight=>1);
    my $button = $d->Show;

    my($cmd) = sprintf "sp_addumpdevice '%s', '%s', '%s', %d\n", $dtype, $lname, $pname, $size;

    if ($button eq 'Show SQL') {
	$self->show_sql_dialog($main::lg{dev_dump_crt}, $cmd, $d);
	$self->create_dump_device($dtype, $lname, $pname, $size);
    } elsif ($button eq 'Create') {
	$self->{Database_conn}->do($cmd);
	$self->f_clr( $main::v_clr );
    }
}

sub create_login {
    my $self = shift;
    my ($uname, $passwd, $fname, $locked, $defdb, @roles) = @_;
    
    my $row;
    my @list = ();
    my $cm = $self->f_str('Tables' ,'1');
    my $sth = $self->{Database_conn}->prepare( $cm ) || 
	        die $self->{Database_conn}->errstr; 
    $sth->execute;
    
    while($row = $sth->fetchrow){
	push @list, $row;
    }       
    $sth->finish;
    
    main::bz();
    
    my $d = $main::mw->DialogBox(-title => $main::lg{login_crt}, -buttons => ["Create", "Cancel", "Show SQL"]);
    my $l1 = $d->Label(-text=> "User Name:", justify=>"right");
    my $ps_l = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$uname,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l2 = $d->Label(-text=>"Password:", justify=>"right");
    my $ps_p = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$passwd,
		    -show=>'*',
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l3 = $d->Label(-text=>"Full Name:", justify=>"right");
    my $ps_s = $d->add("Entry",-cursor=>undef, 
		    -textvariable=>\$fname,   
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l5 = $d->Label(-text=>"Locked:", justify=>"right");
    my $ps_lk = $d->Checkbutton(-onvalue=>"Locked",
				-offvalue=>'',
				-cursor=>undef,
				-variable=>\$locked)->pack();
			     
    my $l4 = $d->Label(-text=>"Database:", justify=>"right");
    my $ps_d = $d->Optionmenu(-options=> [@list],
			      -command=>sub {},
			      -textvariable=>\$defdb)->pack();
    
    my $l6 =  $d->Label(-text=>"Roles:", justify=>"left");
    my $l7 =  $d->Label(-text=>"System Administrator", justify=>"left");
    my @role=();
    my $ps_r = $d->Checkbutton(-onvalue=>"sa_role",
			       -offvalue=>'',
			       -cursor=>undef,
			       -variable=>\$role[0])->pack();
    my $l8 =  $d->Label(-text=>"System Security Officer", justify=>"left");
    my $ps_r1 = $d->Checkbutton(-onvalue=>"sso_role",
				-offvalue=>'',
				-cursor=>undef,
				-variable=>\$role[1])->pack();
    my $l9 =  $d->Label(-text=>"Operator", justify=>"left");
    my $ps_r2= $d->Checkbutton(-onvalue=>"oper_role",
			       -offvalue=>'',
			       -cursor=>undef,
			       -variable=>\$role[2])->pack();
    
 
    Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
    Tk::grid($ps_l,-row=>0,-column=>1,-sticky=>'ew');
    Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
    Tk::grid($ps_p,-row=>1,-column=>1,-sticky=>'ew');
    Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');
    Tk::grid($ps_s,-row=>2,-column=>1,-sticky=>'ew');
    Tk::grid($l4,-row=>3,-column=>0,-sticky=>'e');
    Tk::grid($ps_d,-row=>3,-column=>1,-sticky=>'ew');
    Tk::grid($l5,-row=>0,-column=>2,-sticky=>'e');
    Tk::grid($ps_lk,-row=>0,-column=>3,-sticky=>'ew');
    Tk::grid($l6,-row=>5,-column=>0,-sticky=>'e');
    Tk::grid($l7,-row=>6,-column=>1,-sticky=>'w');
    Tk::grid($ps_r,-row=>6,-column=>0,-sticky=>'ew');
    Tk::grid($l8,-row=>7,-column=>1,-sticky=>'w');
    Tk::grid($ps_r1,-row=>7,-column=>0,-sticky=>'ew');
    Tk::grid($l9,-row=>8,-column=>1,-sticky=>'w');
    Tk::grid($ps_r2,-row=>8,-column=>0,-sticky=>'ew');
        
    $d->gridRowconfigure(1,-weight=>1);
    my $button = $d->Show;

    my($cmd) = sprintf "sp_addlogin '%s', '%s'", $uname, $passwd;
    $cmd .= ",'$defdb'\n" if ($defdb ne '') ;

    if ($button eq 'Show SQL') { 
	$self->show_sql_dialog($main::lg{login_crt}, $cmd, $d);
	$self->create_login($uname, $passwd, $fname, $locked, $defdb, @role);
    } elsif ($button eq 'Create') {
	print $cmd;
	for (@role) {
	    $cmd = sprintf "sp_role 'grant','%s','%s'\n", $_, $uname;
	    print $cmd if ($_ ne '') ;
	}
	$cmd = sprintf "sp_locklogin '%s', 'lock'\n", $uname;
	print $cmd if ($locked ne '');
	$self->f_clr( $main::v_clr );
    }
}

sub create_remote_server {
    my $self = shift;
    my ($rname, $nname, @options) = @_;
    
    main::bz();

    my $d = $main::mw->DialogBox(-title => $main::lg{rem_srv_crt},
				 -buttons => ["Create", "Cancel", "Show SQL"]);
    my $l1 = $d->Label(-text=> "Remote Server Name:", justify=>"right");
    my $ps_r = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$rname,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l2 = $d->Label(-text=>"Network name:", justify=>"right");
    my $ps_n = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$nname,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l3 = $d->Label(-text=>"RPC Options:", justify=>"left");

    my $l4 = $d->Label(-text=>"ReadOnly", justify=>"left");
    my $ps_o = $d->Checkbutton(-variable=>\$options[0],
			       -cursor=>undef,
			       -offvalue=>'',
			       -onvalue=>'readonly')->pack(); 
    my $l5 = $d->Label(-text=>"Encrypt Password", justify=>"left");
    my $ps_o1 = $d->Checkbutton(-variable=>\$options[1],
			       -cursor=>undef,
			       -offvalue=>'',
			       -onvalue=>'net password encryption')->pack(); 
    my $l6 = $d->Label(-text=>"Drop connections with no activity", justify=>"left");
    my $ps_o2 = $d->Checkbutton(-variable=>\$options[2],
			       -cursor=>undef,
			       -offvalue=>'',
			       -onvalue=>'timeouts')->pack(); 
   
    Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
    Tk::grid($ps_r,-row=>0,-column=>1,-sticky=>'ew');
    Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
    Tk::grid($ps_n,-row=>1,-column=>1,-sticky=>'ew');
    Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');
    Tk::grid($l4,-row=>3,-column=>1,-sticky=>'w');
    Tk::grid($ps_o,-row=>3,-column=>0,-sticky=>'e');
    Tk::grid($l5,-row=>4,-column=>1,-sticky=>'w');
    Tk::grid($ps_o1,-row=>4,-column=>0,-sticky=>'e');
    Tk::grid($l6,-row=>5,-column=>1,-sticky=>'w');                                
    Tk::grid($ps_o2,-row=>5,-column=>0,-sticky=>'e');        

    $d->gridRowconfigure(1,-weight=>1);
    my $button = $d->Show;

    my($cmd) = sprintf "sp_addserver '%s', 'sql_server', '%s'\n", $rname, $nname;

    if ($button eq 'Show SQL') {
	$self->show_sql_dialog($main::lg{rem_srv_crt}, $cmd, $d);
	$self->create_remote_server ($rname, $nname, @options);
    } elsif ($button eq 'Create') {
	print $cmd;
	for (@options) {
	    $cmd = sprintf "sp_serveroption '%s', '%s', 'true'\n", $rname, $_;
	    if ($_ ne '') {
		my $sth = $self->{Database_conn}->prepare( $cmd ) || die $self->{Database_conn}->errstr; 
		$sth->execute;
	    }
	}
	$self->f_clr( $main::v_clr );
    }
}

sub create_database {
    my $self = shift;
    my ($dbname, $dbowner, $forload, @listData) = @_;
    
    main::bz();
    my ($row, $size, $type);
    my %devices = ();
    my @users = ();
    my @row = ();
    $type ='data' unless ($type ne '');

    my $cm = $self->f_str('get_free_dev' ,'1');
    my $sth = $self->{Database_conn}->prepare( $cm ) || die $self->{Database_conn}->errstr; 
    $sth->execute;
    
    while(@row = $sth->fetchrow){
	$size = $row[1] unless ($size > 0);
	$devices{$row[0]} = $row[1];
    }       
    $sth->finish;

    $cm = $self->f_str('get_users', '1');
    $sth = $self->{Database_conn}->prepare( $cm ) || die $self->{Database_conn}->errstr; 
    $sth->execute;
    
    while($row = $sth->fetchrow){
	push @users, $row;
    }       
    $sth->finish;

    my $d = $main::mw->DialogBox(-title => $main::lg{db_crt}, -buttons => ["Create", "Cancel", "Show SQL"]);
    my $l1 = $d->Label(-text=> "Database Name:", justify=>"right");
    my $ps_n = $d->add("Entry",-cursor=>undef,
		       -textvariable=>\$dbname,
		       -foreground=>$main::fc,
		       -background=>$main::ec)->pack();

    my $l2 = $d->Label(-text=>"Database Owner:", justify=>"right");
    my $ps_o = $d->Optionmenu(-options=> [@users],
			      -command=>sub {},
			      -textvariable=>\$dbowner)->pack();

    my $l3 = $d->Label(-text=>"For load", justify=>"left");
    my $ps_f = $d->Checkbutton(-variable=>\$forload,
			       -cursor=>undef,
			       -offvalue=>'',
			       -onvalue=>'for load')->pack(); 

    my $l4 = $d->Label(-text=>"Database Devices", justify=>"left");

    my $l5 = $d->Label(-text=>"Name", justify=>"left");
    my $l6 = $d->Label(-text=>"Max Size", justify=>"left");
    my $l7 = $d->Label(-text=>"Data", justify=>"left");  
    my $l8 = $d->Label(-text=>"Log", justify=>"left");
    
    my $dev;
    my $ps_d = $d->Optionmenu(-options=> [sort keys %devices],
			      -command=>sub {$size = $devices{$dev}},
			      -textvariable=>\$dev)->pack();
  
    my $ps_s = $d->add("Entry",-cursor=>undef,
		       -textvariable=>\$size,
		       -foreground=>$main::fc,
		       -background=>$main::ec,
		       -justify=>'right')->pack();

    my $ps_op = $d->Radiobutton(-variable=>\$type,
			       -cursor=>undef,
			       -value=>'data')->pack(); 

    my $ps_op1 = $d->Radiobutton(-variable=>\$type,
				-cursor=>undef,
				-value=>'log')->pack(); 
    my $ps_ls = $d->Listbox()->pack();

    my $ps_ba = $d->Button(-text=>'Add',
			   -command=> sub{$ps_ls->insert('end', $dev.' 'x(35 - length($dev)).$size.' 'x(16 - length($size)).$type)})->pack();
    my $ps_br = $d->Button(-text=>'Remove',
			   -command=> sub{$ps_ls->delete($ps_ls->curselection) if (defined($ps_ls->curselection))})->pack();

    for (@listData) {
	$ps_ls->insert("end", $_);
    }
   
    Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
    Tk::grid($ps_n,-row=>0,-column=>1,-sticky=>'ew');
    Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
    Tk::grid($ps_o,-row=>1,-column=>1,-sticky=>'ew');
    Tk::grid($l3,-row=>2,-column=>1,-sticky=>'w');
    Tk::grid($ps_f,-row=>2,-column=>0,-sticky=>'e');
    Tk::grid($l4,-row=>3,-column=>0,-rowspan=>2,-sticky=>'w');
    Tk::grid($l5,-row=>5,-column=>0,-sticky=>'w');                                
    Tk::grid($l6,-row=>5,-column=>1,-sticky=>'w');                                
    Tk::grid($l7,-row=>5,-column=>2,-sticky=>'w');                                
    Tk::grid($l8,-row=>5,-column=>3,-sticky=>'w');                                
    Tk::grid($ps_d,-row=>6,-column=>0,-sticky=>'ew');
    Tk::grid($ps_s,-row=>6,-column=>1,-sticky=>'w');                                
    Tk::grid($ps_op,-row=>6,-column=>2,-sticky=>'w');        
    Tk::grid($ps_op1,-row=>6,-column=>3,-sticky=>'w');        
    Tk::grid($ps_ba,-row=>6,-column=>4,-sticky=>'ew');        
    Tk::grid($ps_br,-row=>7,-column=>4,-sticky=>'nw');        
    Tk::grid($ps_ls,-row=>7,-column=>0,-columnspan=>4,-sticky=>'ew');        

    $d->gridRowconfigure(1,-weight=>1);
    my $button = $d->Show;
    my $i;
    my ($data, $log) = (' on', ' log on');
    for $i (0..$ps_ls->size - 1) {
	push @listData, $ps_ls->get($i);
	my ($devTmp, $sizeTmp, $typeTmp) = split(/\s+/, $ps_ls->get($i));
	$data .= " $devTmp = $sizeTmp," if ($typeTmp eq 'data');
	$log .= " $devTmp = $sizeTmp," if ($typeTmp eq 'log');
    }
    $data =~ s/,$//g; $log =~ s/,$//g; 
    $log = '' if ($log eq ' log on');

    my($cmd) = sprintf "create database %s %s %s %s\n", $dbname, $data, $log, $forload;

    if ($button eq 'Show SQL') {
	$self->show_sql_dialog($main::lg{db_crt}, $cmd, $d);
	$self->create_database ($dbname, $dbowner, $forload, @listData);
    } elsif ($button eq 'Create') {
	$sth = $self->{Database_conn}->prepare( $cmd ) || die $self->{Database_conn}->errstr; 
	$sth->execute;
	$self->f_clr( $main::v_clr );
    }
}

sub create_table {
    my $self = shift;
    my ($dbname, $tbname, $tbownerGl, $tbsegmentGl, @colDataGl) = @_;
    
    $self->f_clr( $main::v_clr );
    my ($row, $size, $type, $i);
    my ($colName,$dttype, $colLength,$tbsegment, $tbowner, $colPrec, $colScale, $colNull);
    my ($ps_tbowner, $ps_segment, $ps_dttype, $ps_length, $ps_scale, $ps_prec, $ps_nulls);
    my @row = ();
    my @colData = ();
    my @db = ();

    my $cm = $self->f_str('Tables' ,'1');
    my $sth = $self->{Database_conn}->prepare( $cm ) ||
	         die $self->{Database_conn}->errstr; 
    $sth->execute;
    
    while($row = $sth->fetchrow){
	push @db, $row
    }       
    $sth->finish;


    my $d = $main::mw->DialogBox(-title => $main::lg{tbl_crt}, -buttons => ["Create", "Cancel", "Show SQL"]);
    my $l1 = $d->Label(-text=> "Table Name:", justify=>"right");
    my $ps_tbname = $d->add("Entry",-cursor=>undef,
			    -textvariable=>\$tbname,
			    -foreground=>$main::fc,
			    -background=>$main::ec)->pack();

    my $l2 = $d->Label(-text=>"Database:", justify=>"right");

    $dbname= 'Select Database' unless ($dbname ne '');
    my $ps_dbname = $d->Optionmenu(-options=> [@db],
				   -command=>sub {  
				       # Will throw that into a separate function later
				       $self->{Database_conn}->do("use $dbname");
				       $cm = $self->f_str('Users', 2);
				       $sth = $self->{Database_conn}->prepare($cm) || 
					         die $self->{Database_conn}->errstr; 
				       $sth->execute;
				       $ps_tbowner->options([]);
				       while($row = $sth->fetchrow){
					   $ps_tbowner->addOptions([$row]) unless ($row eq 'dbo');
				       }       
				       $tbowner = 'Select User';
				       $sth->finish;

				       $ps_segment->options([]);
				       $cm = $self->f_str('Segments', 2);
				       $sth = $self->{Database_conn}->prepare( $cm ) || 
					         die $self->{Database_conn}->errstr; 
				       $sth->execute;
				       while($row = $sth->fetchrow){
					  $ps_segment->addOptions([$row]);
				       }       
				       $sth->finish;
				       $tbsegment =  'Select Segment' ;

				       $ps_dttype->options([]);
				       $cm = $self->f_str('Datatypes', 13);
				       $sth = $self->{Database_conn}->prepare( $cm ) || 
					         die $self->{Database_conn}->errstr; 
				       $sth->execute;
				       while($row = $sth->fetchrow){
					  $ps_dttype->addOptions([$row]);
				       }       
				       $dttype = 'Select Datatype';
				       $sth->finish;
				       $ps_length->configure(-background=>$main::sc,
							     -state=>'disabled');
				   },
				   -textvariable=>\$dbname)->pack();

    $tbowner = ($tbownerGl ne '') ? $tbownerGl : $tbowner;
    $tbsegment = ($tbsegmentGl ne '') ? $tbsegmentGl : $tbsegment;
    my $l3 = $d->Label(-text=>"Table Owner:", justify=>"right");
    $ps_tbowner = $d->Optionmenu(-options=> [],
				 -command=>sub {},
				 -textvariable=>\$tbowner)->pack();


    my $l4 = $d->Label(-text=>"Segment:", justify=>"right");
    $ps_segment = $d->Optionmenu(-options=> [],
				 -command=>sub {},
				 -textvariable=>\$tbsegment)->pack();

    my $l14 = $d->Label(-text=>"Columns", justify=>"left");

    my $l5 = $d->Label(-text=>"Name", justify=>"left");
    my $l6 = $d->Label(-text=>"Datatype", justify=>"left");
    my $l7 = $d->Label(-text=>"Length", justify=>"left");  
    my $l8 = $d->Label(-text=>"Precision", justify=>"left");
    my $l9 = $d->Label(-text=>"Scale", justify=>"left");
    my $l10 = $d->Label(-text=>"Nulls", justify=>"left");
    
    my $ps_colname = $d->add("Entry",-cursor=>undef,
			     -textvariable=>\$colName,
			     -foreground=>$main::fc,
			     -background=>$main::ec,
			     -justify=>'left')->pack();

    $ps_dttype = $d->Optionmenu(-options=> [],
				-command=>sub {
				    if ($dttype eq 'char' || $dttype eq 'binary' ||
					$dttype eq 'text' || $dttype eq 'varbinary' ||
					$dttype eq 'varchar') {
					$ps_length->configure(-background=>$main::ec,
							      -state=>'normal');
					$ps_prec->configure(-background=>$main::sc,
							    -state=>'disabled');
					$ps_scale->configure(-background=>$main::sc,
							     -state=>'disabled');
					$colPrec = $colScale = '';
				    } elsif ($dttype eq 'numeric' || $dttype eq 'decimal') {
					$colPrec = 18;
					$colScale = 0;
					$ps_prec->configure(-background=>$main::ec,
							    -state=>'normal');
					$ps_scale->configure(-background=>$main::ec,
							    -state=>'normal');
					$ps_length->configure(-background=>$main::sc,
							      -state=>'disabled');
				    } elsif ($dttype eq 'float') {
					$ps_length->configure(-background=>$main::sc,
							      -state=>'disabled');
					$ps_scale->configure(-background=>$main::sc,
							     -state=>'disabled');
					$ps_prec->configure(-background=>$main::ec,
							    -state=>'normal');
					$colPrec = 18;
					$colLength = '';
					$colScale = '';
				    } else {
					$ps_length->configure(-background=>$main::sc,
							      -state=>'disabled');
					$ps_prec->configure(-background=>$main::sc,
							    -state=>'disabled');
					$ps_scale->configure(-background=>$main::sc,
							     -state=>'disabled');
					$colLength = $colPrec = $colScale = '';
				    }
				},
				-textvariable=>\$dttype)->pack();
    
    $ps_length = $d->add("Entry",-cursor=>undef,
			 -textvariable=>\$colLength,
			 -foreground=>$main::fc,
			 -justify=>'left',
			 -state=>'disabled')->pack();
    $ps_prec = $d->add("Entry",-cursor=>undef,
		       -textvariable=>\$colPrec,
		       -foreground=>$main::fc,
		       -justify=>'left',
		       -state=>'disabled')->pack();
    $ps_scale = $d->add("Entry",-cursor=>undef,
			-textvariable=>\$colScale,
			-foreground=>$main::fc,
			-justify=>'left',
			-state=>'disabled')->pack();
    $ps_nulls = $d->Optionmenu(-options=> ["NULL", "NOT NULL", "IDENTITY"],
			       -command=> sub {},
			       -textvariable=>\$colNull)->pack();

    my $ps_ls = $d->Listbox()->pack();
    
    my $ps_ba = $d->Button(-text=>'Add',
			   -command=> sub{
			       $ps_ls->insert('end',
					      $colName.' 'x(22 - length($colName)).
					      $dttype.' 'x(26 - length($dttype)).
					      $colLength.' 'x(24 - length($colLength)).
					      $colPrec.' 'x(25 - length($colPrec)).
					      $colScale.' 'x(17 - length($colScale)).
					      $colNull);
			       $ps_length->configure(-background=>$main::sc,
						     -state=>'disabled');
			       $ps_prec->configure(-background=>$main::sc,
						   -state=>'disabled');
			       $ps_scale->configure(-background=>$main::sc,
						    -state=>'disabled');
			       $colLength = $colPrec = $colScale = $colName = '';
			       $dttype = 'Select Datatype';
			   })->pack();

    my $ps_br = $d->Button(-text=>'Remove',
			   -command=> sub{
			       $ps_ls->delete($ps_ls->curselection) if (defined($ps_ls->curselection));
			       $ps_length->configure(-background=>$main::sc,
						     -state=>'disabled');
			       $ps_prec->configure(-background=>$main::sc,
						   -state=>'disabled');
			       $ps_scale->configure(-background=>$main::sc,
						    -state=>'disabled');
			   })->pack();

    Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
    Tk::grid($ps_tbname,-row=>0,-column=>1,-sticky=>'ew');
    Tk::grid($l2,-row=>0,-column=>2,-sticky=>'e');
    Tk::grid($ps_dbname,-row=>0,-column=>3,-sticky=>'ew');
    Tk::grid($l3,-row=>1,-column=>0,-sticky=>'e');
    Tk::grid($ps_tbowner,-row=>1,-column=>1,-sticky=>'ew');
    Tk::grid($l4,-row=>1,-column=>2,-sticky=>'e');
    Tk::grid($ps_segment,-row=>1,-column=>3,-sticky=>'ew');
    Tk::grid($l14,-row=>3,-column=>0,-rowspan=>2, -sticky=>'w');
    Tk::grid($l5,-row=>5,-column=>0,-sticky=>'w');
    Tk::grid($l6,-row=>5,-column=>1,-sticky=>'w');
    Tk::grid($l7,-row=>5,-column=>2,-sticky=>'w');
    Tk::grid($l8,-row=>5,-column=>3,-sticky=>'w');
    Tk::grid($l9,-row=>5,-column=>4,-sticky=>'w');
    Tk::grid($l10,-row=>5,-column=>5,-sticky=>'w');
    Tk::grid($ps_colname,-row=>6,-column=>0,-sticky=>'ew');
    Tk::grid($ps_dttype,-row=>6,-column=>1,-sticky=>'ew');
    Tk::grid($ps_length,-row=>6,-column=>2,-sticky=>'w');
    Tk::grid($ps_prec,-row=>6,-column=>3,-sticky=>'ew');
    Tk::grid($ps_scale,-row=>6,-column=>4,-sticky=>'w');
    Tk::grid($ps_nulls,-row=>6,-column=>5,-sticky=>'ew');
    Tk::grid($ps_ba,-row=>6,-column=>6,-sticky=>'ew');
    Tk::grid($ps_br,-row=>7,-column=>6,-sticky=>'nw');
    Tk::grid($ps_ls,-row=>7,-column=>0,-columnspan=>6,-sticky=>'ew');

    $d->gridRowconfigure(1,-weight=>1);

    for (@colDataGl) {
	$ps_ls->insert("end", $_);
    }

    my $button = $d->Show;

    my($cmd) = sprintf "CREATE TABLE %s (", $tbname;
    @colDataGl = ();

    for $i (0..$ps_ls->size - 1) {
	push @colDataGl, $ps_ls->get($i);
	@colData = split(/\s\s+/, $ps_ls->get($i));


	$cmd .= "\n";
	# If int or some pre-defined length datatype
	if ($#colData == 2) {
	    $cmd .= join("\t", @colData);
	} elsif ($#colData == 4) { # Numeric or decimal
	    $cmd .= "$colData[0]\t$colData[1]($colData[2],$colData[3])\t$colData[4]";
	} elsif ($#colData == 3){ # whatever
	    $cmd .= "$colData[0]\t$colData[1]($colData[2])\t$colData[3]";
	}
	$cmd .=",";
    }
    
    $cmd =~ s/\,$//g;
    $cmd .= ")\n";
    $cmd .= "ON \"$tbsegment\"\n" if ($tbsegment ne '' && $tbsegment ne 'Select Segment');

    if ($button eq 'Show SQL') {
	$self->show_sql_dialog($main::lg{tbl_crt}, $cmd, $d);
	$self->create_table ($dbname, $tbname, $tbowner, $tbsegment, @colDataGl);
    } elsif ($button eq 'Create') {
	$self->{Database_conn}->do("use $dbname");
	$self->{Database_conn}->do($cmd);
	$self->{Database_conn}->do("grant all on $tbname to $tbowner") if ($tbowner  ne '' && $tbowner ne 'Select User');
	$self->f_clr( $main::v_clr );
    }
}

sub show_server_info {
    my $self = shift;
    main::bz();

    # Get Server name
    my $cm = "select \@\@servername";
    my $sth = $self->{Database_conn}->prepare($cm) || die $self->{Database_conn}->errstr; 
    $sth->execute;
    my $srvname = $sth->fetchrow();
    $sth->finish;

    # Get the rest of the information
    $cm = "select \@\@version";
    $sth = $self->{Database_conn}->prepare($cm) || die $self->{Database_conn}->errstr; 
    $sth->execute;
    my $tmpData = $sth->fetchrow();
    $sth->finish;

    my ($version, $version1, $rtype, $platform, $ostype, $buildopt, $buildopt1, $builddte) = split(/\//, $tmpData);
    $version .= " $version1";
    $buildopt .= " $buildopt1";
    $rtype = ($rtype eq 'P') ? 'Production' : 'Debug';

    # Get Default Language
    $cm = "select \@\@client_csname";
    $sth = $self->{Database_conn}->prepare($cm) || die $self->{Database_conn}->errstr; 
    $sth->execute;
    my $language = $sth->fetchrow();
    $sth->finish;

    # Get default charset
    $cm = "select \@\@language";
    $sth = $self->{Database_conn}->prepare($cm) || die $self->{Database_conn}->errstr; 
    $sth->execute;
    my $charset = $sth->fetchrow();
    $sth->finish;


    my $d = $main::mw->DialogBox(-title => $main::lg{srv_prop}, -buttons => ["Dismiss"]);
    my $l1 = $d->Label(-text=> "Server Name:", justify=>"right");
    my $ps_srv = $d->add("Entry",-cursor=>undef,
			 -textvariable=>\$srvname,
			 -state=>'disabled',
			 -foreground=>$main::fc,
			 -background=>$main::ec)->pack();
    
    my $l2 = $d->Label(-text=>"Version:", justify=>"right");
    my $ps_ver = $d->add("Entry",-cursor=>undef,
			 -textvariable=>\$version,
			 -state=>'disabled',
			 -foreground=>$main::fc,
			 -background=>$main::ec)->pack();

    my $l3 = $d->Label(-text=>"Release type:", justify=>"left");
    my $ps_rel = $d->add("Entry",-cursor=>undef,
			 -textvariable=>\$rtype,
			 -state=>'disabled',
			 -foreground=>$main::fc,
			 -background=>$main::ec)->pack();

    my $l4 = $d->Label(-text=>"Platform:", justify=>"right");
    my $ps_pl = $d->add("Entry",-cursor=>undef,
			-textvariable=>\$platform,
			-state=>'disabled',
			-foreground=>$main::fc,
			-background=>$main::ec)->pack();

    my $l5 = $d->Label(-text=>"Operating System:", justify=>"left");
    my $ps_os = $d->add("Entry",-cursor=>undef,
			-textvariable=>\$ostype,
			-state=>'disabled',
			-foreground=>$main::fc,
			-background=>$main::ec)->pack();

    my $l6 = $d->Label(-text=>"Build Option:", justify=>"right");
    my $ps_bo = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$buildopt,
		    -state=>'disabled',
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l7 = $d->Label(-text=>"Build Date:", justify=>"right");
    my $ps_bd = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$builddte,
		    -state=>'disabled',
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();


    my $l9 = $d->Label(-text=>"Character Set:", justify=>"right");
    my $ps_cs = $d->add("Entry",-cursor=>undef,
			-textvariable=>\$charset,
			-state=>'disabled',
			-foreground=>$main::fc,
			-background=>$main::ec)->pack();
    
    my $l10 = $d->Label(-text=>"Language:", justify=>"right");
    my $ps_lang = $d->add("Entry",-cursor=>undef,
			  -textvariable=>\$language,
			  -state=>'disabled',
			  -foreground=>$main::fc,
			  -background=>$main::ec)->pack();
    
    
    Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
    Tk::grid($ps_srv,-row=>0,-column=>1,-sticky=>'ew');
    Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
    Tk::grid($ps_ver,-row=>1,-column=>1,-sticky=>'ew');
    Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');
    Tk::grid($ps_rel,-row=>2,-column=>1,-sticky=>'e');
    Tk::grid($l4,-row=>3,-column=>0,-sticky=>'e');
    Tk::grid($ps_pl,-row=>3,-column=>1,-sticky=>'ew');
    Tk::grid($l5,-row=>4,-column=>0,-sticky=>'e');
    Tk::grid($ps_os,-row=>4,-column=>1,-sticky=>'ew');
    Tk::grid($l6,-row=>5,-column=>0,-sticky=>'e');                                
    Tk::grid($ps_bo,-row=>5,-column=>1,-sticky=>'ew');        
    Tk::grid($l7,-row=>6,-column=>0,-sticky=>'e');                                
    Tk::grid($ps_bd,-row=>6,-column=>1,-sticky=>'ew');        
    Tk::grid($l9,-row=>9,-column=>0,-sticky=>'e');                                
    Tk::grid($ps_cs,-row=>9,-column=>1,-sticky=>'ew');        
    Tk::grid($l10,-row=>10,-column=>0,-sticky=>'e');                                
    Tk::grid($ps_lang,-row=>10,-column=>1,-sticky=>'ew');        

    $d->gridRowconfigure(1,-weight=>1);
    my $button = $d->Show;
    $self->f_clr( $main::v_clr );
}

sub show_server_stat {
    my $self = shift;
    main::bz();

    # Get Server name
    my @data = ();
    my $cm = "exec sp_monitor";
    my $sth = $self->{Database_conn}->prepare($cm) || die $self->{Database_conn}->errstr; 
    $sth->execute;
    my @row = ();
    do {
	while(@row = $sth->fetchrow()) {
	    for (@row) {
		s/-.*//g;
		s/\(/\//g;
		s/\)//g;
		push @data, $_;
	    }
	}
    } while($sth->{syb_more_results});
    $sth->finish;

    my $d = $main::mw->DialogBox(-title => $main::lg{srv_prop},
				 -buttons => ["Dismiss"]);

    my $l1 = $d->Label(-text=> "Last Run:", justify=>"right");
    my $ps1 = $d->add("Entry",
		      -cursor=>undef,
		      -textvariable=>\$data[0],
		      -state=>'disabled',
		      -foreground=>$main::fc,
		      -background=>$main::ec)->pack();
    
    my $l2 = $d->Label(-text=>"Current Run:", justify=>"right");
    my $ps2 = $d->add("Entry",
		      -cursor=>undef,
		      -textvariable=>\$data[1],
		      -state=>'disabled',
		      -foreground=>$main::fc,
		      -background=>$main::ec)->pack();

    my $l3 = $d->Label(-text=>"Seconds Since Last Run:", justify=>"left");
    my $ps3 = $d->add("Entry",-cursor=>undef,
			 -textvariable=>\$data[2],
			 -state=>'disabled',
			 -foreground=>$main::fc,
			 -background=>$main::ec)->pack();

    my $l4 = $d->Label(-text=>"CPU busy (sec):", justify=>"right");
    my $ps4 = $d->add("Entry",-cursor=>undef,
			-textvariable=>\$data[3],
			-state=>'disabled',
			-foreground=>$main::fc,
			-background=>$main::ec)->pack();

    my $l5 = $d->Label(-text=>"IO Busy:", justify=>"left");
    my $ps5 = $d->add("Entry",-cursor=>undef,
			-textvariable=>\$data[4],
			-state=>'disabled',
			-foreground=>$main::fc,
			-background=>$main::ec)->pack();

    my $l6 = $d->Label(-text=>"Idle:", justify=>"right");
    my $ps6 = $d->add("Entry",-cursor=>undef,
		      -textvariable=>\$data[5],
		      -state=>'disabled',
		      -foreground=>$main::fc,
		      -background=>$main::ec)->pack();

    my $l7 = $d->Label(-text=>"Packets Received:", justify=>"right");
    my $ps7 = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$data[6],
		    -state=>'disabled',
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();


    my $l8 = $d->Label(-text=>"Packets Sent:", justify=>"right");
    my $ps8 = $d->add("Entry",-cursor=>undef,
			-textvariable=>\$data[7],
			-state=>'disabled',
			-foreground=>$main::fc,
			-background=>$main::ec)->pack();
    
    my $l9 = $d->Label(-text=>"Packet Errors:", justify=>"right");
    my $ps9 = $d->add("Entry",-cursor=>undef,
			  -textvariable=>\$data[8],
			  -state=>'disabled',
			  -foreground=>$main::fc,
			  -background=>$main::ec)->pack();

    my $l10 = $d->Label(-text=>"Total Read:", justify=>"right");
    my $ps10 = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$data[9],
		    -state=>'disabled',
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l11 = $d->Label(-text=>"Total Write:", justify=>"right");
    my $ps11= $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$data[10],
		    -state=>'disabled',
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();


    my $l12 = $d->Label(-text=>"Total Errors:", justify=>"right");
    my $ps12 = $d->add("Entry",-cursor=>undef,
			-textvariable=>\$data[11],
			-state=>'disabled',
			-foreground=>$main::fc,
			-background=>$main::ec)->pack();
    
    my $l13 = $d->Label(-text=>"Total Connections:", justify=>"right");
    my $ps13 = $d->add("Entry",-cursor=>undef,
			  -textvariable=>\$data[12],
			  -state=>'disabled',
			  -foreground=>$main::fc,
			  -background=>$main::ec)->pack();
    my $l0 = $d->Label(-text=> "* Value Since Reboot / Value Since Last Run", justify=>"right");    
    
    
    Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
    Tk::grid($ps1,-row=>0,-column=>1,-sticky=>'ew');
    Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
    Tk::grid($ps2,-row=>1,-column=>1,-sticky=>'ew');
    Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');
    Tk::grid($ps3,-row=>2,-column=>1,-sticky=>'e');
    Tk::grid($l4,-row=>3,-column=>0,-sticky=>'e');
    Tk::grid($ps4,-row=>3,-column=>1,-sticky=>'ew');
    Tk::grid($l5,-row=>4,-column=>0,-sticky=>'e');
    Tk::grid($ps5,-row=>4,-column=>1,-sticky=>'ew');
    Tk::grid($l6,-row=>5,-column=>0,-sticky=>'e');                                
    Tk::grid($ps6,-row=>5,-column=>1,-sticky=>'ew');        
    Tk::grid($l7,-row=>6,-column=>0,-sticky=>'e');                                
    Tk::grid($ps7,-row=>6,-column=>1,-sticky=>'ew');        
    Tk::grid($l8,-row=>7,-column=>0,-sticky=>'e');                                
    Tk::grid($ps8,-row=>7,-column=>1,-sticky=>'ew');        
    Tk::grid($l9,-row=>8,-column=>0,-sticky=>'e');                                
    Tk::grid($ps9,-row=>8,-column=>1,-sticky=>'ew');        
    Tk::grid($l10,-row=>9,-column=>0,-sticky=>'e');                                
    Tk::grid($ps10,-row=>9,-column=>1,-sticky=>'ew');        
    Tk::grid($l11,-row=>10,-column=>0,-sticky=>'e');                                
    Tk::grid($ps11,-row=>10,-column=>1,-sticky=>'ew');        
    Tk::grid($l12,-row=>11,-column=>0,-sticky=>'e');                                
    Tk::grid($ps12,-row=>11,-column=>1,-sticky=>'ew');        
    Tk::grid($l13,-row=>12,-column=>0,-sticky=>'e');                                
    Tk::grid($ps13,-row=>12,-column=>1,-sticky=>'ew');        
    Tk::grid($l0,-row=>15,-column=>0,-rowspan=>3, -columnspan=>2, -sticky=>'ew');                                

    $d->gridRowconfigure(1,-weight=>1);
    my $button = $d->Show;
    $self->f_clr( $main::v_clr );
}


sub show_sql_dialog {
    my $self = shift;
    my($title, $cmd, $parent) = @_;

    my $d = $parent->DialogBox(-title => "$title",
			       -buttons => ["Dismiss"]);
    my $l1 = $d->Label(-text=> $cmd, -justify=> "left")->pack();

    $d->Show();
}


# Replication Server Section (for fututre use)
sub create_subscription {
    my $self = shift;
    my ($dtype, $lname, $pname, $size) = @_;
    
    main::bz();

    my $d = $main::mw->DialogBox(-title => $main::lg{dev_dump_crt}, -buttons => ["Create", "Cancel", "Show SQL"]);
    my $l1 = $d->Label(-text=> "Subscription Database:", justify=>"right");
    my $ps_l = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$lname,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l2 = $d->Label(-text=>"Subscription name:", justify=>"right");
    my $ps_p = $d->add("Entry",-cursor=>undef,
		    -textvariable=>\$pname,
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l3 = $d->Label(-text=>"Definition Name:", justify=>"right");
    my $ps_s = $d->add("Entry",-cursor=>undef, 
		    -textvariable=>\$size, 
		    -foreground=>$main::fc,
		    -background=>$main::ec)->pack();

    my $l4 = $d->Label(-text=>"Materialization:", justify=>"right");
  
    my $ps_d = $d->Radiobutton(variable=>\$dtype,
		    text=>'bulk',
		    value=>'bulk')->pack(); 

    my $ps_d1 = $d->Radiobutton(variable=>\$dtype,
		    text=>'empty',
		    value=>'empty')->pack(); 

    Tk::grid($l1,-row=>0,-column=>0,-sticky=>'e');
    Tk::grid($ps_l,-row=>0,-column=>1,-sticky=>'ew');
    Tk::grid($l2,-row=>1,-column=>0,-sticky=>'e');
    Tk::grid($ps_p,-row=>1,-column=>1,-sticky=>'ew');
    Tk::grid($l3,-row=>2,-column=>0,-sticky=>'e');
    Tk::grid($ps_s,-row=>2,-column=>1,-sticky=>'ew');
    Tk::grid($l4,-row=>3,-column=>0,-sticky=>'e');
    Tk::grid($ps_d,-row=>3,-column=>1,-sticky=>'w');
    Tk::grid($ps_d1,-row=>4,-column=>1,-sticky=>'w');                                
        
    $d->gridRowconfigure(1,-weight=>1);
    my $button = $d->Show;

    my $cmd;
    if ($dtype eq 'bulk') {
	$cmd = sprintf "define subscription %s for %s with replicate at %s.%s\n", $pname, $size, $main::v_db, $lname;
	$cmd = sprintf "activate subscription %s for %s with replicate at %s.%s\n", $pname, $size, $main::v_db, $lname;
	$cmd = sprintf "validate subscription %s for %s with replicate at %s.%s\n", $pname, $size, $main::v_db, $lname;
    } else {
	$cmd = sprintf "create subscription %s for %s with replicate at %s.%s\n", $pname, $size, $main::v_db, $lname;
    }


    if ($button eq 'Show SQL') {
	$self->show_sql_dialog($main::lg{dev_dump_crt}, $cmd, $d);
	$self->create_subscription($dtype, $lname, $pname, $size);
    } elsif ($button eq 'Create') {
	print $cmd;
	$self->f_clr( $main::v_clr );
    }
}

sub univ_form { 
   my $self = shift;

   my $w; # For small button window generation

   # A complex function for generating on-the-fly Forms
   # for viewing database information

   ($loc_d,$own,$obj,$uf_type) = @_;

   my $m_t = "$main::lg{form_for} $obj";
   
   my $bd = $loc_d->DialogBox(-title=>$m_t,
                              -buttons=>[ $main::lg{exit} ]);
   my $uf_txt;

   if ($uf_type eq 'index'){
       $uf_txt = "$own.$obj, $main::lg{sel_cols}";
   } else {
       $uf_txt = "$main::lg{prov_sql} $main::lg{sel_info}";
   }
   $bd->Label(-text=>$uf_txt,-anchor=>'n')->pack();
   
   my $t = $bd->Scrolled('Text',
                         -height=>16,
                         -wrap=>'none',
                         -cursor=>undef,
                         -foreground=>$main::fc,
                         -background=>$main::bc
			 );
   
   my $cm = $self->f_str('selected_dba','1');
   $cm = sprintf($cm, $obj);
   my $sth = $self->{Database_conn}->prepare( $cm ) || 
               die $self->{Database_conn}->errstr;

   $sth->execute;

   my @h_t = ($main::lg{i_col},
	      $main::lg{i_sel_sql},
	      $main::lg{i_dat_typ},
	      $main::lg{i_ord});

   my $i;
   
   for $i (0..3){
       unless (($uf_type eq 'index') && ($i == 2)){
         if ($i == 3){
	     $w = $t->Entry(-textvariable=>\$h_t[$i],-cursor=>undef,-width=>3);
         } else {
	     $w = $t->Entry(-textvariable=>\$h_t[$i],-cursor=>undef);
         }
	 
         $w->configure(-background=>$main::fc,
                       -foreground=>$main::ec);
         $t->windowCreate('end',-window=>$w);
     }
   }
   $t->insert('end', "\n");
   
   my @c_t;
   my @t_t;
   $ind_bd_cnt = 0;
   my @res;
   
   while (@res = $sth->fetchrow) {
       $c_t[$ind_bd_cnt] = $res[0];
       $w = $t->Entry(-textvariable=>\$c_t[$ind_bd_cnt],
		      -cursor=>undef);
       $t->windowCreate('end',-window=>$w);
       
       unless ($uf_type eq 'index'){
	   
	   $sql_entry[$ind_bd_cnt] = "";
	   
	   $w = $t->Entry(-textvariable=>\$sql_entry[$ind_bd_cnt],
			  -cursor=>undef,
			  -foreground=>$main::fc,
			  -background=>$main::ec
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

   $t->configure( -state=>'disabled' );

   $t->pack( -expand =>1,
             -fill=>'both'
           );

   my $bb = $bd->Frame->pack( -side=>'bottom',
                              -before=> $t
                            );

   if ($uf_type eq 'index'){
      $uf_txt = 'Build Index';
   } else {
      $uf_txt = $main::lg{sel_info};
   }

   $bb->Button( -text=>$uf_txt,
                -command=>sub{ $bd->Busy;
                               $self->selector($bd,$uf_type);
                               $bd->Unbusy}
              )->pack (-side=>'right', 
                       -anchor=>'e');

   $bd->Show;
}

sub selector {

   my $self = shift;

   # User may wish to narrow search for info, down to 
   # a particular set of rows, and order these rows.
   # This function allows them to do that.

   my($sel_d,$uf_type) = @_;

   if ($uf_type eq 'index'){
      $self->build_ord($sel_d,$uf_type);
      return;
   }
   $l_sel_str = ' select ';

   my $i;
   for $i (0..$ind_bd_cnt){
      if ($i != $ind_bd_cnt){
         $l_sel_str = $l_sel_str . "$i_ac[$i], ";
      } else {
         $l_sel_str = $l_sel_str . "$i_ac[$i] ";
      }
   }

   $l_sel_str = $l_sel_str . "\nfrom ${own}..${obj} ";

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
   $self->build_ord($sel_d,$uf_type);
   $self->and_finally($sel_d,$l_sel_str);
}

sub and_finally {
   my $self = shift;

   my($af_d,$cm) = @_;

   # Now we've built up our full SQL statement for this table,
   # fill a Perl array with everything and display it.
   $ary_ref = $self->{Database_conn}->selectall_arrayref($cm);

   $min_row = 0;
   $max_row = @$ary_ref;
   if ($max_row == 0){
      main::mes($af_d, $main::lg{no_rows});
   } else {
      $gc = $min_row;

      my $c_d = $af_d->DialogBox(-title=>$m_t);

      my(@lb) = qw/-anchor n -side top -expand 1 -fill both/;
      my $top_frame = $c_d->Frame->pack(@lb);
   
      my $t = $top_frame->Scrolled('Text',
                                   -height=>16,
                                   -wrap=>'none',
                                   -cursor=>undef,
                                   -foreground=>$main::fc,
                                   -background=>$main::bc);

      for my $i (0..$ind_bd_cnt) {
         $lrg_t[$i] = "";
         $w = $t->Entry(-textvariable=>\$i_ac[$i],
                        -cursor=>undef);
         $t->windowCreate('end',-window=>$w);
   
         $w = $t->Entry(-textvariable=>\$lrg_t[$i],
                        -cursor=>undef,
                        -foreground=>$main::fc,
                        -background=>$main::ec,
                        -width=>40);

         $t->windowCreate('end',-window=>$w);
         $t->insert('end', "\n");
      }
      $t->configure(-state=>'disabled');
      $t->pack(@lb);

      my $c_br = $c_d->Frame->pack(-before=>$top_frame,
                                   -side=>'bottom',
                                   -expand=>'no');
   
      $gen_sc = 
         $c_br->Scale( 
             -orient=>'horizontal',
             -label=>"$main::lg{rec_of} " . $max_row,
             -length=>400,
             -sliderrelief=>'raised',
             -from=>1,-to=>$max_row,
             -tickinterval=>($max_row/8),

             -command=>[ 
                sub {   $self->calc_scale_record($gen_sc->get())
                    }  ]

                     )->pack(side=>'left');

      $c_br->Button(-text=>$main::ssq,
                    -command=>sub{$self->see_sql($c_d,$l_sel_str)}

                   )->pack(side=>'right');

      $self->go_for_gold();
      $c_d->Show;
   }
   undef $ary_ref;
}
sub calc_scale_record {
   my $self = shift;

   # Whizz backwards and forwards through the records

   my($sv) = @_;
   $gc = $sv - 1;

   $self->go_for_gold();
}
sub go_for_gold {
   my $self = shift;

   # Work out which row of information to display,
   # and then display it.

   my $curr_ref = $ary_ref->[$gc];
   for my $i (0..$ind_bd_cnt) {
      $lrg_t[$i] = $curr_ref->[$i];
   }
   $gen_sc->set(($gc + 1));
}
sub build_ord {

   my $self = shift;

   # It all gets a bit nasty here.  This works out
   # the user's intentions on how to order their
   # required information.

   my($bl_d,$uf_type) = @_;
   my $l_chk = 0;

   my $i;

   for $i (0..$ind_bd_cnt){
      if ($i_uc[$i] == 1){
         $l_chk = 1;
      }
   }

   if ($l_chk == 1){

      $self->now_build_ord($bl_d,$uf_type);

      if ($uf_type ne 'index'){
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
  }
}
sub now_build_ord {
   my $self = shift;

   # This helps build up the ordering SQL string.

   my($nbo_d,$uf_type) = @_;
   $tot_i_cnt = 0;

   my $i;

   for $i (0..$ind_bd_cnt){
      if ($i_uc[$i] == 1){
         $tot_i_cnt++;
         $tot_ind_ar[$tot_i_cnt] = $i_ac[$i];
      }
   }
   my $b_d = $nbo_d->DialogBox(-title=>$m_t); 

   $b_d->Label(  -text=>$main::lg{ind_ord_arrng},
                 -anchor=>'n'
              )->pack(-side=>'top');

   my $t = $b_d->Scrolled('Text',
                          -height=>16,
                          -wrap=>'none',
                          -cursor=>undef,
                          -foreground=>$main::fc,
                          -background=>$main::bc);

   my @pos_txt;
   for $i (1..($tot_i_cnt + 2)){
      if ($i <= $tot_i_cnt){
         $pos_txt[$i] = "Pos $i";
         $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                        -width=>7,
                        -background=>$main::fc,
                        -foreground=>$main::ec);
      } else {
         if ($i == ($tot_i_cnt + 1)){
            $pos_txt[$i] = $main::lg{i_col};
            $w = $t->Entry(-textvariable=>\$pos_txt[$i],
                           -background=>$main::fc,
                           -foreground=>$main::ec);
         } else {
	     $pos_txt[$i] = $main::lg{i_desc};
	     $w = $t->Entry(-textvariable=>\$pos_txt[$i],
			    -width=>8,
			    -background=>$main::fc,
			    -foreground=>$main::ec);
         }
     }
      $t->windowCreate('end',-window=>$w);
  }
   $t->insert('end', "\n");

   # The following is all a bit horrible.  I'm afraid 
   # you're going to have to work it out for yourself.
   # It's not nice, you may not want to bother.

   my $j_row;

   for $j_row (1..$tot_i_cnt){

      $ih[$j_row] = $j_row;
      $dsc_n[$j_row] = 0;
      $o_ih[$j_row] = $ih[$j_row];

      my $j_col;

      for $j_col (1..($tot_i_cnt + 2)){
         if ($j_col <= $tot_i_cnt){

            $w = $t->Radiobutton(
                        -relief=>'flat',
                        -value=>$j_row,
                        -variable=>\$ih[$j_col],
                        -width=>4,
                        -command=>[ sub {  $self->j_inri()  }]);

            $t->windowCreate('end',-window=>$w);
         } else {
            if ($j_col == ($tot_i_cnt + 1)){

               $w = $t->Entry( -textvariable=>\$tot_ind_ar[$j_row],
                               -cursor=>undef,
                               -foreground=>$main::fc,
                               -background=>$main::ec
                             );

               $t->windowCreate('end',-window=>$w);
	   } else {
                  $w = $t->Checkbutton( -variable=>\$dsc_n[$j_row],
                                        -relief=>'flat',
                                        -width=>6);

                  $t->windowCreate('end',-window=>$w);
	   }
         }
      }
      $t->insert('end', "\n");
   }
   $t->configure(-state=>'disabled');
   $t->pack();
   $b_d->Show;
}

sub j_inri {
   my $self = shift;

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

sub get_lines
{
   my $self = shift;

   my ($sql_name, $sql_num, $param1, @bindees) = @_;
   my @names = ();
   my $sth;
   my $tar;

   # Bind does not work properly, let's play around
   if ($sql_num == 99 && ($sql_name eq 'Segments' || $sql_name eq 'All Objects')) {
       $param1 = sprintf ($param1, @bindees);
       @bindees = ();
   }

   ($tar, @names) = $self->do_query_fetch_all($param1, \$sth , @bindees);
   my @tlen;

   $self->post_process_sql($sql_name, $sql_num, $tar);
   # as this is new, how do I know if the user's version has 
   # this before I use it?
  
   my @types;
   @types = @{$sth->{TYPE}} if (exists($sth->{TYPE}));

   my ($j, $i, $len, $just);
   my (@format, $header);

   for ($i = 0;$i < $#names+1;$i++){
        # default justify to the left and hope for the best!
      $just = '-';

      # as this is new, how do I know if the user's version 
      # has this before I use it?

      if (exists($sth->{TYPE}) && defined(DBI::SQL_INTEGER))
      {
         # find the type to set the justification; get these from DBI.pm
         SWITCH: {
            $_ = $types[$i];
#            ($_ == DBI::SQL_CHAR) && do { $just = '-'; last SWITCH; };
#            ($_ == DBI::SQL_VARCHAR) && do { $just = '-'; last SWITCH; };
#            ($_ == DBI::SQL_DATE) && do { $just = '-'; last SWITCH; };
#            ($_ == DBI::SQL_TIME) && do { $just = '-'; last SWITCH; };
#            ($_ == DBI::SQL_TIMESTAMP) && do { $just = '-'; last SWITCH; };
#            ($_ == DBI::SQL_LONGVARCHAR) && do { $just = '-'; last SWITCH; };
#            ($_ == DBI::SQL_BINARY) && do { $just = '-'; last SWITCH; };
#            ($_ == DBI::SQL_VARBINARY) && do { $just = '-'; last SWITCH; };
#            ($_ == DBI::SQL_LONGVARBINARY) && do { $just = '-'; last SWITCH; };
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
      for ($j=0 ; $j < @{$tar}  ; $j++)
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
   my $self = shift;

   my ($header, $tar, $r_tlen, $r_format) = @_;
   my ($i, $j, @row);
   my @lines = @{$tar};
   my @format = @{$r_format};
   my @tlen = @{$r_tlen};
   my $ubar = '---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------';

   
   # print the column header
   $self->{Text_var}->insert('end', "\n$header\n");

   # print the underbars to show column width
   for ($i=0 ; $i <= $#tlen ; $i++)
   {
      $self->{Text_var}->insert('end', substr($ubar, 0, $tlen[$i]) . ' ');
   }
   $self->{Text_var}->insert('end', "\n");

   # print the data!
   for ($j=0 ; $j <= $#lines ; $j++)
   {
      @row = @{$lines[$j]};
      next if (@row == 1 && $row[0] == 0);
      for ($i=0 ; $i <= $#tlen; $i++)
      {
	  $row[$i] = "" if (!defined($row[$i]));
	  $self->{Text_var}->insert('end', sprintf($format[$i], $row[$i]));
      }
      $self->{Text_var}->insert('end', "\n");
   }
}

# do a query, and fetch all rows into an array of arrays
# be careful, this could consume a LOT of memory if called with a bad statement!

sub do_query_fetch_all
{
   my $self = shift;

   my($stmt, $asth, @bindees) = @_;
   my $tbl_ary_ref = undef;
   my ($sth, $i, $j);
   my (@row, @temp);
   # to do them all:

   $sth = $self->do_query($stmt, @bindees);

   for ($i = 0;$i < $sth->{NUM_OF_FIELDS};$i++){
       push @temp, $sth->{NAME}->[$i];
   }

   $i = 0;
   do {
       while(@row = $sth->fetchrow){
	   for (@row) {
	       $tbl_ary_ref->[$i]->[$j++] = $_;
	   }       
	   $j = 0;
	   $i++;
       }
   } while($sth->{syb_more_results});

   $self->db_check_error($stmt, "Fetch");
   $$asth = $sth if (defined($asth));
   $sth->finish();

   return ($tbl_ary_ref, @temp);
}
1;

