#
#
#

package Shell::Mark;

use strict;

use Exporter ();
use vars qw(@ISA $VERSION);
$VERSION = $VERSION = q{1.0};
@ISA=('Exporter');


my $statement_count = 1;

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

   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self  = {
       count => \$statement_count,
      mark => undef,
    };

   bless($self, $class);

	 $statement_count = 1;
	 undef(%marks);

   return $self;
}

1;
