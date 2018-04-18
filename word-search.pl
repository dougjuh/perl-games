#!/usr/bin/perl


#----------------------------------------------------------
# Docs and help
#----------------------------------------------------------



use strict;
use Getopt::Long;
my %opt;
GetOptions( \%opt, qw( size=i easy hard debug final ) );

my(
   $aword,     # temp word
   $cell,
   %cnt,       # tally of various stats
   $debug,
   $dir,       # direction 0-8
   @dirword,   # word for direction
   $dirx,      # x-component of direction
   $diry,      # y-component of direction
   @dropped,   # array of dropped words and reasons
   @final_words, # final word list to print
   @grid,      # array by x,y of final letters
   $hardness,  # option for easy/hard level
   $have_blank,
   $i,
   $it_fits,
   %letters_used,  # keep track of letters used in solution
   $max_x,     # maximum size in x direction
   $max_y,     # maximum size in y direction
   $min_len,   # minimum length allowed
   %original,  # hash by word of original word
   %words,     # hash by word of length
   %wstats,    # statistics per word (for testing)
   $x,
   $y,
);


# Hard-coded parameters
$min_len = 3;
$max_x = $opt{size} || 12;  # start counting from 1
$max_y = $opt{size} || 12;
if ( $opt{easy} ) {
   $hardness = 1;
} else {
   $hardness = 2;
}
$debug = $opt{debug};

@dirword = qw( down-left down down-right left x right up-left up up-right);

#----------------------------------------------------------
# Load list into memory
#----------------------------------------------------------
open INP, "words.txt" or die "Cannot open input file";
while (<INP>) {
   chomp();
   $aword = $_;
   $aword =~ s/[^a-zA-Z]//g;  # Remove all non-alpha chars
   next if ! $aword;
   $aword = lc($aword);
   if ( length($aword) < $min_len ) {
      warn "WARN: $_ is too short\n" if $debug;
      push @dropped, "$_ is too short" if $debug;
      next;
   }
   if ( length($aword) > $max_x or length($aword) > $max_y ) {
      warn "WARN: $_ is too long\n" if $debug;
      push @dropped, "$_ is too long" if $debug;
      next;
   }
   $original{$aword} = "$_";
   $words{$aword} = length($aword);
   $cnt{input}++;

}
close INP;


#----------------------------------------------------------
# Sort words by length descending
# Try to place each word
#----------------------------------------------------------
for $aword ( sort { $words{$b} <=> $words{$a} } keys %words ) {
   print "$aword $words{$aword}\n" if $debug;

   # Get valid location for the word
   ($x, $y, $dirx, $diry, $dir) = get_start_point($aword, $words{$aword});
   print "   Place in x=$x y=$y dirx=$dirx diry=$diry $dirword[$dir]\n" 
         if $debug;

   # Did not fit, so skip the word
   if ( ! $x and ! $y ) {
      push @dropped, $aword;
      next;
   }

   # Word fits, so store it in grid
   for ($i=0; $i<$words{$aword}; $i++) {
      $grid[$x + $dirx * $i][$y + $diry * $i] = substr($aword, $i, 1);
      $letters_used{substr($aword, $i, 1)} = 1;
   }
   # Put word on list
   push @final_words, $aword;
   # Gather stats
   $wstats{$aword}{len} = $words{$aword};
   $wstats{$aword}{dir} = $dir;
   $cnt{use}++;
   $cnt{dir}{$dir}++;
   print_results('grid') if $debug;
}

fill_empty();
print_results('final');



####################################################################
# Subroutines
####################################################################

#------------------------------------------------------------
# Get position and direction for one word
#------------------------------------------------------------
sub get_start_point {
   my($aword, $length) = @_;
   my($x, $y, $dir);
   my(@possible, $pick, $overlap, $curr_overlap);

#print "INSIDE hardness=$hardness maxx=$max_x maxy=$max_y\n";

   # Look at every possible location and direction
   for ( $x=1; $x<=$max_x; $x++) {
      for ( $y=1; $y<=$max_y; $y++) {
         # If starting cell has wrong letter, then skip trying directions
         next if $grid[$x][$y] and $grid[$x][$y] ne substr($aword,0,1);
         # Try all directions
         for ( $dir=0; $dir<=8; $dir++) {
            next if $dir == 4;
            # if Easy, only allow left, down, down-left-diag
            next if $hardness == 1 and $dir !~ m/[125]/;

            # Convert direction digit into x/y movements
            $dirx = $dir % 3 - 1;  # -1, 0, 1
            $diry = int($dir / 3) - 1;  # -1, 0, 1

            # Reject if word length does not fit inside grid dimensions
            next if $dirx and ( $x - 1 + $dirx * $length < 1
                           or $x - 1 + $dirx * $length > $max_x );
            next if $diry and ( $y - 1 + $diry * $length < 1
                           or $y - 1 + $diry * $length > $max_y );

#print "   Try fitting x=$x y=$y DIR=$dir dirx=$dirx diry=$diry\n";
            # Does each letter fit in the existing grid?
            $it_fits = 1;
            $overlap = 0;
            FITTING: for ($i=0; $i<$length; $i++) {
               $cell = $grid[$x + $dirx * $i][$y + $diry * $i];
#print "  grid has: $cell in x=$x y=$y i=$i word=".substr($aword,$i,1)."\n"
#if $cnt{use} > 8;
               if ( $cell eq '' ) {
                  $have_blank = 1;
               } elsif ( $cell eq substr($aword, $i, 1) ) {
                  $overlap++;
               } else {
                  $it_fits = 0;
                  last FITTING;
               }
            }

            # If word fits and there is also a blank in the grid
            if ( $it_fits and $have_blank ) {
               # Ignore low-overlap words
               if ( $overlap > $curr_overlap ) {
                  @possible = ();
                  $curr_overlap = $overlap;
print "   Possible Fits=$it_fits x=$x y=$y dirx=$dirx diry=$diry ".
      "DIR=$dir $dirword[$dir]\n" if $debug;
                  push @possible, [ $x, $y, $dirx, $diry, $dir];
                  if ( $dir =~ m/[02368]/ ) { # extra chance diagonal+left
                     push @possible, [ $x, $y, $dirx, $diry, $dir];
                  }
               
               } elsif ( $overlap == $curr_overlap ) {
print "   Possible Fits=$it_fits x=$x y=$y dirx=$dirx diry=$diry ".
      "DIR=$dir $dirword[$dir]\n" if $debug;
                  push @possible, [ $x, $y, $dirx, $diry, $dir];
                  if ( $dir =~ m/[02368]/ ) { # extra chance diagonal+left
                     push @possible, [ $x, $y, $dirx, $diry, $dir];
                  }
               }
            }
         }
      }
   }

   # Now find random entry among the possibilities
   $pick = int(rand $#possible);  # from 0 to length of @possible
   if ( $#possible >= 0 ) {
      return @{$possible[$pick]};
   } else {
      return ();
   }
}


#------------------------------------------------------------
# Fill empty cells
#------------------------------------------------------------
sub fill_empty {

   my($fill_list);
   if ( $hardness == 1 ) {
      # easy mode; use any letter
      $fill_list = 'abcdefghijklmnopqrstuvwxyz';
   } else {
      # hard mode; only use letters already in the grid
      $fill_list = join('', sort keys %letters_used);
   }
   my $fill_length = length($fill_list);
   my $rnd;

   for ( $x=1; $x<=$max_x; $x++) {
      for ( $y=1; $y<=$max_y; $y++) {
         if ( ! $grid[$x][$y] ) {
            $rnd = int(rand $fill_length);
            $grid[$x][$y] = substr($fill_list, $rnd, 1);
         }
      }
   }
}


#------------------------------------------------------------
# Draw final grid and words
#------------------------------------------------------------
sub print_results {
   my($version) = @_;
   my($horz, $vert);

   # Print debug summary stats and dropped words 
   if ( $debug and $version eq 'final' ) {
      print "\n";
      print "STATISTICS:\n";
      printf "Fit=%3d\% \n", ($cnt{use} / $cnt{input}) * 100,
      print "Tally by direction:\n";
      for $dir ( sort keys %{ $cnt{dir} } ) {
         printf "   tally=%2d  dir=%1d %1s\n", 
                $cnt{dir}{$dir}, $dir, $dirword[$dir];
      }
   }

   # Print just dropped words
   if ( $version eq 'final' ) {
      print "Dropped words:\n";
      for $aword ( sort @dropped ) {
         print "$aword\n";
      }
   }

   # Print grid
   print "\n";
   if ( $version eq 'grid' ) {
      $horz = '  ';
      $vert = "\n";
   } else {
      print "\n";    # extra line before start
      $horz = '    ';
      $vert = "\n\n";
   }
      for ( $y=1; $y<=$max_y; $y++) {
         for ( $x=1; $x<=$max_x; $x++) {
            if ( $grid[$x][$y] ) {
               print "$grid[$x][$y]$horz";
            } else {
               print ".$horz";
            }
         }
         print "$vert";
      }
   #}

   # Print word list
   if ( $version eq 'final' ) {
      print "\n";
      print "WORD LIST:\n";
      for $aword ( sort @final_words ) {
          #if ( $debug ) {
            #printf "%-15s  Len=%2d  Dir=%1d %1s\n", 
                     #$original{$aword}, 
                     #$wstats{$aword}{len}, $wstats{$aword}{dir},
                     #$dirword[$wstats{$aword}{dir}];
         #} else {
            print "  $original{$aword}\n";
         #}
      }
   }


}



