#!/usr/bin/perl
use Getopt::Long;
use warnings;

GetOptions (\%opt,"embl:s","project:s","help");


my $help=<<USAGE;
EMBL to gff
perl $0 --embl test.embl --project moc1

USAGE


if ($opt{help} or keys %opt < 1){
    print "$help\n";
    exit();
}

# Declare and initialize variables
my $fh; # variable to store filehandle
my $record;
my $dna;
my $annotation;
my $offset;
my $library = $opt{embl};
 
# Perform some standard subroutines for test
$fh = open_file($library);
 
 
while( $record = get_next_record($fh) ) {
    next if (length $record < 2); 
    ($annotation, $dna) = get_annotation_and_dna($record);
    my $gene=writegff($annotation,$dna);
    #print "Annotation:\n$annotation\n";
    #print "DNA:\n$dna\n"; 
}
 
exit;
 
################################################################################
# Subroutines
################################################################################
 
# open_file
#
#   - given filename, set filehandle
 
sub writegff
{
my ($anno,$dna)=@_;
my $count=0;
open OUT, ">$opt{project}.gff" or die "$!";
while($anno=~/FT   CDS             (.*?)[\)\/]/gs){
   my $pos=$1;
   my $strand="+";
   $count++;
   my $name=$opt{project}.".".$count;
   $pos=~s/[\n\s]//g;
   $strand= "-" if ($pos=~/complement/);
   $pos=~s/[a-z]//g;
   $pos=~s/[\(\>]//g; 
   my @exon=split(",",$pos);
   my @exonp;
   foreach my $e (@exon){
      my @unit;
      if ($e=~/(\d+)\.\.(\d+)/){
         $unit[0]=$1;
         $unit[1]=$2;
      } 
      push (@exonp,[$unit[0],$unit[1]]);
   }
   my $mrnas=$exonp[0][0];
   my $mrnae=$exonp[$#exonp][1];
   print OUT "$opt{project}\tEMBL\tmRNA\t$mrnas\t$mrnae\t\.\t$strand\t\.\tID=$name;\n";
   foreach my $ep (@exonp){
      print OUT "$opt{project}\tEMBL\tCDS\t$ep->[0]\t$ep->[1]\t\.\t$strand\t\.\tParent=$name;\n";
   }
   print "$strand\t$pos\n";
}
close OUT;
open OUT, ">$opt{project}.fasta" or die "$!";
   print OUT ">$opt{project}\n$dna\n";
close OUT;
}


sub open_file {
 
    my($filename) = @_;
    my $fh;
 
    unless(open($fh, $filename)) {
        print "Cannot open file $filename\n";
        exit;
    }
    return $fh;
}
 
# get_next_record
#
#   - given GenBank record, get annotation and DNA
 
sub get_next_record {
 
    my($fh) = @_;
 
    my($offset);
    my($record) = '';
    my($save_input_separator) = $/;
 
    $/ = "//\n";
 
    $record = <$fh>;
 
    $/ = $save_input_separator;
    
    return $record;
}
 
# get_annotation_and_dna
#
#   - given GenBank record, get annotation and DNA
 
sub get_annotation_and_dna {
 
    my($record) = @_;
 
    my($annotation) = '';
    my($dna) = '';
 
    # Now separate the annotation from the sequence data
    #($annotation, $dna) = ($record =~ /^(LOCUS.*ORIGIN\s*\n)(.*)\/\/\n/s);
    ($annotation, $dna) = ($record =~ /^(FH\s+Key.*SQ\s+Sequence.*?BP;\s*\n)(.*)\/\/\n/s); 
    # clean the sequence of any whitespace or / characters 
    #  (the / has to be written \/ in the character class, because
    #   / is a metacharacter, so it must be "escaped" with \)
    $dna =~ s/[\s\/\d]//g;
     
    return($annotation, $dna)
}
 
# search_sequence
#
#   - search sequence with regular expression
 
sub search_sequence {
 
    my($sequence, $regularexpression) = @_;
 
    my(@locations) = (  );
 
    while( $sequence =~ /$regularexpression/ig ) {
        push( @locations, pos );
    }
 
    return (@locations);
}
 
# search_annotation
#
#   - search annotation with regular expression
 
sub search_annotation {
 
    my($annotation, $regularexpression) = @_;
 
    my(@locations) = (  );
 
    # note the /s modifier--. matches any character including newline
    while( $annotation =~ /$regularexpression/isg ) {
        push( @locations, pos );
    }
 
    return (@locations);
}

