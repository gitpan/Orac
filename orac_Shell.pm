package orac_Shell;

sub dbish {
   package main;

   if(!defined($swc{dbish})){
      $swc{dbish} = $global_sub_win_count;
      $global_sub_win_count++;
   }

   $sw[$swc{dbish}] = MainWindow->new();
   $sw[$swc{dbish}]->title($lg{dbish});

   my(@exp_lay) = qw/-side top -padx 5 -expand no -fill both/;
   my $dmb = $sw[$swc{dbish}]->Frame->pack(@exp_lay);
   my $orac_li = $sw[$swc{dbish}]->Pixmap(-file=>'img/orac.bmp');
   $dmb->Label(-image=>$orac_li,-borderwidth=>2,-relief=>'flat')->pack(-side=>'left',-anchor=>'w');

   # Add buttons.  

   $dmb->Button(-text=>$lg{execute_sql},-command=>sub{ orac_Shell::execute_sql() }
               )->pack(side=>'left');

   $dmb->Button(-text=>$lg{clear},-command=>sub{
                      $sw[$swc{dbish}]->Busy;
                      $dbish_txt->delete('1.0','end');
                      $sw[$swc{dbish}]->Unbusy;
                                               }
               )->pack(side=>'left');

   $dmb->Button(-text=>$lg{exit},-command=> sub{
                      $sw[$swc{dbish}]->withdraw();
                      $sw_flg[$swc{dbish}]->configure(-state=>'active');
                      undef $sql_browse_arr} 
               )->pack(-side=>'left');


   (@exp_lay) = qw/-side top -padx 5 -expand yes -fill both/;
   my $top_slice = $sw[$swc{dbish}]->Frame->pack(@exp_lay);

   my $dbish_txt_width = 50;
   my $dbish_txt_height = 12;
   $sw_hand[$swc{dbish}] = $top_slice->Scrolled('Text',-wrap=>'none',-cursor=>undef,
                                                       -height=>($dbish_txt_height + 8),-width=>($dbish_txt_width + 12),
                                                       -foreground=>$fc,-background=>$bc);

   $dbish_txt = $sw_hand[$swc{dbish}]->Scrolled('Text',-wrap=>'none',-cursor=>undef,
                                                     -height=>$dbish_txt_height,-width=>$dbish_txt_width,
                                                     -foreground=>$fc,-background=>$ec);
   tie (*DBISH_TXT, 'Tk::Text', $dbish_txt);

   # A little help:

   $sw_hand[$swc{dbish}]->insert( 'end', main::gf_str('txt/onthefly_sql.txt') );

   $sw_hand[$swc{dbish}]->windowCreate('end',-window=>$dbish_txt);
   $sw_hand[$swc{dbish}]->insert('end', "\n");
   $sw_hand[$swc{dbish}]->pack(-expand=>1,-fil=>'both');

   # Now disable calling button, and iconize window

   $sw_flg[$swc{dbish}]->configure(-state=>'disabled');
   main::iconize($sw[$swc{dbish}]);
   return;
}
sub execute_sql {
   package main;

   # Takes the SQL statement directly from the screen
   # and then pumps out report
   # Using KevinB's stuff, go!

   main::f_clr();
   orac_Base::show_sql ( $dbish_txt->get("1.0", "end") );
}
1;
