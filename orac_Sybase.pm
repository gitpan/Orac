package orac_Sybase;

sub init1_orac_Sybase {
   # Does nothing in Oracle yet
}
sub init1_orac_Sybase {
   package main;

   # Place here whatever environmental variables are needed
   # for dbi:Sybase, eg (for oracle):
   # $ENV{TWO_TASK} = $v_db;
}
sub init2_orac_Sybase {
   package main;

   # Place here any bits of code you would like to run
   # once you've connected to each database.  For Oracle,
   # you may want to select the database block size into
   # a variable, so it's available for each subsequent 
   # statement, without continually reloading it.
}
sub init3_orac_Sybase {
   package main;

   my($cm,$sub,$frm) = @_;

   # We'll cover this one later.  Don't do anything here
   # unless you know what it is you're trying to achieve.

   return($cm,$frm);
}
sub init4_orac_Sybase {
   package main;

   my $flag = shift;

   # Again, this is for special report formatting.  
   # You do not need to do anything here, for now.

}
######################### Database dependent code functions below here #########################
1;
