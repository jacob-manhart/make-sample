#! perl.exe

use strict;
use warnings;
use String::Random qw(random_regex random_string);
use Spreadsheet::SimpleExcel;

###################### USER INPUT ######################

print "\nConfirmit Project Number:\n>";
my $cnum = <ARGV>;
chomp($cnum);

print "\nInternal Project Number:\n>";
my $pnum = <ARGV>;
chomp($pnum);

print "\nProvide any additional text for the filename $cnum\_$pnum...\n>";
my $addtext = <ARGV>;
chomp($addtext);

print "\nHow many characters should each ID contain?\n>";
my $charlimit = <ARGV>;
chomp($charlimit);

print "\nDo you just want to create IDs? (y\/n)\n>";
my $intent = <ARGV>;
chomp $intent;

###################### BUILDING JUST IDS ######################

if($intent eq 'y'){    
	print "\nHow many Records?\n>";
	my $idlimit = <ARGV>;
	chomp($idlimit);

    my @ids = makeIDs($idlimit,$charlimit);
    open OUT, ">$cnum\_$pnum$addtext.txt"; 
    foreach(@ids){
        print OUT "$_\n";
    }
    exit;
}

###################### MORE USER INPUT ######################
my $totalRecords = 0;

print "\nTest, Live, or Both? (t/l/b)\n>";
my $lktyp = <ARGV>;
chomp($lktyp);

###################### COUNTRY HANDLING ######################
my $counter = 1;

my @countries;
my @languages;
my @countryLiveCount;
my @countryTestCount;
print "\nHow many countries do you need?\n>";
my $noOfCountries = <ARGV>;
chomp($noOfCountries);
my $countrySize = @countries;
while($countrySize < $noOfCountries){
	#### get country code ####
	print "\nCurrent Values:\n@countries\nCountry code for country #$counter of $noOfCountries\n>";
	my $ccode = <ARGV>;
	chomp($ccode);
	push @countries, $ccode;
	
	#### get language code ####
	print "\nWhat language for $ccode?\n>";
	my $clang = <ARGV>;
	chomp($clang);
	push @languages, $clang;
	
	#### get number of records for country ####
	my $ccount = 0;
	### LIVE records
	if($lktyp eq 'l' or $lktyp eq 'b'){
		print "\nHow many LIVE records for \"$ccode\"?\n>";	
		my $livecount = <ARGV>;
		chomp($livecount);
        push @countryLiveCount, $livecount;
		$ccount = $ccount+$livecount;
	}
	### TEST records
	if($lktyp eq 't' or $lktyp eq 'b'){
		print "\nHow many TEST records for \"$ccode\"?\n>";	
		my $testcount = <ARGV>;
		chomp($testcount);
        push @countryTestCount, $testcount;
		$ccount = $ccount+$testcount;
	}
	
	$totalRecords = $totalRecords+$ccount;
	$countrySize = @countries;
	$counter++;
}

###################### AT THIS POINT WE SHOULD KNOW HOW MANY RECORDS WE NEED ######################
### $totalRecords

###################### SAMPLE SOURCE HANDLING ######################

print "\nPlease provide the value for column \"source\".\n>";
my $source = <ARGV>;
chomp($source);

###################### ADDITIONAL COLUMN HANDLING ######################

#### Find out how many additional columns we need ####
my @columns = ('userid','lang','country','source','lktyp','thelink');
my @colvalues;
my @newColumns = ();

print "\n@columns\n";
print "How many additional columns do we need?\n>";
my $colnum = <ARGV>;
chomp($colnum); 

my $noOfColumns = @columns;
$counter = 0;
while(@columns < ($colnum+$noOfColumns)){
	#### get name of column ####
    print "\nName additional column #$counter:";
    my $cname = <ARGV>;
    chomp($cname);
    push @columns, $cname;
    push @newColumns, $cname;
	
	#### get value for column ####
	print "\nWhat value for $cname?\n>";
	my $cvalue = <ARGV>;
	chomp($cvalue);
	push @colvalues, $cvalue;
	
    $counter++;
}


### At this point we have six arrays for file creation ###
# @countries = country codes to be used.
# @languages = language codes to be used for each country.
# @countryLiveCount = number of LIVE records for each country.
# @countryTestCount = number of TEST records for each country.
# @columns = contains the labels for each column.  
# userid, lang, country, source, lktyp, thelink, [additional cols...]
# @colvalues = values for each additional column


## let's make some IDs ##

print "\nNow that I know how many records you need, I'm going to generate IDs\n";
my @ids = makeIDs($totalRecords,$charlimit);

print "\nCreating Files\n";

$counter = 0;
my $idx = 0;
foreach(@countries){
    my $country = $_;
    my $lang = $languages[$counter];
    my $liveCount = $countryLiveCount[$counter];
    my $testCount = $countryTestCount[$counter];
    
    if($lktyp eq "l" or $lktyp eq "b"){
        open OUT1, ">$cnum\_$pnum$addtext\_$country\_LIVE.txt";
        foreach(@columns){ #print out column labels
            print OUT1 "$_\t";
        }
    }
    
    if($lktyp eq "t" or $lktyp eq "b"){
        open OUT2, ">$cnum\_$pnum$addtext\_$country\_TEST.txt";
        foreach(@columns){ #print out column labels
            print OUT2 "$_\t";
        }
    }
    
    my $idCounter = 0;
    if($lktyp eq "l" or $lktyp eq "b"){ ##live looping
        while ($idCounter < $liveCount){
            my $id = $ids[$idx];
            my $row = "\n$id\t$lang\t$country\t$source\t1\thttp://survey.confirmit.com/wix/$cnum.aspx?\_\_userid=$id&l=$lang";
            foreach(@colvalues){
                $row = $row . "\t$_";
            }
            print OUT1 $row;
            $idx++;
            $idCounter++;
        }
    }
    
    $idCounter = 0;
    if($lktyp eq "t" or $lktyp eq "b"){ ##test looping
        while ($idCounter < $testCount){
            my $id = $ids[$idx];
            my $row = "\n$id\t$lang\t$country\t$source\t99\thttp://survey.confirmit.com/wix/$cnum.aspx?\_\_userid=$id&l=$lang";
            foreach(@colvalues){
                $row = $row . "\t$_";
            }
            print OUT2 $row;
            $idx++;
            $idCounter++;
        }
    }
    
    $counter++;
}



###################### SUBROUTINES ######################

#define MakeIDs subroutine
sub makeIDs {
#passed arguments - Number of IDs, Length of ID
    my %used = ();
    open IN, "<usedIDs.txt";
    print "Reading used IDs...\n";
    while(<IN>){
	   chomp($_);
	   $used{$_} = ();
    }
    close IN;
    open OUT, ">>usedIDs.txt";
    my %uniqueIDs = ();
    my @outputIDs;
    print "Creating new IDs...\n";
    while(keys(%uniqueIDs) < $_[0]){ #loop while number of IDs is less than number requested
       my $rpattern = random_regex("[0-5]{$_[1]}"); #create a random pattern on which to base our id
	   my $pass = random_string($rpattern,["B"..."D"],["F"..."H"],["J"..."N"],["P".."R"],["V"..."Z"],[0...9]); #create the ID based on that random pattern and the acceptable characters
	   unless(exists $used{$pass}){
		  $uniqueIDs{$pass} = ();
		  $used{$pass} = ();
          push @outputIDs, $pass;
          print OUT "$pass\n";
	   }
   }
   close OUT;
   return @outputIDs;
}

exit;
###################### END OF NEW SCRIPT ######################