#
#
#
package Shell::Current;
use strict;
use Carp;

sub new {
	my $proto = shift; 
	my $class = ref($proto) || $proto;

	my $self  = {
			status    => undef,
			beg       => undef,
			end       => undef,
			cmark     => undef,
			display   => undef,
			stat_num  => undef,
			is_marked => undef,
			msg       => undef,
			statement => undef,
		};
	bless($self, $class);
}

sub AUTOLOAD {
	my $self = shift;
	my $type = ref($self) || croak "$self is not an object";
	use vars qw($AUTOLOAD);
	my $option = $AUTOLOAD;
	$option =~ s/.*:://;
	
	unless (exists $self->{$option}) {
		croak "Can't access '$option' field in object of class $type";
	}
	if (@_) {
		return $self->{$option} = shift;
	} else {
		return $self->{$option};
	}
	croak qq{This line shouldn't ever be seen}; #'
}

1;
