#!/bin/perl
#
# Doug Juhlin - Sudoku solver


use strict;

my(
   
   %answer,
   %box_cells,    # hash of array of array; (row,col) locations for a box's cells
   %find,         # tally of entries found by rule
   $debug,
   $found,        # flag indicates something found
   $found2,       # flag indicates something found -- outer loop
   %got_pair,     # (box)(key) record pairs found
   %got_twin,     # (box)(num) record twins found
   @input,        # input numbers
   %possible,
   $show_finds,   # flag to print/suppress tally of finds per method
   $show_moves,   # flag to print/suppress major changes
   %wh_box,       # find box number given row/col
);

# Options
$debug = 1;
$show_finds = 1;     # tally of which rules were used
$show_moves = 1;     # show each change


#-----------------------------------------------------------
# Initialization
#-----------------------------------------------------------

# Given a row/col, decide which box it belongs to
for my $x ( 1, 2, 3 ) {
   $wh_box{$x}{1} = $wh_box{$x}{2} = $wh_box{$x}{3} = 1;
   $wh_box{$x}{4} = $wh_box{$x}{5} = $wh_box{$x}{6} = 2;
   $wh_box{$x}{7} = $wh_box{$x}{8} = $wh_box{$x}{9} = 3;
}
for my $x ( 4, 5, 6 ) {
   $wh_box{$x}{1} = $wh_box{$x}{2} = $wh_box{$x}{3} = 4;
   $wh_box{$x}{4} = $wh_box{$x}{5} = $wh_box{$x}{6} = 5;
   $wh_box{$x}{7} = $wh_box{$x}{8} = $wh_box{$x}{9} = 6;
}
for my $x ( 7, 8, 9 ) {
   $wh_box{$x}{1} = $wh_box{$x}{2} = $wh_box{$x}{3} = 7;
   $wh_box{$x}{4} = $wh_box{$x}{5} = $wh_box{$x}{6} = 8;
   $wh_box{$x}{7} = $wh_box{$x}{8} = $wh_box{$x}{9} = 9;
}

# row/col for each cell within each box
%box_cells = (
   1 => [ [1,1], [1,2], [1,3], [2,1], [2,2], [2,3], [3,1], [3,2], [3,3] ],
   2 => [ [1,4], [1,5], [1,6], [2,4], [2,5], [2,6], [3,4], [3,5], [3,6] ],
   3 => [ [1,7], [1,8], [1,9], [2,7], [2,8], [2,9], [3,7], [3,8], [3,9] ],
   4 => [ [4,1], [4,2], [4,3], [5,1], [5,2], [5,3], [6,1], [6,2], [6,3] ],
   5 => [ [4,4], [4,5], [4,6], [5,4], [5,5], [5,6], [6,4], [6,5], [6,6] ],
   6 => [ [4,7], [4,8], [4,9], [5,7], [5,8], [5,9], [6,7], [6,8], [6,9] ],
   7 => [ [7,1], [7,2], [7,3], [8,1], [8,2], [8,3], [9,1], [9,2], [9,3] ],
   8 => [ [7,4], [7,5], [7,6], [8,4], [8,5], [8,6], [9,4], [9,5], [9,6] ],
   9 => [ [7,7], [7,8], [7,9], [8,7], [8,8], [8,9], [9,7], [9,8], [9,9] ],
);



#-----------------------------------------------------------
# Main loop
#-----------------------------------------------------------

if ( $ARGV[0] ) {
   @input = get_puzzle($ARGV[0]);
} else {
   @input = get_puzzle('manual');
}
init_possible();
get_input();
print_grid('Input Grid');


$found2 = 1;
while ( $found2 ) {
   $found2 = 0;
   $found = 1;
   while ( $found ) {
      $found = 0;
      $found = $found + check_cells();
      $found = $found + check_rows();
      $found = $found + check_cols();
      $found = $found + check_boxes();
   }
   print_possible('Just before check for twins');
   $found2 = $found2 + check_twins();
   print_possible('Just before check for pairs');
   $found2 = $found2 + check_pairs();
}

print_possible();

print_grid('Final Grid');
print_find() if $show_finds;

exit;


################################################################
################################################################
# Subroutines
################################################################
################################################################

#
# Within each box, for each number 1-9, 
#  if the number is possible only once in the box, then set it.
#
sub check_boxes {
   my($box, $ref, $num, $found, $cnt_poss, $only_row, $only_col);
   for $box (1..9) {
      for $num (1..9) {
      $cnt_poss = 0;
         for $ref ( @{$box_cells{$box}} ) {
            if ( $possible{$ref->[0]}{$ref->[1]}{$num} ) {
               $only_row = $ref->[0];
               $only_col = $ref->[1];
               $cnt_poss++;
            }
         }
         if ( $cnt_poss == 1 ) {
            set_value($only_row, $only_col, $num, 'check_boxes');
            $found++;
            $find{box}++;
         }
      }
   }
   return $found;
}

#
# For each cell, if there is only one possible number, then set it.
# 
sub check_cells {
   my($row, $col, $num, $found, $cnt_poss, $only_poss);
   for $row (1..9) {
      for $col (1..9) {
         $cnt_poss = 0;
         for $num ( 1 .. 9 ) {
            if ( $possible{$row}{$col}{$num} ) {
               $only_poss = $num;
               $cnt_poss++;
            }
         }
         if ( $cnt_poss == 1 ) {
            set_value($row, $col, $only_poss, 'check_cells');
            $found++;
            $find{cell}++;
         }
      }
   }
   return $found;
}

#
# Determine if a number is possible only once in a columnumn
#
sub check_cols {
   my($row, $col, $num, $found, $cnt_poss, $only_row);
   for $col (1..9) {
      for $num (1..9) {
         $cnt_poss = 0;
         for $row (1..9) {
            if ( $possible{$row}{$col}{$num} ) {
               $only_row = $row;
               $cnt_poss++;
            }
         }
         if ( $cnt_poss == 1 ) {
            set_value($only_row, $col, $num, 'check_cols');
            $found++;
            $find{col}++;
         }
      }
   }
   return $found;
}

#
# Determine if a number is possible only once in a row
#
sub check_rows {
   my($row, $col, $num, $found, $cnt_poss, $only_col);
   for $row (1..9) {
      for $num (1..9) {
         $cnt_poss = 0;
         for $col (1..9) {
            if ( $possible{$row}{$col}{$num} ) {
               $only_col = $col;
               $cnt_poss++;
            }
         }
         if ( $cnt_poss == 1 ) {
            set_value($row, $only_col, $num, 'check_rows');
            $found++;
            $find{row}++;
         }
      }
   }
   return $found;
}


#
# Look for twins in a box, so can remove a number from the entire row/col
#
sub check_twins {
   my($box, $num, $twrow, $twcol, $twcount, $RR, $CC, $ref, $tmp, $found);
   $found = 0;
   for $box (1..9) {
      for $num (1..9) {
         next if $got_twin{$box}{$num};
         $twrow = $twcol = $twcount = 0;
         for $ref ( @{$box_cells{$box}} ) {
            $RR = $ref->[0];
            $CC = $ref->[1];
            if ( $possible{$RR}{$CC}{$num} ) {
               if ( $twcount == 0 ) {  # first possible cell for the number
                  $twrow = $RR;
                  $twcol = $CC;
               }
               if ( $twrow != $RR ) {
                  $twrow = 0;
               }
               if ( $twcol != $CC ) {
                  $twcol = 0;
               }
               $twcount++;
            }
         }
         # Examine results of tally of possible locations for a number
         if ( $twrow > 0 and $twcount > 1 ) {
            # Found a twin - clear the row of possible num, except in this box
            if ( $show_moves ) {
               print "twin - num=$num in box=$box ";
               print "going across\n" if $twrow;
               print "going down\n" if $twcol;
            }
            $got_twin{$box}{$num} = 1;
            $found++;
            $find{twin}++;
            for $tmp (1..9) {
               if ( $wh_box{$twrow}{$tmp} != $box ) {
                  $possible{$twrow}{$tmp}{$num} = 0;
               }
            }
         }
         if ( $twcol > 0 and $twcount > 1 ) {
            # Found a twin - clear the col of possible num, except in this box
            if ( $show_moves ) {
               print "twin - num=$num in box=$box ";
               print "going across\n" if $twrow;
               print "going down\n" if $twcol;
            }
            $got_twin{$box}{$num} = 1;
            $found++;
            $find{twin}++;
            for $tmp (1..9) {
               if ( $wh_box{$tmp}{$twcol} != $box ) {
                  $possible{$tmp}{$twcol}{$num} = 0;
               }
            }
         }
      }
   }
   return $found;
}


#
# Check for pairs 
#
sub check_pairs {
   my($row, $col, $xx, $yy, $nn, $key, $tmp, $tmpnum, $found);
   my(%have_key);
   $found = 0;

   # Check rows 
   for $row (1..9) {
      %have_key = ();
      for $col (1..9) {
         next if $got_pair{$row}{$col};
         # Determine list of possible values for this cell
         $key = '';
         for $nn (1..9) {
            $key .= $nn if $possible{$row}{$col}{$nn};
         }
         next if ! $key or length($key) != 2;

         # Check each cell in a row
         if ( $have_key{$key} ) {  # found a second pair
            # Have a pair in this row
            if ( $show_moves ) {
               print "pairs - in row $row at col $col and $have_key{$key}\n";
            }
            $got_pair{$row}{$col} = 1;
            $found++;
            $find{pair}++;
            for $tmp (1..9) {
               next if $tmp == $have_key{$key};  # loc of first pair
               next if $tmp == $col;                  # loc of second pair
               for $tmpnum ( (split('', $key)) ) {   # for each num in pair
                  $possible{$row}{$tmp}{$tmpnum} = 0;
               }
            }
         } else {
            $have_key{$key} = $col;  # location of one pair
         }
      }
   }

   # Check columns 
   for $col (1..9) {
      %have_key = ();
      for $row (1..9) {
         next if $got_pair{$row}{$col};
         # Determine list of possible values for this cell
         $key = '';
         for $nn (1..9) {
            $key .= $nn if $possible{$row}{$col}{$nn};
         }
         next if ! $key or length($key) != 2;
         # Check each cell in a column
         if ( $have_key{$key} ) {  # found a second pair
            # Have a pair in this column
            if ( $show_moves ) {
               print "pairs - in col $col at row $row and $have_key{$key}\n";
            }
            $got_pair{$row}{$col} = 1;
            $found++;
            $find{pair}++;
            for $tmp (1..9) {
               next if $tmp == $have_key{$key};  # loc of first pair
               next if $tmp == $row;                 # loc of second pair
               for $tmpnum ( (split('', $key)) ) {   # for each num in pair
                  $possible{$tmp}{$col}{$tmpnum} = 0;
               }
            }
         } else {
            $have_key{$key} = $row;  # location of one pair
         }
      }
   }

   # Check boxes

   ### YET TO DO


   return $found;
}




################################################################
# Non-rule subroutines
################################################################

#
# Take values from general @input structure and assign them to answer grid.
#
sub get_input {
   my($row, $col, $num);
   for $row ( 1 .. 9 ) {
      for $col ( 1 .. 9 ) {
         $num = shift @input;
         if ( $num == 0 ) {
            $answer{$row}{$col} = '';
         } else {
            set_value($row, $col, $num, '');
         }
      }
   }
}

#
# Initialize all possible values for each cell.
#
sub init_possible {
   my($row, $col, $num);
   for $row ( 1 .. 9 ) {
      for $col ( 1 .. 9 ) {
         for $num ( 1 .. 9 ) {
            $possible{$row}{$col}{$num} = 1;
         }
      }
   }
}


#
# Print tally of finds by method.
#
sub print_find {
   my($xx);
   for $xx ( sort keys %find ) {
      printf "Method %5s found %2d\n", $xx, $find{$xx};
   }
}

#
# Print the answers in a grid.
#
sub print_grid {
   my($title) = @_;
   my($row, $col, $num);
   print "\n";
   print "$title\n" if $title;
   for $row ( 1 .. 9 ) {
      for $col ( 1 .. 9 ) {
         $num = $answer{$row}{$col};
         $num = ' ' if ! $num;
         print "$num ";
         print "| " if $col == 3 or $col == 6;
      }
      print "\n";
      if ( $row == 3 or $row == 6 ) {
         print '------+-------+------'."\n";
      }
   }
   print "\n";
}

#
# Prints all possible values in a grid.
# The first parameter is an optional title.
#
sub print_possible {
   my($row, $col, $num, $poss);
   my($title) = @_;

   print "\n";
   print "Possible Moves    $title\n";
   for $row (1..9) {
      for $col (1..9) {
         $poss = '';
         for $num (1..9) {
            $poss .= "$num" if $possible{$row}{$col}{$num};
         }
         printf "%-6s", $poss;
         print "| " if $col == 3 or $col == 6;
      }
      print "\n";
      if ( $row == 3 or $row == 6 ) {
      print '------------------+-------------------+-------------------'."\n";
      }
   }
   print "\n";
}


#
# Assign a value to a specific row/column;
#   remove the value from related possible cells.
# Optionally increment tally indicating which rule triggered this assignment.
# Parameters:  (row, column, value, "rule name")
#
sub set_value {
   my($xx, $boxnum, $ref);
   my($row, $col, $num, $method) = @_;

   print "$method - set row=$row col=$col num=$num\n" 
            if $show_moves and $method;

   # Set answer
   $answer{$row}{$col} = $num;

   # Clear possible number from cells in rows and columns
   for $xx ( 1 .. 9 ) {
      $possible{$row}{$xx}{$num} = 0;
      $possible{$xx}{$col}{$num} = 0;
   }
   # Clear possible number from cells in box
   $boxnum = $wh_box{$row}{$col};
   for $ref ( @{$box_cells{$boxnum}} ) {
      $possible{$ref->[0]}{$ref->[1]}{$num} = 0;
   }
   # Clear all possible numbers for this cell
   for $xx ( 1 .. 9 ) {
      $possible{$row}{$col}{$xx} = 0;
   }

}

#
# Input a puzzle from the operator or from a file.
# Assign to a generic @input structure.
#
sub get_puzzle {
   my $pnum = shift @_;
   my(@raw, @input, $xx, $aline, $afile);

   if ( $pnum =~ m/manual/i ) {
      print "\n\n";
      print "Enter nine lines each with nine digits or spaces\n";
      print "Use zero or space to indicate an empty cell\n";
      print "Save data in file (optional): ";
      $afile = <STDIN>;
      chomp($afile);
      if ( $afile ) {
         open(DATA, ">sudata.$afile") or die "Cannot save file sudata.$afile";
         $pnum = $afile;
      }
      for $xx (1..9) {
         $aline = <STDIN>;
         chomp($aline);
         $aline = substr($aline,0,9);
         push @raw, $aline;
         print DATA "$aline\n" if $afile;
      }
      close DATA if $afile;
   }

   if ( $pnum =~ m/[a-z]/i ) {
      if ( $pnum =~ m/file/i ) {
         print "\n\n";
         print "Enter file name with data: ";
         $afile = <STDIN>;
         chomp($afile);
      } else {
         $afile = $pnum;
      }
      open(DATA, "<sudata.$afile") or die "Cannot open file sudata.$afile";
      for $xx (1..9) {
         $aline = <DATA>;
         $aline = substr($aline,0,9);
         push @raw, $aline;
      }
   }

   if ( $pnum == 1 ) {
      @input =     qw( 1 0 0 0 0 0 0 0 9 );
      push @input, qw( 6 7 5 0 0 8 0 3 0 );
      push @input, qw( 0 0 0 3 6 0 8 0 0 );
      push @input, qw( 0 0 0 0 1 0 0 0 8 );
      push @input, qw( 0 3 7 0 0 0 4 5 0 );
      push @input, qw( 2 0 0 0 3 0 0 0 0 );
      push @input, qw( 0 0 1 0 7 3 0 0 0 );
      push @input, qw( 0 2 0 4 0 0 9 7 5 );
      push @input, qw( 7 0 0 0 0 0 0 0 3 );
   }

   if ( $pnum == 2 ) {
      @raw =     '060090400';
      push @raw, '000007080';
      push @raw, '000260100';
      push @raw, '020000005';
      push @raw, '907504208';
      push @raw, '400000030';
      push @raw, '005081000';
      push @raw, '040300000';
      push @raw, '001020070';
   }

   if ( ! @input ) {
   for $xx (@raw) {
      push @input, split('', $xx);
   }
   }
   return @input;
}

