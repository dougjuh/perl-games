#!/usr/local/bin/dwperl

# Automate solving the "Loop" puzzle (from Android app)

use strict;

# ALL variables defined here are accessible to subroutines
my(
   %Box,
   $Across, $Down,
   $Debug, $Trace,
);

# Variables local to the main program
my(
   @raw, $puzzle,
   $loc,
   $valid, @pos,
   $changed, $cntr,
);


$puzzle = $ARGV[0];
$Trace = $ARGV[1] if $ARGV[1] =~ m/\d+/;
$Debug = $ARGV[1] if $ARGV[1] =~ m/debug/i;
unless ( $puzzle ) {
   print "Usage: $0 PUZZLE-NUMBER\n";
   exit 2;
}

# Load in from wherever into array-of-array
@raw = load_in($puzzle);

# Move raw shapes into box hash by position
assign_to_box(\@raw);

# Assign possible positions for each piece
for $loc ( keys %Box ) {
   ($valid, @pos) = setup_positions($loc, $Box{$loc}{shape});
   $Box{$loc}{num_pos} = $valid;
   @{$Box{$loc}{pos}} = @pos;
}
print_box('debug', 'ORIGINAL POSSIBLE POSITIONS OF SHAPES');


# For boxes with only one position, reduce possibilities of neighbors
$changed = reduce_one_only();
while ( $changed and $cntr <= 10 ) {
   warn "FYI - reviewed one-only positions and something changed\n";
   $cntr++;    # avoid infinite loop
   $changed = reduce_one_only();
}

print "\n";
#print_box('debug', 'RAW FINAL');
print_box('nice', 'FINAL SOLUTION');


############################################################

#-----------------------------------------------------------
# Return array-of-array of names of pieces for original layout
# 
sub load_in {
   my($set) = @_;
   my @data;

   if ( $set == 1 ) {
      push @data, [ qw( curve curve end ) ];
      push @data, [ qw( bar hill hill ) ];
      push @data, [ qw( curve four curve ) ];
      push @data, [ qw( empty curve end ) ];
   }
   if ( $set == 2 ) {
      push @data, [ qw( end empty curve curve ) ];
      push @data, [ qw( hill hill curve bar ) ];
      push @data, [ qw( hill four end bar ) ];
      push @data, [ qw( curve hill end hill ) ];
      push @data, [ qw( end curve empty end ) ];
   }
   if ( $set == 3 ) {
      push @data, [ qw( end curve curve curve bar curve end ) ];
      push @data, [ qw( bar hill four curve none hill curve ) ];
      push @data, [ qw( hill hill curve none none curve curve ) ];
      push @data, [ qw( curve bar bar bar end end curve ) ];
   }
   if ( $set == 4 ) {
      push @data, [ qw( end hill bar bar bar curve ) ];
      push @data, [ qw( curve four bar curve end hill ) ];
      push @data, [ qw( hill four bar hill curve end ) ];
      push @data, [ qw( curve hill bar curve curve curve ) ];
      push @data, [ qw( none end bar curve end bar ) ];
      push @data, [ qw( end bar hill hill curve bar ) ];
      push @data, [ qw( curve hill hill curve end hill ) ];
      push @data, [ qw( end curve curve curve hill hill ) ];
      push @data, [ qw( end end bar bar bar bar ) ];
      push @data, [ qw( end curve curve end curve curve ) ];
   }
   if ( $set == 151 ) {
      push @data, [ qw( end curve curve end bar curve ) ];
      push @data, [ qw( bar curve four bar curve bar ) ];
      push @data, [ qw( bar end curve hill hill curve ) ];
      push @data, [ qw( hill four bar hill curve empty ) ];
      push @data, [ qw( end hill hill curve end empty ) ];
      push @data, [ qw( end curve end hill curve empty ) ];
      push @data, [ qw( end end empty end curve end ) ];
   }
   if ( $set == 159 ) {
      push @data, [ qw( end end hill hill curve ) ];
      push @data, [ qw( hill bar hill four hill ) ];
      push @data, [ qw( hill bar curve hill curve ) ];
      push @data, [ qw( hill hill hill four curve ) ];
      push @data, [ qw( curve four hill hill end ) ];
      push @data, [ qw( end curve hill hill curve ) ];
      push @data, [ qw( curve bar curve hill curve ) ];
      push @data, [ qw( empty end bar hill end ) ];
   }

   return @data;

}

#-----------------------------------------------------------
# Assign array-of-array into master box hash

sub assign_to_box {
   my($raw) = @_;
   my($row, $shape, $loc);

   for $row ( @$raw ) {
      for $shape ( @$row ) {
         $loc++;
         $loc = sprintf "%02d", $loc;
         # massage shape names
         $shape = lc($shape);
         $shape = 'curv' if $shape =~ m/curve/; # so prints nicely
         $shape = 'none' if $shape =~ m/(empty|none|blank)/;
         warn "UNKNOWN SHAPE: $shape for loc=$loc\n" 
               unless $shape =~ m/(end|bar|curv|hill|four|none)/;
#warn "ASSIGN: loc=$loc = $shape\n";
         $Box{$loc}{shape} = $shape;
         # count cells across in first row only; assume input is consistent
         $Across++ unless $Down;
      }
      $Down++;
   }
}

#-----------------------------------------------------------
# Determine 1-4 possible positions for each shape
# and the locations of the sets of connectors
# Connectors are named based on the two boxes,
#   so the connector between boxes 2 and 3 is called 0203

sub setup_positions {
   my($loc, $shape) = @_;
   my($top, $bottom, $left, $right, @position, $x);

   # Determine location of boxes to the top, bottom, left, right
   if ( $loc <= $Across ) {
      $top = 0;
   } else {
      $top = sprintf "%02d", $loc - $Across;
   }
   if ( $loc > $Across * ($Down - 1) ) {
      $bottom = 0;
   } else {
      $bottom = sprintf "%02d", $loc + $Across;
   }
   if ( $loc % $Across == 1 ) {
      $left = 0;
   } else {
      $left = sprintf "%02d", $loc - 1;
   }
   if ( $loc % $Across == 0 ) {
      $right = 0;
   } else {
      $right = sprintf "%02d", $loc + 1;
   }

   # Check if neighboring box is empty
   $top = 0 if $top and ! $Box{$top}{shape};
   $bottom = 0 if $bottom and ! $Box{$bottom}{shape};
   $left = 0 if $left and ! $Box{$left}{shape};
   $right = 0 if $right and ! $Box{$right}{shape};

   # Combos of two boxes (i.e. a connector) are always 4 digits,
   # and have lower-number box first, then higher-number box
#warn "POSITIONS: loc=$loc.$shape Across=$Across T=$top R=$right B=$bottom L=$left\n";
   if ( $shape eq 'end' ) {
      push @position, _valid_conn($top);
      push @position, _valid_conn($right);
      push @position, _valid_conn($bottom);
      push @position, _valid_conn($left);
   }
   elsif ( $shape eq 'bar' ) {
      push @position, _valid_conn($top,$bottom);
      push @position, _valid_conn($left,$right);
      push @position, 0;
      push @position, 0;
   }
   elsif ( $shape eq 'curv' ) {
      push @position, _valid_conn($top,$right);
      push @position, _valid_conn($right,$bottom);
      push @position, _valid_conn($left,$bottom);
      push @position, _valid_conn($top,$left);
   }
   elsif ( $shape eq 'hill' ) {
      push @position, _valid_conn($top,$left,$right);
      push @position, _valid_conn($top,$right,$bottom);
      push @position, _valid_conn($left,$right,$bottom);
      push @position, _valid_conn($top,$left,$bottom);
   }
   elsif ( $shape eq 'four' ) {
      push @position, _valid_conn($top,$left,$right,$bottom);
      push @position, 0;
      push @position, 0; 
      push @position, 0;
   }
   elsif ( $shape eq 'none' ) {
      push @position, 0;
      push @position, 0;
      push @position, 0; 
      push @position, 0;
   }

   # Determine number of valid positions
   $valid = 0;
   for ( $x=0; $x<=3; $x++ ) {
      $valid++ if $position[$x];
   }

   return $valid, @position;
}

# Determine if set of box numbers makes a valid set of connectors
sub _valid_conn {
   my(@conn) = @_;
   my($c);
   for $c ( @conn ) {
      return 0 if $c == 0;
      return 0 if $Box{$c}{shape} eq 'none';
   }
   return join('-', @conn);
}


#-----------------------------------------------------------
# For boxes with only one position,
# reduce the possibilities of neighboring boxes

sub reduce_one_only {
   my($loc, $loc2, $p, $p2, $something_changed);
   my($conn, $linked);

   # Look at each box with one position
   for $loc ( sort keys %Box ) {

if ( $Trace =~ m/$loc/ ) {
warn "*** BEFORE: loc=$loc $Box{$loc}{shape} numpos=$Box{$loc}{num_pos} \n";
warn "            p=0 conn=$Box{$loc}{pos}[0]\n";
warn "            p=1 conn=$Box{$loc}{pos}[1]\n";
warn "            p=2 conn=$Box{$loc}{pos}[2]\n";
warn "            p=3 conn=$Box{$loc}{pos}[3]\n";
}

      # For each position
      for $p ( qw( 0 1 2 3 ) ) {
         next unless $Box{$loc}{pos}[$p];
         $conn = $Box{$loc}{pos}[$p];

         # Logic if loc has only one possible position
         if ( $Box{$loc}{num_pos} == 1 ) {
            # For each neighboring box which is linked to this position
            for $loc2 ( split(/-/, $conn) ) {
warn "LOOK: loc=$loc numpos=$Box{$loc}{num_pos} conn=$conn loc2=$loc2 \n" 
if $Debug or $Trace =~ m/($loc|$loc2)/;
               for $p2 ( qw( 0 1 2 3 ) ) {
                  # Skip position if empty
                  next unless $Box{$loc2}{pos}[$p2];
warn "     p2=$p2  $Box{$loc2}{pos}[$p2]\n" if $Debug or $Trace =~ m/($loc|$loc2)/;
                  # Keep this box2's position p2 since linked to original box
                  next if $Box{$loc2}{pos}[$p2] =~ $loc;
                  # This possible position of a neighbor is now invalid
warn "REMOVED: loc2=$loc2 pos $p2 = $Box{$loc2}{pos}[$p2]\n"
if $Debug or $Trace =~ m/($loc|$loc2)/;
                  $Box{$loc2}{pos}[$p2] = 0;
                  $Box{$loc2}{num_pos}--;
                  $something_changed++;
               }
            }
         } # end num-pos = 1
         else {
            # For each neighboring box which is linked to this position
            for $loc2 ( split(/-/, $conn) ) {
warn "LOOK2: loc=$loc numpos=$Box{$loc}{num_pos} p=$p conn=$conn loc2=$loc2 \n" 
if $Debug or $Trace =~ m/($loc|$loc2)/;
               $linked = 'no';
               for $p2 ( qw( 0 1 2 3 ) ) {
                  $linked = 'yes' if $Box{$loc2}{pos}[$p2] =~ $loc;
               }
               # If neighbor does not link to me, then drop my link to him
               if ( $linked eq 'no' and $Box{$loc}{pos}[$p] ) {
warn "REMOVED2: loc=$loc pos $p=$Box{$loc}{pos}[$p] since loc2=$loc2 not link back\n"
if $Debug or $Trace =~ m/($loc|$loc2)/;
                  $Box{$loc}{pos}[$p] = 0;
                  $Box{$loc}{num_pos}--;
                  $something_changed++;
               }
            }
         } # end num-pos not 1
      }
   }
   return $something_changed;
}


#-----------------------------------------------------------
# Print shapes and info
# Marks are assigned to array as ( '', top-left, top, top-right, etc)

sub print_box {
   my($style, $title) = @_;
   print "$title\n";
   _print_box_debug() if $style eq 'debug';
   _print_box_nice() if $style eq 'nice';
}

#---------------------------------------
sub _print_box_debug {
   my($x, $y, $loc, @out1, @out2, @out2b, @out3);
   # possible characters to mark positions
   # (top row, middle row, bottom row)
   my @char = qw( '' / | \ - - \ | / );
   my(@mark);

   my $fmt1 = "  %1s   %1s   %1s   ";    # top and bottom row
   my $fmt2 = "  %1s%2d.%-4s%1s   ";   # center row
   my $fmt2b = " %s";   # debug row

   for ( $y = 1; $y <= $Down; $y++ ) {
      @out1 = @out2 = @out2b = @out3 = ();
      for ( $x = 1; $x <= $Across; $x++ ) {
         $loc++;
         $loc = sprintf "%02d", $loc;
         @mark = ();
#warn "MARKS: loc=$loc.$Box{$loc}{shape} POS=", join('; ', @{$Box{$loc}{pos}}), "\n"
   #if defined(@{$Box{$loc}{pos}});

         # Determine which marks get set for this shape and possibilities
         if ( $Box{$loc}{shape} eq 'end' ) {
            $mark[2] = $char[2] if $Box{$loc}{pos}[0];
            $mark[5] = $char[5] if $Box{$loc}{pos}[1];
            $mark[7] = $char[7] if $Box{$loc}{pos}[2];
            $mark[4] = $char[4] if $Box{$loc}{pos}[3];
         }
         elsif ( $Box{$loc}{shape} eq 'bar' ) {
            $mark[2] = $char[2] if $Box{$loc}{pos}[0];
            $mark[7] = $char[7] if $Box{$loc}{pos}[0];
            $mark[5] = $char[5] if $Box{$loc}{pos}[1];
            $mark[4] = $char[4] if $Box{$loc}{pos}[1];
         }
         elsif ( $Box{$loc}{shape} eq 'curv' ) {
            $mark[3] = $char[3] if $Box{$loc}{pos}[0];
            $mark[8] = $char[8] if $Box{$loc}{pos}[1];
            $mark[6] = $char[6] if $Box{$loc}{pos}[2];
            $mark[1] = $char[1] if $Box{$loc}{pos}[3];
         }
         elsif ( $Box{$loc}{shape} eq 'hill' ) {
            $mark[1] = $char[1] if $Box{$loc}{pos}[0];
            $mark[3] = $char[3] if $Box{$loc}{pos}[0];
            $mark[3] = $char[3] if $Box{$loc}{pos}[1];
            $mark[8] = $char[8] if $Box{$loc}{pos}[1];
            $mark[8] = $char[8] if $Box{$loc}{pos}[2];
            $mark[6] = $char[6] if $Box{$loc}{pos}[2];
            $mark[6] = $char[6] if $Box{$loc}{pos}[3];
            $mark[1] = $char[1] if $Box{$loc}{pos}[3];
         }
         elsif ( $Box{$loc}{shape} eq 'four' ) {
            $mark[2] = $char[2] if $Box{$loc}{pos}[0];
            $mark[5] = $char[5] if $Box{$loc}{pos}[0];
            $mark[7] = $char[7] if $Box{$loc}{pos}[0];
            $mark[4] = $char[4] if $Box{$loc}{pos}[0];
         }
         elsif ( $Box{$loc}{shape} eq 'none' ) {
            # do nothing
         }

         push @out1, sprintf $fmt1, $mark[1], $mark[2], $mark[3];
         push @out2, sprintf $fmt2, $mark[4], $loc, $Box{$loc}{shape}, $mark[5];
         push @out2b, sprintf $fmt2b, join(';', @{$Box{$loc}{pos}});
         push @out3, sprintf $fmt1, $mark[6], $mark[7], $mark[8];
      }

      print join('', @out1)."\n";
      print join('', @out2)."\n";
      #print join('', @out2b)."\n";
      print join('', @out3)."\n";
      print "\n";
   }

}


#---------------------------------------
sub _print_box_nice {
   my($x, $y, $loc, $shape, $p, $i );
   my @wrong;  # list of locations with multiple positions
   my @out;  # array with 5 elements for each mini-line in a row across board

   # holds all possible printable shapes as 5x5 characters
   my %char = _define_chars();

   # Loop thru each row of boxes
   for ( $y = 1; $y <= $Down; $y++ ) {
      @out = ();
      # Loop thru each box in a row
      for ( $x = 1; $x <= $Across; $x++ ) {
         $loc++;
         $loc = sprintf "%02d", $loc;
         $shape = $Box{$loc}{shape};
         # Look for box with 2+ positions
         push @wrong, $loc if $Box{$loc}{num_pos} > 1;
         push @wrong, $loc if $Box{$loc}{num_pos} = 0 
                          and $Box{$loc}{shape} ne 'none';
#warn "WRONG: loc=$loc numpos=$Box{$loc}{num_pos} \n";

         # Loop thru each position to find the one being used
         for ( $p = 0; $p <= 3; $p++ ) {
            if ( $Box{$loc}{pos}[$p] or ( $shape eq 'none' and $p == 0 ) ) {
               # Loop thru each printable 5-lines of a shape
               for ( $i = 0; $i <= 4; $i++ ) {
                  push @{$out[$i]}, $char{$shape}[$p][$i];
               }
            } # end valid pos
         }
      } # end $x
      print join('', @{$out[0]}), "\n";
      print join('', @{$out[1]}), "\n";
      print join('', @{$out[2]}), "\n";
      print join('', @{$out[3]}), "\n";
      print join('', @{$out[4]}), "\n";
   }
   if ( @wrong ) {
      print "Um, these box locations have multiple solutions:\n";
      print join(', ', @wrong)."\n";
   }
}

# Define each nice printable shape
sub _define_chars {
   my %char;
   # char{shape}[pos][subline] = '     ' # string length 5

   $char{end}[0][0] = '  |  ';
   $char{end}[0][1] = '  |  ';
   $char{end}[0][2] = '  O  ';
   $char{end}[0][3] = '     ';
   $char{end}[0][4] = '     ';
   $char{end}[1][0] = '     ';
   $char{end}[1][1] = '     ';
   $char{end}[1][2] = '  O--';
   $char{end}[1][3] = '     ';
   $char{end}[1][4] = '     ';
   $char{end}[2][0] = '     ';
   $char{end}[2][1] = '     ';
   $char{end}[2][2] = '  O  ';
   $char{end}[2][3] = '  |  ';
   $char{end}[2][4] = '  |  ';
   $char{end}[3][0] = '     ';
   $char{end}[3][1] = '     ';
   $char{end}[3][2] = '--O  ';
   $char{end}[3][3] = '     ';
   $char{end}[3][4] = '     ';

   $char{bar}[0][0] = '  |  ';
   $char{bar}[0][1] = '  |  ';
   $char{bar}[0][2] = '  |  ';
   $char{bar}[0][3] = '  |  ';
   $char{bar}[0][4] = '  |  ';
   $char{bar}[1][0] = '     ';
   $char{bar}[1][1] = '     ';
   $char{bar}[1][2] = '-----';
   $char{bar}[1][3] = '     ';
   $char{bar}[1][4] = '     ';

   $char{curv}[0][0] = '  |  ';
   $char{curv}[0][1] = '   \ ';
   $char{curv}[0][2] = '    -';
   $char{curv}[0][3] = '     ';
   $char{curv}[0][4] = '     ';
   $char{curv}[1][0] = '     ';
   $char{curv}[1][1] = '     ';
   $char{curv}[1][2] = '    -';
   $char{curv}[1][3] = '   / ';
   $char{curv}[1][4] = '  |  ';
   $char{curv}[2][0] = '     ';
   $char{curv}[2][1] = '     ';
   $char{curv}[2][2] = '-    ';
   $char{curv}[2][3] = ' \   ';
   $char{curv}[2][4] = '  |  ';
   $char{curv}[3][0] = '  |  ';
   $char{curv}[3][1] = ' /   ';
   $char{curv}[3][2] = '-    ';
   $char{curv}[3][3] = '     ';
   $char{curv}[3][4] = '     ';

   $char{hill}[0][0] = '  |  ';
   $char{hill}[0][1] = ' / \ ';
   $char{hill}[0][2] = '-   -';
   $char{hill}[0][3] = '     ';
   $char{hill}[0][4] = '     ';
   $char{hill}[1][0] = '  |  ';
   $char{hill}[1][1] = '   \ ';
   $char{hill}[1][2] = '    -';
   $char{hill}[1][3] = '   / ';
   $char{hill}[1][4] = '  |  ';
   $char{hill}[2][0] = '     ';
   $char{hill}[2][1] = '     ';
   $char{hill}[2][2] = '-   -';
   $char{hill}[2][3] = ' \ / ';
   $char{hill}[2][4] = '  |  ';
   $char{hill}[3][0] = '  |  ';
   $char{hill}[3][1] = ' /   ';
   $char{hill}[3][2] = '-    ';
   $char{hill}[3][3] = ' \   ';
   $char{hill}[3][4] = '  |  ';

   $char{four}[0][0] = '  |  ';
   $char{four}[0][1] = ' / \ ';
   $char{four}[0][2] = '-   -';
   $char{four}[0][3] = ' \ / ';
   $char{four}[0][4] = '  |  ';

   $char{none}[0][0] = '     ';
   $char{none}[0][1] = '     ';
   $char{none}[0][2] = '     ';
   $char{none}[0][3] = '     ';
   $char{none}[0][4] = '     ';

   return %char;
}


