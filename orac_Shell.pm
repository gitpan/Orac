# vim:ts=2:sw=2
################################################################################
#
# Orac DBI Visual Shell.
# Versions 1.0.3a
#
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
#


package orac_Shell;
@ISA = qw{Shell::Do Shell::Format orac_Shell::mark};

use Exporter;

use Tk;
use Tk::Table;
use Tk::Pretty;
use Shell::Do;
use Shell::Format;
use Data::Dumper;

use strict;

my $VERSION;
$VERSION = $VERSION = qq{1.0.4a};

my ($sql_txt, $sql_entry_txt);
my ($rslt_txt, $rslt_entry_txt);
my ($ind_txt, $mv_ind_rslt);
my (@ind_txt, @mv_ind_rslt, $ind_tbl);
my (@sql_txt, @sql_entry_txt);

my ($opt_row_dis_c, $opt_dis_grid);
my ($entry_txt, $entry_tbl, $entry_frm);
my (@entry_txt);
my %color_ball;

my ($dbiwd, $dbistatus, $auto_ball, $chng_ball, $button_exe);
my ($idxMark, $begLn);

sub new
{
   print STDERR "orac_Shell::new\n" if ( $main::debug > 0 );

   my $proto = shift; my $class = ref($proto) || $proto;
   my $marks = new orac_Shell::mark;
   my $self  = {
       current => undef,
      rv         => undef,
      status  => \$dbistatus,
      display_rows => 1,
      marks => $marks,
    };

   bless($self, $class);

   print Dumper($self)
      if ( $main::debug > 0 );

   # save off args...
   # or other encapsulated values, these do NOT inherit!

   $self->{mw} = $_[0];
   $self->{dbh} = $_[1];

   print STDERR "orac_Shell,   new mw  >$self->{mw}<\n" 
      if ( $main::debug > 0 );

   print STDERR "orac_Shell,   new dbh >$self->{dbh}<\n" 
     if ( $main::debug > 0 );

   $color_ball{green} = $self->{mw}->Photo( -file => "$FindBin::RealBin/img/grn_ball.gif" );
   $color_ball{red}   = $self->{mw}->Photo( -file => "$FindBin::RealBin/img/red_ball.gif" );
   $color_ball{yellow}= $self->{mw}->Photo( -file => "$FindBin::RealBin/img/yel_ball.gif" );
   $color_ball{checkmark}= $self->{mw}->Photo( -file => "$FindBin::RealBin/img/smChekmark.gif");

   return $self;
}

# Create the top level for Orac DBI Shell.



sub dbish_open {
   my $self = shift;
   my $mw = $self->{mw};

   #
   # Determine if the dbish window is defined.  If it isn't, define the
   # window.
   #

   if (defined($self->{dbiwd})) {

      print "deiconifying\n";

      $dbiwd->deiconify();
      $dbiwd->raise();

   } else { 
      
      # Create a Toplevel window under the curren main.

      $dbiwd = $self->{mw}->Toplevel();

      $dbiwd->title( "Orac DBI Shell SQL" );

      $main::swc{dbish} = $dbiwd;

      # Create status label

      my $sf = $dbiwd->Frame( -relief => 'groove',
                              -bd => 2 

                            )->pack( -side => 'bottom', -fill => 'x' );

      # This is the status bar.

      $auto_ball = $sf->Label(-image=> $color_ball{green}, 
                              -borderwidth=> 2,
                              -relief=> 'flat'

                             )->pack(  -side=> 'right', -anchor=>'w');

      $self->bind_message( $auto_ball, "Auto commit" );

      $chng_ball = $sf->Label(-image=> $color_ball{red}, 
                              -borderwidth=> 2,
                              -relief=> 'flat'

                             )->pack(  -side=> 'right', -anchor=>'w');

      $self->bind_message( $chng_ball, "Any changed since last save" );

      $sf->Label( -textvariable => \$dbistatus )->pack(-side => 'left');

      my @menus;

      # Create the menu bar with entries.
      $self->menu_bar(\@menus);

      # Create the menu button with entries.
      $self->menu_button();

      # Create Text widget for results display.
      $dbistatus = "Creating Text results widget";

      $rslt_txt = $dbiwd->Scrolled( "Text", 
                                    -relief => 'groove',
                                    -width => 78, 
                                    -height => 20,
                                    -cursor=>undef,
                                    -foreground=>$main::fc,
                                    -background=>$main::bc,
                                    -wrap => "none",
                                    -takefocus => 0,
                                    -setgrid => 1,

                                  )->pack( -side => 'top',
										   -expand => 1,
										   -fill => "both");

      $dbiwd->Label(-text => ' ',
                    -relief => 'groove' 

                   )->pack( -side => 'top', -fill => 'x' );

      $entry_frm = $dbiwd->Frame( -relief => 'groove',
                                )->pack( -side => 'top',
										 -expand => 1,
										 -fill => "both");


      # Create Text widget for command entry
      $dbistatus = "Creating Text entry widget";

      $self->new_entry( $_ );


      $main::swc{dbish}->{text} = $rslt_txt;

      # Tie the windows to the file types:
      tie (*ENTRY_TXT, 'Tk::Text', $entry_txt);
      tie (*RSLT_TXT,  'Tk::Text', $rslt_txt);

      $self->{dbishwindow} = \$dbiwd;

      # Finallly, iconize window

      main::iconize($dbiwd);
   }

   # If the auto commit is on, set the ball to green, else red.
   # This is adjusted each time the window is entered. 

   if($self->{dbh}->{AutoCommit}) {
      $auto_ball->configure( -image => $color_ball{green} );
   } else {
      $auto_ball->configure( -image => $color_ball{red} );
   }

   # Make the Main Window and icon.
        # Disable button, calling orac_Shell

   $self->{mw}->iconify();
        $main::sub_win_but_hand{dbish}->configure(-state=>'disabled');

   $dbistatus = "Window for Tk created.";

   # Last thing is focus on the entry box.
   $entry_txt->focusForce();
   $rslt_txt->configure( -state => 'disabled' );

   #$entry_tbl->packPropagate(0);
}

my ($curx);
sub where_am_i {
   my ($self, $x, $y, $txt ) = @_;
   $curx = $x;
   $entry_txt->focus();

   print STDERR "Move to : $x\n"
      if ( $main::debug > 0 );

   print Dumper($entry_tbl->packSlaves())
      if ( $main::debug > 0 );

   print $entry_tbl->name()
      if ( $main::debug > 0 );
};

sub new_entry {
   my ($self, $x) = @_;


   my $s = $entry_frm->Scrolled( 'Text', -scrollbars => 'wo')->pack();

   my $ysb = $s->Subwidget( "yscrollbar" );

   $ind_tbl = $s->Table( -columns => 1, 
      -rows => 10,
      -scrollbars => '',
   );

   my @bt;
   for (my  $x = 1; $x <= 6; $x++ ) {
     $bt[$x] = $ind_tbl->Button( # -text => '',
         -image => $color_ball{checkmark},
         -background=>$main::ec,
         -justify => 'center',
         -height => 8,
         -width => 8,
         -highlightthickness => 1,
         -relief => 'raised',
      );
      $ind_tbl->put( $x,1, $bt[$x] );

      print STDERR "\tbutton $x\n"
         if ( $main::debug > 0 );
   }

   $ind_txt = $s->Text( -width => 3, -state => 'normal',); 
   my ($this,$last);
   $this = $last = 0;
   my $ss = sub {
      $s->Subwidget( "yscrollbar" )->set(@_);
      $this = $s->Subwidget( "yscrollbar" )->get();
      if ($this < $last) {
         $ind_txt->yview("scroll", -1, "units" );
      } else {
         $ind_txt->yview("scroll", 1, "units" );
      }

      print STDERR "This $this Last $last\n"
         if ( $main::debug > 0 );

      $last = $this;

      print STDERR "entry index current: " , 
                   $entry_txt->index( 'current' ), "\n"
         if ( $main::debug > 0 );
   };


   $entry_txt = $s->Text( # 'Text',
      -relief => 'groove',
      -width => 74,
      # -height => 3,
      -cursor=>undef,
      -foreground=>$main::fc,
      -background=>$main::ec,
      -yscrollcommand => $ss,
   );


my $sc = sub {
      $entry_txt->yview(@_);
      $ind_txt->yview(@_);
};

$ysb->configure( -command => $sc );

#for ( my $x = 1; $x < 150; $x++ ) { $ind_txt->insert( "end", "$x\n" ) };

$ind_txt->configure( -state => 'disabled', );

$ind_tbl->pack( 
   -side => 'left',
   -anchor => 'n',
   #-ipadx => 2,
   -ipady => 2,
   -pady => 2,
);
$ind_txt->pack( -side => 'left' );
$entry_txt->pack( -side => 'left' );


   print Pretty $entry_txt->configure, "\n"
      if ( $main::debug > 0 );

   my $fnt = $entry_txt->cget( -font );

   print $entry_txt->fontActual( $fnt, -size ), "\n"
      if ( $main::debug > 0 );


   # Pick up the Return key ... see return_press.
   $entry_txt->bind( "<Return>", sub { $self->return_press() } );
   $entry_txt->tagConfigure( "Exec",  -foreground => "green" );

   $entry_txt->insert( "1.0", " ");

   print Dumper( $entry_txt->bbox( "1.0" ))
      if ( $main::debug > 0 );

   $entry_txt->delete( "1.0", "end" );

}

#  Allows the user to change auto commit.
sub auto_commit {
}

#
# Because I really dislike have to move the mouse up to the execute
# button, if the only character on a line is /, execute the above
# statement.
#
my $exeStatement;
sub return_press {
   my $self = shift;

   #$ind_txt->configure( -state => 'normal' );
   #$ind_txt->insert( 'end', "\n" );
   #$ind_txt->configure( -state => 'disabled' );

   # Determine where the cursor is.
   my $ind = $entry_txt->index( 'insert - 1 lines' );

   # Grab the last line of text.
   my $txt = $entry_txt->get( $ind, 'insert' );
   chomp $txt;


   # The previously entered line is only a /, exeucte.
   if ($txt =~ m:[/;]$:) {

      print STDERR "An execute command ...\n"
         if ( $main::debug > 0 );

      # get current buffer finds the sql statement.
      $self->{statement_number} = $self->get_current_buffer( $ind );
      # now execute it;
      $button_exe->invoke();


   $self->set_results_btn( $self->{statement_number}, $begLn);

      # So, the statement is executed, results display, if any, now
      # the house keeping.

      #my $s = $entry_txt->get( "1.0", "end" );

      # Delete all blank lines between the last statement and [/;]

      #$s =~ s:[\s\t\n]+/::;
      #$entry_txt->delete( "1.0", "end" );

      #$entry_txt->insert( "end", $s );

      # determine the actual height of the box that is needed.

      # size height of text box.
      
      # Move to the next row in the table.
   } #else {
   #}

}
sub check_ind_txt {
   my ($self, $pl) = @_;

   print $ind_txt->index('end'), "\n"
      if ( $main::debug > 0 );

   if ($ind_txt->compare( 'end', "<=", "$pl.0" ) ) {
      $ind_txt->insert( 'end', "\n" );
   }
}

# 
# Determine where the markers go
#

my %rmarkers;
sub set_results_btn {
   my ($self, $c, $inx ) = @_;

   my $pl = int( $entry_txt->index( $self->{marks}->get_mark_beg($c)) + .99 );

   print STDERR "Index $inx Statement $pl \n"
      if ( $main::debug > 0 );

   $self->check_ind_txt($pl);

   # Add just a line place for statement marker.
   # Using closure witht the button, instead of a subroutine.
   # see Advanced Perl Programming p60.
   my $mv_to_res = sub { 
      $self->move_to_results( $c )
   };

   print STDERR "Placing mark at $pl\n"
      if ( $main::debug > 0 );

  $rmarkers{ $pl } = $mv_ind_rslt = $ind_txt->Button( # -text => '',
         -command =>  $mv_to_res,
         -image => $color_ball{checkmark},
         -background=>$main::ec,
         -justify => 'center',
         -height => 5,
         -width => 6,
   );

   #
   # Create the new  window.
   #

   $ind_txt->configure( -state => 'normal' );

   my $eend = int($entry_txt->index( 'end' ));

   # Check the rows in the current table.
   if ($eend > $ind_tbl->totalRows) {

      print STDERR "Add more rows to the table.\n"
         if ( $main::debug > 0 );

      $ind_tbl->configure( -rows => $eend );
   }

   $ind_txt->delete( "1.0", 'end' );
   for (my $x = 1; $x <= $eend; $x++ ) {

      $ind_txt->insert( "$pl.0", "\n" );

      if (exists $rmarkers{ $x }) {
         #$ind_tbl->put( $x, 1, $rmarkers{ $x });
         #$ind_tbl->put( $x, 1, "." );
         $ind_txt->windowCreate( "$pl.0", 
            -align => 'center',
            -stretch => 1,
            -window => $rmarkers{ $x },
         );
      }  else {
      #         $ind_tbl->put( $x, 1, "." );
      }
   }

   $ind_txt->configure( -state => 'disabled' );
}

#
# Get the current buffer text.
#


sub get_current_buffer() {

   my $self = shift;
   $idxMark = $entry_txt->index( 'insert' );
   my $stinx;

   print STDERR "Search entry start: $idxMark "
      if ( $main::debug > 0 );

   my $inx = $entry_txt->search( 
      -backwards, 
      -regexp, 
      '[;/]$',  #',
      $stinx = $entry_txt->index( 'insert - 1 lines'),
      "1.0",
   );
   # The buffer could have more than one statement in it.
   # Find the last statement. Look for the new statement on
   # the next line.
   $begLn = "1.0";
   if (defined $inx and length($inx) > 0) {
      # Convert the index to something more usable.
      $begLn = $entry_txt->index("$inx + 1 chars"); 

      print STDERR " found at: $inx "
         if ( $main::debug > 0 );
   } 
   $exeStatement = $entry_txt->get( $begLn, $idxMark );
   $entry_txt->tagAdd( 'Exec', $begLn, $idxMark );

   print STDERR " getting text from $begLn to $idxMark: $exeStatement\n"
      if ( $main::debug > 0 );

   #
   # The statement determined, now set the begin and end marks.
   #

   my $marks = $self->{marks};
   my $c = $marks->is_marked($begLn);

   print Dumper($marks)
      if ( $main::debug > 0 );

   if (not defined($c)) {

      print STDERR "C is not defined, creating new mark\n"
         if ( $main::debug > 0 );

      $c = $marks->mark( $begLn, $idxMark );

      print STDERR "Mark created, index $c\n"
         if ( $main::debug > 0 );

      $entry_txt->markSet( $marks->get_mark_beg($c),
         $marks->get_beg($c) );
      $entry_txt->markGravity( $marks->get_mark_beg($c), "left" );

   } else {
      # Statement is marked already, update the index information.
      $marks->set_mark_beg($c,$begLn);
      $marks->set_mark_end($c,$idxMark);
   }

   print STDERR join( "\n", $entry_txt->markNames(), "" )
      if ( $main::debug > 0 );

   #foreach ($entry_txt->markNames()) {
      #print STDERR "MARK: $_ at ", $entry_txt->index($_), "\n";
   #}
   $c;
}


sub bind_message {
   my $self = shift;
   my ($widget, $msg) = @_;
   $widget->bind('<Enter>', [ sub { $dbistatus = $_[1]; }, $msg ] );
   $widget->bind('<Leave>', sub { $dbistatus = ""; } );
}

sub dbish_clear {
   my $self = shift;

   $rslt_txt->delete( "1.0", 'end' );
   $entry_txt->delete( "1.0", 'end' );
   $ind_txt->delete( "1.0", 'end' );
   # $self->release;
}
   

sub dbish {
   my $self = shift;
   return;
}

sub opt_dis_grid {
   my $self = shift;
   if (! $opt_dis_grid ) {
      $self->release();
   }
}

# Get a file from the operating system.
sub load_query {

}

# Save a file to an operating system.
sub save_query {

}


sub red {
   $auto_ball->configure( -image => $color_ball{red} );
}
sub green {
   $auto_ball->configure( -image => $color_ball{green} );
}

sub tba {
   my $self = shift;
   print RSLT_TXT "Work in progress ...\n";
   0;
}

sub menu_bar {

   print STDERR "menu_bar: in, dbiwd>$dbiwd<\n"
      if ( $main::debug > 0 );

   my $self = shift;

   my($menus_ref) = @_;

   $dbistatus = "Creating menu bar";

   my $f = $dbiwd->Frame( -relief => 'ridge', -borderwidth => 2 );

   $f->pack( -side => 'top', -anchor => 'n', -expand => 1, -fill => 'x' );
   
   # Put the logo on the menu bar.

   my $orac_logo = $dbiwd->Photo(-file=>"$FindBin::RealBin/img/orac.gif");

   $f->Label(-image=> $orac_logo, 
             -borderwidth=> 2,
             -relief=> 'flat'

            )->pack(  -side=> 'left', -anchor=>'w');
   
   # Create a menu bar.

   print STDERR "BEFORE menu bar options: $_\n"
      if ( $main::debug > 0 );

   foreach (qw/File Edit Options Help/) {

      print STDERR "menu bar options: $_\n"
         if ( $main::debug > 0 );

      push( @$menus_ref, $f->Menubutton( -text => $_ , -tearoff => 0 ) );

   }
   print STDERR "AFTER menu bar options, menus-3 >" . $menus_ref->[3] . "<\n"
      if ( $main::debug > 0 );
   
   $menus_ref->[3]->pack(-side => 'right' ); # Help
   $menus_ref->[0]->pack(-side => 'left' );  # File
   $menus_ref->[1]->pack(-side => 'left' );  # Edit
   $menus_ref->[2]->pack(-side => 'left' );  # Options
   
   print STDERR "menus_ref: >" . $menus_ref . "<\n"
      if ( $main::debug > 0 );

   $self->menu_file($menus_ref);
   $self->menu_edit();
   $self->menu_options($menus_ref);
   $self->menu_help($menus_ref);

}


sub menu_file {
   my $self = shift;

   my($menus_ref) = @_;

   print STDERR "menu_file: menusf_ref :>" . $menus_ref . "<\n"
      if ( $main::debug > 0 );

   #
   # Add some options to the menus.
   #
   # File menu

   print STDERR "menus-0 (additem) >" . $menus_ref->[0] . "<\n"
      if ( $main::debug > 0 );

   $menus_ref->[0]->AddItems(
         [ "command" => "Load", -command => sub { $self->tba } ],
         [ "command" => "Save", -command => sub { $self->tba } ],
         "-",
         [ "command" => "Properties", -command => sub { $self->tba } ],
         "-",
         [ "command" => "Exit", -command => sub { $self->tba } ],

                      );
}

sub menu_edit {
   my $self = shift;
}

sub menu_options {
   my $self = shift;

   my($menus_ref) = @_;

   # Options menu

   my $opt_disp = $menus_ref->[2]->menu->Menu;
   my @formats = $self->load_formats;
      
   foreach (@formats) {
      $opt_disp->radiobutton( -label => $_, 
         -variable => \$opt_dis_grid,
         -value => $_,
         );
   }

   $menus_ref->[2]->cascade( -label => "Display format..."); 
   $menus_ref->[2]->entryconfigure( "Display format...", -menu => $opt_disp);
   $opt_dis_grid = 'neat';

   # Create the entries for rows returned.

   my $opt_row = $menus_ref->[2]->menu->Menu;

   foreach (qw/1 10 25 50 100 all/) {

      $opt_row->radiobutton( -label => $_, -variable => \$opt_row_dis_c,
         -value => $_ );
   }

   $menus_ref->[2]->cascade( -label => "Rows return..." );
   $menus_ref->[2]->entryconfigure( "Rows return...", -menu => $opt_row);
   $opt_row_dis_c = 'all';

}

sub menu_help {
   my $self = shift;

   my($menus_ref) = @_;

   # Help menu
   $menus_ref->[3]->AddItems(
      [ "command" => "Index", -command => sub { $self->tba } ],
      "-",
      [ "command" => "About", -command => sub { $self->tba } ],
   );
}

sub menu_button {

   my $self = shift;

   # Create a button bar.
   $dbistatus = "Creating menu button bar";

   my $bf = $dbiwd->Frame( -relief => 'ridge', -borderwidth => 2 );
   $bf->pack( -side => 'top', -anchor => 'n', -expand => 1, -fill => 'x' );

   # need to invoke the execute in other parts of the application.

   $button_exe = $bf->Button( -text=> 'Execute',
                              -command=> sub{ $self->execute_sql() }
                            )->pack(side=>'left');

   $bf->Button( -text=> 'Clear',
                -command=>sub{ $self->dbish_clear(); }

              )->pack(side=>'left');

   $bf->Button( -text=> 'Tables',
                -command=> sub{ $self->tba() }

              )->pack(side=>'left');

   $bf->Button( -text=> 'Copy Results',
                -command=> sub{ $self->tba() }

              )->pack(side=>'left');

   $bf->Button( -text=> 'Commit',
                -command=> sub{ $self->tba() }

              )->pack(side=>'left');

   $bf->Button( -text=> 'Rollback',
                -command=> sub{ $self->tba() }

              )->pack(side=>'left');

   $dbistatus = "Creating Close button";
   
   $bf->Button( -text => "Close",
               -command => sub { 
 
                 $dbiwd->withdraw;
                 $self->{mw}->deiconify();
                 $main::sub_win_but_hand{dbish}->configure(-state=>'active');

                               } 
              )->pack( -side => "right" ); #'

}

#
# Move to the results of the statement executed.  Currently
# no limit on results stored, but this may change.
#
sub move_to_results {
   my $self = shift;
   my $c = shift;
   # Lots of debug information here.
   # print STDERR "Move to Results event for results $c\n";
   # print STDERR join( "\n", $rslt_txt->markNames(), "" );
   # foreach ($rslt_txt->markNames()) {
      # print STDERR "MARK: $_ at ", $rslt_txt->index($_), "\n";
   # }
   $rslt_txt->see( $rslt_txt->index( $self->{marks}->get_results($c) ));
}

#
# As the names implies, this button executes all the statements in the
# current entry buffer.
#
sub execute_all_buffer {

}

# Execute the most currently statement in the entry buffer.
sub execute_sql {

   my $self = shift;

    $dbiwd->Busy;
    my $statement = $exeStatement;
    chomp $statement;
    $statement =~ s:[/;]$::;  # Replace the last / with nothing.
    
    # Are we connected to the database?
    my $dbh = $self->{dbh};
    $self->no_go( "Database handle not openned!"), return unless($dbh);

   print STDERR "\nexecuting statement: $statement\n"
      if ( $main::debug > 0 );

   my $sth = $self->do_prepare( $statement );
   $self->no_go("Failed to prepare statement!" ), return unless ($sth);

   # Statement is prepared, now execute or do.
   my $rv = $self->sth_go( $sth, 1 );

   # 

   $self->no_go("Statement execute failed!" ), return unless ($rv);

   # OK, at this point mark the results window.

   $self->{marks}->set_results($self->{statement_number});
   $rslt_txt->configure( -state => 'normal' );
   $rslt_txt->markSet( $self->{marks}->get_results($self->{statement_number}),
      $rslt_txt->index("insert" )); #"
   $rslt_txt->markGravity( $self->{marks}->get_results($self->{statement_number}), "left" );

   # Does the statement require row displayed? If doesn't then
   # show the status from the executed statement.

   unless ($self->{display_rows}) {
      $self->no_go("");
      $rslt_txt->configure( -state => 'normal' );

      print RSLT_TXT $self->{status}, "\n" if $self->{status};

      $rslt_txt->configure( -state => 'disabled' );
      return;
   }


   # print RSLT_TXT "Number of fields: " . $sth->{NUM_OF_FIELDS} . "\n";
   #
   # Dump return set to a grid.
   #   
   $dbh->{neat_maxlen} = 40004;
   my $class = $self->formatter($opt_dis_grid);
   my $r = $class->new($self);

   # Move the results windows to the end, before starting the output.
   $rslt_txt->see( 'end linestart '); #'

   $rslt_txt->configure( -state => 'normal' );
   $r->header($sth, \*RSLT_TXT, ",");

   my $row;
   while( $row = $sth->fetchrow_arrayref() ) {
      $r->row($row, \*RSLT_TXT, "," );
   }
   $rslt_txt->see( 'end linestart '); #'
   $r->trailer(\*RSLT_TXT);

   $sth->finish;
   $self->no_go( "completed" );
}

sub no_go {
   my $self = shift;
   $dbistatus = shift;
   $entry_txt->tagRemove( 'Exec', $begLn, $idxMark );
   $rslt_txt->configure( -state => 'disabled' );
   $dbiwd->Unbusy;
   return;
}

# This method is used to track the X text widgets with the scroll bar.
sub sync_txt {
   my $self = shift;
   my ($sb, $scrolled, $lbs, @args) = @_;
   $sb->set(@args);
   my ($top, $bottom) = $scrolled->yview();
   foreach my $list (@$lbs) {
      $list->yviewMoveto($top);
   }
}

package orac_Shell::mark;
use strict;
my $statement_count = 0;

my %marks;

sub mark {
   my ( $self, $begin, $end, $mark_beg, $mark_end, $status,
      $results, $index ) = @_;

   my $cur = "sql_" . $statement_count;
   $mark_beg = $cur . "_beg" unless $mark_beg;
   $mark_end = $cur . "_end" unless $mark_end;

   $marks{$statement_count} =  {
      "begin" => $begin,
      "end"   => $end,
      "mark_beg" => $mark_beg,
      "mark_end" => $mark_end,
      "status" => $status,
      "results" => $results,
      "count" => $statement_count,
   };



   return $statement_count++;
}

sub remove {
   my ($self, $mark_inx) = @_;
   if (exists $marks{$mark_inx}) {
      delete $marks{$mark_inx} && $self->{count}--;
   }
}

sub is_marked {
   my ($self, $index) = @_;
   foreach (keys %marks) {

      print STDERR "Checking key: " . $_  . " index: " .  $index . "\n"
         if ( $main::debug > 0 );

      return $_ 
         if ($marks{$_}->{begin} eq $index);
   }
   return undef;

};

sub get_beg {
   my ($self, $inx) = @_;
   $marks{$inx}->{begin};
}

sub set_beg {
   my ($self, $inx, $val) = @_;
   $marks{$inx}->{begin} = $val;
}

sub get_mark_beg {
   my ($marks, $inx) = @_;
   $marks{$inx}->{mark_beg};
}

sub set_mark_beg {
   my ($self, $inx, $val) = @_;
   $marks{$inx}->{mark_beg} = $val;
}


sub get_end {
   my ($self, $inx) = @_;
   $marks{$inx}->{end};
}

sub set_end {
   my ($self, $inx, $val) = @_;
   $marks{$inx}->{end} = $val;
}

sub get_mark_end {
   my ($self, $inx) = @_;
   $marks{$inx}->{mark_end};
}

sub set_mark_end {
   my ($self, $inx, $val) = @_;
   $marks{$inx}->{mark_end} = $val;
}

# Set/Get the results mark name.
sub set_results {
   my ($self, $inx, $val) = @_;
   $marks{$inx}->{results} = "rslt_" . $inx . "_beg";
}

sub get_results {
   my ($self, $inx, $val) = @_;
   $marks{$inx}->{results};
}

sub new {

   print STDERR "orac_Shell::mark::new\n" 
      if ( $main::debug > 0 );

   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self  = {
       count => \$statement_count,
      mark => undef,
    };

   bless($self, $class);

   return $self;
}

1;
