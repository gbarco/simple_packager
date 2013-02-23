use strict;
use Archive::Zip::SimpleZip qw($SimpleZipError);
use File::Basename;
use File::Path;

my %package;

#supports globs and texts
open( CONTENTS, '<', 'package_contents.txt');
my @lines = <CONTENTS>;
close( CONTENTS );

#eval globs and store special commands
for ( @lines ) {
	chomp;
	if ( m/^(\w+)\s*=\s*(.*)$/i ) {
		$package{uc $1} = $2;
	} elsif ( m/^<.*?>$/) {
		push @{$package{CONTENTS}}, eval $_;
	} else {
		#keep all non comments
		push @{$package{CONTENTS}}, $_ unless ( m/^#/ );
	}
}

@lines = undef;

die "Undefined package=output.zip quiting..." unless defined $package{PACKAGE};

print "Prepackaging...\n";
system( $package{PRE_PACKAGE} ) if ( defined $package{PRE_PACKAGE} && $package{PRE_PACKAGE} ne '');

#create path to output filename
File::Path::make_path( File::Basename::dirname( $package{PACKAGE} ) );

print "Packaging...\n";
my $z = Archive::Zip::SimpleZip->new( $package{PACKAGE} ) or die "Cannot create zip file: $SimpleZipError\n";

#add all files
for ( @{$package{CONTENTS}} ) {
	if ( defined $package{SKIP} ) {
		if ( /$package{SKIP}/ ) {
			print "Skipping '$_'\n";
			next;
		}
	}
	print "Adding '$_'...\n";
	$z->add($_) or die "Cannot add '$_' to zip file: $SimpleZipError\n" ;
}
$z->close();

print "Postpackaging...\n";
system( $package{POST_PACKAGE} ) if ( defined $package{POST_PACKAGE} && $package{POST_PACKAGE} ne '');
print "Done!\n";
