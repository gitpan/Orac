
#
# vim:ts=2:sw=2
# Package: Orac::Shell::Do
# contains the database interaction commands.
#

package Shell::Do;

sub do_prepare {
	my $self = shift;
	my $statement = shift;
	my $sth;
	return undef unless $statement;
	eval {
		$sth = $self->{dbh}->prepare($statement);
		# $sh->sth_go($sth, 1);
	};
	if ($@) {
		my $err = $@;
		$err =~ s: at \S*Shell/Do.pm line \d+(,.*?chunk \d+)?::
			if !$self->{debug} && $err =~ /^DBD::\w+::\w+ \w+/;
				print STDERR "$err";
	}
	# $self->{dbh}->prepare( $statement );
	$sth;
}

sub sth_go {
	my ($self, $sth, $execute) = @_;
	my $rv;
	if ($execute || !$sth->{Active}) {
		my @params;
		my $params = $sth->{NUM_OF_PARAMS} || 0;
		print "Statement has $params parameters:\n" if $params;
		foreach(1..$params) {
	    	#my $val = $sh->readline("Parameter $_ value: ");
	    	push @params, $val;
		}
			$rv = $sth->execute(@params);
			#print STDERR "Value returned: $rv\n";
			return $rv if !defined($rv); 
			$self->{display_rows} = 1;
	}
	
	if (!$sth->{'NUM_OF_FIELDS'}) { # not a select statement
		local $^W=0;
		$rv = "undefined number of" unless defined $rv;
		$rv = "unknown number of"   if $rv == -1;
		$self->{status} = "[$rv row" . ($rv==1 ? "" : "s") . " affected]"; #"
		$self->{display_rows} = 0;
	}

	$rv;
}

sub do_execute {
	my $self = shift;
	my $sth  = shift;
$sth->execute(@_);
}
sub do_finish {
	my $self = shift;
}
sub do_fetch {
	my $self = shift;
}
sub do_commit {
	my $self = shift;
}
sub do_rollback {
	my $self = shift;
}
sub do_do {
	my $self = shift;
$self->{dbh}->do( @_ );
}




1;
__END__
