#
# vim: ts=2:sw=2:ai:aw
################################################################################
#
# Orac DBI Visual Shell.
# Versions 1.0.10
#
# Copyright (c) 1998,1999 Andy Duncan, Thomas A. Lowery
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
# Support questions and suggestions can be directed 
# to mailto:manage-orac-dba-users@listserv.kkitts.com
# Download from CPAN/authors/id/A/AN/ANDYDUNC or
# http://www.kkitts.com/orac-dba/index.html
################################################################################
#


package orac_Shell;
@ISA = qw{
	Shell::Do
	Shell::File
	Shell::Format
	Shell::Menu
	Shell::Meta
};

use Exporter;

use Tk 800.014;
use Tk::Pretty;
use Tk::Dialog;
use Tk::Adjuster;

use Carp;

use FindBin;
use lib $FindBin::RealBin;

use Shell::Connection;
use Shell::Current;
use Shell::Do 1.0;
use Shell::Edit 1.0;
use Shell::File 1.0;
use Shell::Format 1.0;
use Shell::Mark 1.0;
use Shell::Menu 1.0;
use Shell::Meta 1.0;
use Shell::Properties 1.0;
use Shell::Options;

use strict;

my $VERSION;
$VERSION = $VERSION = qq{1.0.10};

my ($ind_txt);
my (@ind_txt);
my ($entry_frm);
my $_Dbistatus;
my %rmarkers;

sub new
{

	my $proto = shift; 
	my $class = ref($proto) || $proto;
	my $mw = shift;
	my $dbh = shift;

	my $self  = {
		buttons    		=> undef,
		BinDir     		=> $FindBin::RealBin,
		debug					=> $main::debug,
		dbh						=> $dbh,
		dbiwd					=> undef,
		display_rows	=> 1,
		edit					=> undef,
		entry_txt			=> undef,
		icon					=> undef,
		imagedir			=> qq{$FindBin::RealBin/img/},
		meta					=> undef,
		marks					=> Shell::Mark->new,
		mw						=> $mw,
		prop					=> undef,
		rslt_txt			=> undef,
		rv         		=> undef,
		status     		=> \$_Dbistatus,
		menus => {
			file 		=> undef,
			edit		=> undef,
			meta		=> undef,
			options	=> undef,
			help 		=> undef,
			order		=> [qw/Help File Edit Meta Options/],
		},
		connection => undef,
		current				=> undef,
		options => undef,
		properties => undef,
	};

	bless($self, $class);

	$self->{options}    = Shell::Options->new($self);
	$self->{properties} = Shell::Properties->new($self);
	$self->{edit}       = Shell::Edit->new($self);
	$self->{current}    = Shell::Current->new($self);
	$self->{connection}    = Shell::Connection->new($self);


	# Restore options if prop is defined.
	$self->properties->load() if ($self->properties->state);


   # save off args...
   # or other encapsulated values, these do NOT inherit!


	# Define the icons to use.
	$self->icon( {
		q{green}     => q{grn_ball.gif},
		q{red}       => q{red_ball.gif},
		q{yellow}    => q{yel_ball.gif},
		q{checkmark} => q{tick.gif},
		q{exec}      => q{exec_tick.gif},
		q{execall}   => q{exec_all.gif},
		q{clear}     => q{eraser.gif},
		q{commit}    => q{th_up.gif},
		q{rollback}  => q{th_dn.gif},
		q{back}  		 => q{back.gif},
	} );

	#
	# Define the methods to handle the properties.
	#
	return $self;
}

#
# Define the icons (pictures) used.
#
sub icon {
	my $self = shift;
	croak qq{Icon called without arguments.} unless @_;
	my $icon = shift;
	if ((ref $icon)eq q{HASH}) {
		foreach my $ky (keys %$icon) {
			$self->{icon}->{$ky} = $self->mw->Photo(-file=> $self->imagedir . $icon->{$ky});
		}
	} else {
		croak qq{Icon $icon is not defined!} unless exists $self->{icon}->{$icon};
		return $self->{icon}->{$icon};
	}

}

# Create the top level for Orac DBI Shell.

sub dbish_open {
   my $self = shift;

   #
   # Determine if the dbish window is defined.  If it isn't, define the
   # window.
   #

   my $dbiwd;

   if (defined($self->dbiwd)) {

      $self->dbiwd->deiconify();
      $self->dbiwd->raise();

      $dbiwd = $self->dbiwd;

   } else { 
      
      # Create a Toplevel window under the current main.

      $self->dbiwd($self->mw->Toplevel());

      $dbiwd = $self->dbiwd;

      $dbiwd->title( "Orac-DBA SQL Shell" );

      # Create status label

      my $sf = $dbiwd->Frame( -relief => 'groove',
                              -bd => 2 
                            )->pack( -side => 'bottom', -fill => 'x' );

      # This is the status bar.

      $self->buttons({ q{auto_commit} =>
				$sf->Label(-image=> $self->icon(q{green}), 
                              -borderwidth=> 2,
                              -relief=> 'flat'
                             )->pack(  -side=> 'right', -anchor=>'w')});

			my $auto_commit = $self->buttons( q{auto_commit} );
			$auto_commit->bind( q{<Enter>}, 
				sub {
					my $msg = qq{Auto Commit is };
					$msg .= qq{OFF} unless $self->dbh->{AutoCommit};
					$msg .= qq{ON}  if $self->dbh->{AutoCommit};
					$msg .= qq{.  Click to change.};
					$self->status($msg);
			} );
			$auto_commit->bind(q{<Leave>}, sub { $self->status(""); } );
			$auto_commit->bind(q{<Button-1>}, sub { $self->auto_commit(); } );

      $self->buttons({ q{raise_error} =>
				$sf->Label(-image=> $self->icon(q{green}), 
                              -borderwidth=> 2,
                              -relief=> 'flat'
                             )->pack(  -side=> 'right', -anchor=>'w')});

			my $raise_error = $self->buttons( q{raise_error} );
			$raise_error->bind( q{<Enter>}, 
				sub {
					my $msg = qq{Raise Error is };
					$msg .= qq{OFF} unless $self->dbh->{RaiseError};
					$msg .= qq{ON}  if $self->dbh->{RaiseError};
					$msg .= qq{.  Click to change.};
					$self->status($msg);
			} );
			$raise_error->bind(q{<Leave>}, sub { $self->status(""); } );
			$raise_error->bind(q{<Button-1>}, sub { $self->raise_error(); } );

      $self->buttons({ q{print_error} =>
				$sf->Label(-image=> $self->icon(q{green}), 
                              -borderwidth=> 2,
                              -relief=> 'flat'
                             )->pack(  -side=> 'right', -anchor=>'w')});

			my $print_error = $self->buttons( q{print_error} );
			$print_error->bind( q{<Enter>}, 
				sub {
					my $msg = qq{Print Error is };
					$msg .= qq{OFF} unless $self->dbh->{PrintError};
					$msg .= qq{ON}  if $self->dbh->{PrintError};
					$msg .= qq{.  Click to change.};
					$self->status($msg);
			} );
			$print_error->bind(q{<Leave>}, sub { $self->status(""); } );
			$print_error->bind(q{<Button-1>}, sub { $self->print_error(); } );



      $sf->Label( -textvariable => \$_Dbistatus )->pack(-side => 'left');

      # Create the menu bar with entries.
      $self->menu_bar();

      # Create the menu button with entries.
      $self->menu_button();

      # Create Text widget for results display.
      $self->status("Creating Text results widget");

      $self->new_entry( $_ );

      # Tie the windows to the file types:
      tie (*ENTRY_TXT, 'Tk::Text', $self->entry_txt);
      tie (*RSLT_TXT,  'Tk::Text', $self->rslt_txt);


      # Finallly, iconize window

      main::iconize($dbiwd);
   }

	# If the auto commit is on, set the ball to green, else red.
	# This is adjusted each time the window is entered. 
	$self->auto_commit($self->dbh->{AutoCommit});
	$self->print_error($self->dbh->{PrintError});
	$self->raise_error($self->dbh->{RaiseError});
		

   # Make the Main Window and icon.
        # Disable button, calling orac_Shell

   $self->mw->iconify() if $self->options->mini_main_wd;

   $self->status("Window for Tk created.");

   # Last thing is focus on the entry box.
   $self->entry_txt->focusForce();
   $self->rslt_txt->configure( -state => 'disabled' );

}

sub buttons {
	my $self = shift;
	croak qq{Buttons called without arguments.} unless @_;
	my $button = shift;
	if ((ref $button) eq q{HASH}) {
		foreach my $ky (keys %$button) {
			$self->{buttons}->{$ky} = $button->{$ky};
		}
	} else {
		return $self->{buttons}->{$button};
	}
	return undef;
}

sub buttons_configure {
	my $self = shift;
	croak qq{Button configure called without arguments.} unless @_;
	my $button = shift;
	if ((ref $button) eq q{HASH}) {
		foreach my $ky (keys %$button) {
			my $lbl = $ky;
			my $config = $button->{$ky};
			$self->{buttons}->{$lbl}->configure(%$config);
		}
	} else {
		return $self->{buttons}->{$button};
	}
	return undef;
}

my ($curx);
sub where_am_i {
   my ($self, $x, $y, $txt ) = @_;
   $curx = $x;
   $self->entry_txt->focus();

};

sub new_entry {
	my ($self, $x) = @_;
	my $main_frame = $self->dbiwd->Frame( -relief => 'groove',
                                    )->pack(-fill=>'both', 
                                            -expand => 1,
                                            -side => 'top' 
                                           );

	$self->rslt_txt($main_frame->Scrolled( "Text", 
                                         -relief => 'groove',
                                         -width => 78, 
                                         -height => 10,
                                         -cursor=>undef,
                                         -foreground=>$main::fc,
                                         -background=>$main::bc,
                                         -font=>$main::font{name},
                                         -wrap => "none",
                                         -takefocus => 0,
                                         -setgrid => 1,
                                       ));


      $entry_frm = $main_frame->Frame( -relief => 'groove',
                                     )->pack(-fill=>'both', 
                                             -expand => 1,
                                             -side => 'top' 
                                            );


      # Create Text widget for command entry
      $self->status(qq{Creating Text entry widget});

      my $adjuster = $main_frame->Adjuster();

      $adjuster->packAfter(  $entry_frm, 
                             -side => 'top',
                          );

	my $s = $entry_frm->Scrolled( 'Text',
		-scrollbars => 'wo',
		-height => 12,
        -setgrid => 1,
	)->pack(-expand =>1, -fill=> "both");

   my $ysb = $s->Subwidget( "yscrollbar" );

   $ind_txt = $s->Text( 
	 	-width => 0,
		-state => 'normal',
		-borderwidth => 0,
		); 
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

      $last = $this;

   };


   $self->entry_txt($s->Text( # 'Text',
      -relief => 'groove',
      -width => 74,
      # -height => 3,
      -cursor=>undef,
      -foreground=>$main::fc,
      -background=>$main::ec,
      -yscrollcommand => $ss,
			-font=>$main::font{name},
			-borderwidth => 0,
			-setgrid => 1,
   ));

	my $sc = sub {
      $self->entry_txt->yview(@_);
      #$ind_txt->yview(@_);
	};

	$ysb->configure( -command => $sc );


	#$ind_txt->pack( 
		#-side => 'left',
		#-pady => 1,
		#-expand => 0,
		#-fill => 'both',
	#);
	$self->entry_txt->pack(
		-side => 'left',
		-pady => 1,
		-expand => 1,
		-fill => 'both',
	);
	$self->rslt_txt->pack( -expand=>1, -fill=>'both', -side => 'top' );
	$ind_txt->configure( -state => 'disabled', );

	# Pick up the Return key ... see return_press.
	$self->entry_txt->bind( "<Return>", sub { $self->return_press() } );
	$self->entry_txt->tagConfigure( "Exec",  -foreground => "green" );
	$self->entry_txt->tagConfigure( "Error",  -foreground => "red" );

	# Tags for the results window.
	$self->rslt_txt->tagConfigure( "Bold", -background => "white" );

}

#
#  Allows the user to change auto commit.
#
sub auto_commit {
	my ($self, $cmt) = @_;

	unless(@_ > 1) {
	if($self->dbh->{AutoCommit}) {
		# AutoCommit is on, turn off, enable buttons.
		$cmt = $self->dbh->{AutoCommit} = 0;
	} else {
		# AutoCommit is off, turn on, disable buttons.
		$cmt = $self->dbh->{AutoCommit} = 1;
	}
	}
		$self->buttons_configure( {
			q{auto_commit} => { -image => $self->icon(q{red}) },
			q{commit}      => { -state => 'normal' },
			q{rollback}    => { -state => 'normal' } } )
			unless $cmt;
		$self->buttons_configure( {
			q{auto_commit} => { -image => $self->icon(q{green})},
			q{commit}      => { -state => 'disabled' },
			q{rollback}    => { -state => 'disabled' } } )
			if $cmt;
	return $cmt;
}

#
#  Allows the user to change print error.
#
sub print_error {
	my ($self, $cmt) = @_;

	unless(@_ > 1) {
	if($self->dbh->{PrintError}) {
		# AutoCommit is on, turn off, enable buttons.
		$cmt = $self->dbh->{PrintError} = 0;
	} else {
		# AutoCommit is off, turn on, disable buttons.
		$cmt = $self->dbh->{PrintError} = 1;
	}
	}
		$self->buttons_configure( {
			q{print_error} => { -image => $self->icon(q{red}) } } )
			unless $cmt;
		$self->buttons_configure( {
			q{print_error} => { -image => $self->icon(q{green})} } )
			if $cmt;
	return $cmt;
}

#
#  Allows the user to change raise error.
#
sub raise_error {
	my ($self, $cmt) = @_;

	unless(@_ > 1) {
	if($self->dbh->{RaiseError}) {
		# AutoCommit is on, turn off, enable buttons.
		$cmt = $self->dbh->{RaiseError} = 0;
	} else {
		# AutoCommit is off, turn on, disable buttons.
		$cmt = $self->dbh->{RaiseError} = 1;
	}
	}
		$self->buttons_configure( {
			q{raise_error} => { -image => $self->icon(q{red}) } } )
			unless $cmt;
		$self->buttons_configure( {
			q{raise_error} => { -image => $self->icon(q{green})} } )
			if $cmt;
	return $cmt;
}

#
# Commit: Only works if auto commit is off.
#
sub commit {
	my $self = shift;
	$self->dbh->commit;
	$self->rslt_txt->configure( -state => q{normal} );
	print RSLT_TXT qq{\nCommitted!\n};
	$self->rslt_txt->see(q{end});
	$self->rslt_txt->configure( -state => q{disabled} );
}

#
# Rollback: Only works if auto commit is off.
#
sub rollback {
	my $self = shift;
	$self->dbh->rollback;
	$self->rslt_txt->configure( -state => q{normal} );
	print RSLT_TXT qq{\nRolled Back!\n};
	$self->rslt_txt->see(q{end});
	$self->rslt_txt->configure( -state => q{disabled} );
}

#
# Because I really dislike have to move the mouse up to the execute
# button, if the only character on a line is /, execute the above
# statement.
#
sub return_press {
   my $self = shift;

   # Determine where the cursor is.
   my $ind = $self->entry_txt->index( 'insert - 1 lines lineend' );

   # Grab the last line of text.
   my $txt = $self->entry_txt->get( "$ind - 1 chars" , "$ind" );
   chomp $txt;

	# The previously entered line is only a /, exeucte.
	if ($txt =~ m:[/;]$: and $self->options->autoexec) {

		$self->doit( $ind );

	} 
}

sub check_ind_txt {
   my ($self, $pl) = @_;

   if ($ind_txt->compare( 'end', "<=", "$pl.0" ) ) {
      $ind_txt->insert( 'end', "\n" );
   }
}

#
# Tag Statement Errored: The statement failed to execute.
#

sub tag_statement_errored {
	my ($self, $beg, $end) = @_;
	$beg = $self->current->beg unless $beg;
	$end = $self->current->end unless $end;
	$self->entry_txt->tagAdd( 'Error', $beg, $end );
	$self->marks->remove($self->current->stat_num);
}

sub untag_statement_errored {
	my ($self, $beg, $end) = @_;

	$beg = $self->current->beg unless $beg;
	$end = $self->current->end unless $end;

	$self->entry_txt->tagRemove( 'Error', $beg, $end );
}

#
# Create the results button next to the statement
# executed.  The results button is only created, if
# one does not currently exist.
#

sub create_results_btn {
	my ($self, $bl) = @_;
	$bl = $self->current->stat_num unless $bl;
	if (!$self->current->is_marked) {
		return $self->set_results_btn($bl);
	}
	return 0;
}
# 
# Determine where the markers go
#


sub set_results_btn {
	my ($self, $c, $inx ) = @_;

	$c = $self->current->stat_num unless $c;

	# Enable the ind widget to accept the line number.
	$ind_txt->configure( -state => 'normal' );

	 # Round off the current
   my $pl = int( 
	 	$self->entry_txt->index( $self->marks->get_mark_beg($c)) + .99 );

   $self->check_ind_txt($pl);

   # Add just a line place for statement marker.
   # Using closure witht the button, instead of a subroutine.
   # see Advanced Perl Programming p60.
   my $mv_to_res = sub { 
      $self->move_to_results( $c )
   };


	$rmarkers{$c} = $self->entry_txt->Button( # -text => '',
         -image => $self->icon(q{checkmark}),
         #-background=>$main::bc,
         -justify => 'center',
         -height => 8,
         -width => 8,
         -highlightthickness => 1,
         -relief => 'raised',
				 -command => $mv_to_res,
      );

	$self->bind_message( $rmarkers{$c}, q{Scroll results window to statement results.} );

	$self->entry_txt->windowCreate( "$pl.0", -window => $rmarkers{$c} );
	$self->entry_txt->insert( "$pl.1", " " );

	$ind_txt->configure( -state => 'disabled' );
}

#
# Set the current buffer to null (undefined)
#
sub clear_current_buffer {
	my $self = shift;
	foreach (keys %{$self->current}) {
		$self->current->$_(undef);
	}
}

sub get_all_text_buffer {
	my ($self, $cinx) = @_;
	$cinx = q{end} unless $cinx;
	return $self->entry_txt->get(q{1.0}, $cinx);
}

#
# Get the current buffer text.
#

sub get_current_buffer {
   my ($self, $cinx) = @_;
   my $stinx;

	 # First, clear the current buffer.
	 $self->clear_current_buffer();

	 $cinx = 'insert' unless $cinx;
	 # Determine where we are.
   $self->current->cmark($self->entry_txt->index( $cinx ));

	 # Search the statement.
   my $inx = $self->entry_txt->search( 
      -backwards, 
      -regexp, 
      '[;/]$', #',
      $stinx = $self->entry_txt->index( "$cinx - 2 chars"),
      "1.0",
   );

   # The buffer could have more than one statement in it.
   # Find the last statement. Look for the new statement on
   # the next line.
   $self->current->beg("1.0");
   if (defined $inx and length($inx) > 0) {
      # Convert the index to something more usable.
      $self->current->beg( $self->entry_txt->index("$inx + 1 chars")); 
   } 

	 # Get the current statement.
   $self->current->statement($self->entry_txt->get( $self->current->beg, $self->current->cmark));
   $self->entry_txt->tagAdd( 'Exec', $self->current->beg, $self->current->cmark );

	$self->current->end($self->current->cmark);
   #
   # The statement determined, now set the begin and end marks.
   #

   my $marks = $self->marks;
   my $cc = $marks->is_marked($self->current->beg);


   if (not defined($cc)) {
      $cc = $marks->mark( $self->current->beg, $self->current->cmark );
			$self->current->stat_num($cc);
      $self->entry_txt->markSet( $marks->get_mark_beg($cc),
			$marks->get_beg($cc) );
      $self->entry_txt->markGravity( $marks->get_mark_beg($cc), "left" );
			$self->current->is_marked(0);
   } else {
      # Statement is marked already, update the index information.
      $marks->set_mark_beg($cc,$self->current->beg);
      $marks->set_mark_end($cc,$self->current->cmark);
			$self->current->stat_num($cc);
			$self->current->is_marked(1);
   }

   $cc;
}


sub bind_message {
   my $self = shift;
   my ($widget, $msg) = @_;
   $widget->bind('<Enter>', [ sub { $self->status($_[1]); }, $msg ] );
   $widget->bind('<Leave>', sub { $self->status(""); } );
}

sub replace_buffer {
	my ($self, $buffer) = @_;
	$self->clear_entry;
	print ENTRY_TXT $buffer . qq{\n};
}

sub clear_all_marks {
   my $self = shift;
	
	# Used tmp variables to reduce confusion.
	for (sort keys %rmarkers) {
		my $widget = $rmarkers{$_};
		if (Tk::Exists($widget)) {
			my $mk  = $self->entry_txt->index($widget);
			my $mk2 = $self->entry_txt->index(qq{$mk + 2 chars});
			$self->entry_txt->delete( $mk, $mk2 );
		}
			delete $rmarkers{$_};
	}

	undef(%rmarkers);
	$self->marks(Shell::Mark->new);
}

sub clear_entry {
	my $self = shift;
	$self->entry_txt->delete( "1.0", 'end' );
	$self->clear_all_marks;
}

sub clear_result {
	my $self = shift;
	# Clear the results window.  I may have to release the
	# current marks.
	$self->rslt_txt->configure( -state => 'normal' );
	$self->rslt_txt->delete( "1.0", 'end' );
	$self->rslt_txt->configure( -state => 'disabled' );

	$self->clear_all_marks;
}

sub clear_all {
   my $self = shift;

	# Clear the results window.  I may have to release the
	# current marks.
	$self->clear_result;

	# Clear the entry window.
	$self->clear_entry;

	# Clear the indicator window.
	#$ind_txt->configure( -state => 'normal' );
	#$ind_txt->delete( "1.0", 'end' );
	#$ind_txt->configure( -state => 'disabled' );

	# Release the marks structure and rebuild the object.

	return;
}
   
sub tba {
   my $self = shift;
   print RSLT_TXT "Work in progress ...\n";
   0;
}

#
# Move to the results of the statement executed.  Currently
# no limit on results stored, but this may change.
#
sub move_to_results {
   my ($self, $c) = @_;
	if( $self->{rslt_txt}->tagRanges( "Bold" ) ) {
		$self->{rslt_txt}->tagRemove( 'Bold', $self->{rslt_txt}->tagRanges( "Bold" ) );
	}
	 my $rslt_inx =$self->{rslt_txt}->index( $self->{marks}->get_results($c));
   $self->{rslt_txt}->see( $rslt_inx );
	 $self->{rslt_txt}->tagAdd( 'Bold', $rslt_inx, "$rslt_inx lineend" );
}

#
# doit:  Executes either from the execute button or using [/;]
#
sub doit {
	my ($self, $inx) = @_;


	$inx = $self->entry_txt->index( 'insert lineend' ) unless $inx;

	#print STDERR "doit: $inx\n";

	# get current buffer finds the sql statement.
	$self->get_current_buffer( $inx );

	# now execute it;
	$self->execute_sql();

	# If the execution happened, do a number of things.
	# Mark the results or tag as errored.
	if (!$self->current->status) {
		#my ($start, $end) = $self->entry_txt->tagNextrange( 'Error', $begLn );
		# Untag the statement if error tagged.
		$self->untag_statement_errored();
		$self->create_results_btn();
	} else {
		# Change the text to a error.
		$self->tag_statement_errored();
		# Put up a dialog box with the error message.
		$self->message_dialog(qq{Error Message},
			$self->current->msg . qq{\n\n$self->current->statement\n} )
		if ($self->options->stop_on_error); #
	}

}

#
# Display a dialog box to the user.  Using this method until
# we create a dialog handler in the core function.
#
sub message_dialog {
	my ($self, $title, $msg) = @_;

	$title = "Message Dialog Box" unless $title;
	$msg = "Well, you called for a message dialog, but didn't give a message"
		unless $msg;
	
	my $d = $self->dbiwd->Dialog( 
		-title => $title,
		-text => $msg
	);
	return $d->Show;
}

#
#
#
sub search_forward {
	my ($self, $inx) = @_;

	$inx = $self->entry_txt->index( 'current' ) unless $inx;

	return $self->entry_txt->search( 
      -regexp, 
      '[;/]$', #',
      $inx,
      "end",
   );
}

#
# As the names implies, this button executes all the statements in the
# current entry buffer.
#
sub execute_all_buffer {
	my ($self) = @_;

	#
	# Start at the top of the buffer and execute each statement.
	#
	my $cinx = '1.0';
	my $done = 0;
	my $i = "";
	while( !$done ) {
		$self->entry_txt->see( $cinx );
		$i = $self->search_forward( $cinx );
		if ( !defined($i) or length($i) == 0 ) {
			$done = 1;
			last;
		}
		$i = $self->entry_txt->index( "$i lineend" );

		$self->doit( $i );
		$cinx = $self->entry_txt->index( qq{$i lineend} );
	};

}

# Execute the most currently statement in the entry buffer.
sub execute_sql {

   my $self = shift;

    $self->dbiwd->Busy;
    my $statement = $self->current->statement;
    chomp $statement;
    $statement =~ s:[/;]$::;  # Replace the last / with nothing.
    
   my $sth = $self->do_prepare( $statement );
   $self->no_go("Failed to prepare statement!" ), return undef
	 	if ($self->current->status);

   # Statement is prepared, now execute or do.
   my $rv = $self->sth_go( $sth, 1 );

   $self->no_go("Statement execute failed!" ), return undef 
	 	if ($self->current->status);

		# OK, at this point mark the results window.
		$self->results_mark();

		$self->display_results($sth);

		#
		# Does the statement require row displayed? If doesn't then
		# show the status from the executed statement.
		#
		$self->no_go( "completed" );
		return $self->current->status(0) unless $self->current->status;
}

sub display_results {
	my ($self, $sth) = @_;

	$self->dbiwd->Busy;

	my $sav_state = $self->rslt_txt->cget( -state );
	$self->rslt_txt->configure( -state => q{normal} );

	if ($self->current->display) {
		$self->dbh->{neat_maxlen} = 40004;
		my $class = $self->formatter($self->options->display_format);
		my $r = $class->new($self);
		$r->header($sth, \*RSLT_TXT, ",");

		my $row;
		while( $row = $sth->fetchrow_arrayref() ) {
			$r->row($row, \*RSLT_TXT, "," );
		}
		$r->trailer(\*RSLT_TXT);

		$sth->finish;
	} else {
		print RSLT_TXT $self->current->msg, "\n" unless $self->current->status;
	}

	$self->rslt_txt->see( q{end linestart});
	$self->rslt_txt->configure( -state => $sav_state );
	$self->dbiwd->Unbusy;
}

sub no_go {
   my $self = shift;
   $self->status(shift);
   $self->entry_txt->tagRemove( 'Exec', $self->current->beg, $self->current->cmark );
   $self->rslt_txt->configure( -state => 'disabled' );
   $self->dbiwd->Unbusy;
   return;
}
sub results_mark {
	my ($self, $stn) = @_;
	my $marks = $self->{marks};
	$stn = $self->current->stat_num unless $stn;
	$marks->set_results($stn);
	$self->rslt_txt->configure( -state => 'normal' );
	$self->rslt_txt->markSet( 
		$marks->get_results($stn),
		$self->rslt_txt->index("insert" )); 
	$self->rslt_txt->markGravity( 
		$marks->get_results($stn), "left" );
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

sub status {
	my $self = shift;
	if (@_) {
		return $_Dbistatus = shift;
	} else {
		return $_Dbistatus;
	}
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";
	use vars qw($AUTOLOAD);
	my $command = $AUTOLOAD;
	$command =~ s/.*:://;
	
	unless (exists $self->{$command}) {
		croak "Can't access '$command' field in object of class $type";
	}
	if (@_) {
		return $self->{$command} = shift;
	} else {
		return $self->{$command};
	}
	croak qq{This line shouldn't ever be seen}; #'
}

1;
