#!/usr/local/bin/perl

use strict;

my(@cat, @fact);     # entered by user
my %itmnum;          # hash by item word of internal item-number
my %item_cat_num;    # hash by item word of category number
my @truth;           # array by item-num by item-num of truth
my($num );


# Get info from user
enter_info();

# Process input value
my $numcat = scalar(@cat);
my $numitem = scalar(@{$cat[0]});
print "numcat=$numcat  numitem=$numitem\n";

init_items();
#init_cats();

for $num ( @fact ) {
   add_fact($num->[0], $num->[1], $num->[2]);
}

print_grid();




#########################################################
# Subroutines
#########################################################

#----------------------------------------------------------
# Enter info from user
# Update global list of categories and list of facts
# TODO make sure all in the same case  (HERE OR ELSEWHERE?)
sub enter_info {
   @{$cat[0]} = qw(apple pear cherry orange);
   @{$cat[1]} = qw(blue yellow green red);
   @{$cat[2]} = qw(Fred Susan Suzie Charlie);

   @{$fact[0]} = qw(apple is blue);
   @{$fact[1]} = qw(Susan is green);
   @{$fact[2]} = qw(cherry is Fred);
   @{$fact[3]} = qw(Charlie is pear);
   @{$fact[4]} = qw(Fred is red);
   #@{$fact[4]} = qw(Fred is green);   # error
}


#----------------------------------------------------------
# Assign each item word to a unique number
# Keep track of which category number an item word belongs to
sub init_items {
   my($catnum, $itm, $itm2);
   my $counter = 1;
   for ( $catnum=0; $catnum<=$#cat; $catnum++ ) {
      for $itm ( @{$cat[$catnum]} ) {
         $itmnum{$itm} = $counter;
         $counter++;
         $item_cat_num{$itm} = $catnum;
      }
   }
}


#----------------------------------------------------------
# Add a know fact
# Params:  item-A  relationship  item-B
sub add_fact {
   my($a, $rel, $b) = @_;
   my($value, $xvalue, $item);

   # Add truth/false based on relationship
   if ( $rel =~ m/is/i ) {
      $value  = 1;
      $xvalue = -1;
   }
   if ( $rel =~ m/not/i ) {
      $value  = -1;
      $xvalue = 1;
   }
   $truth[$itmnum{$a}][$itmnum{$b}] = $value;
   $truth[$itmnum{$b}][$itmnum{$a}] = $value;

   # Set to false other items in these two categories
   for $item ( @{$cat[$item_cat_num{$a}]} ) {
      next if $item eq $a;
      add_fact_if_ok($item, $b, $value, $xvalue);
   }
   for $item ( @{$cat[$item_cat_num{$b}]} ) {
      next if $item eq $b;
      add_fact_if_ok($item, $a, $value, $xvalue);
   }
   # Copy to other truth/false items

}

sub add_fact_if_ok {
   my($one, $two, $val, $xval) = @_;
   if ( $truth[$itmnum{$one}][$itmnum{$two}] == $val ) {
      warn "ERROR $one and $two is $val but want to set $xval\n";
   } else {
      $truth[$itmnum{$one}][$itmnum{$two}] = $xval;
      $truth[$itmnum{$two}][$itmnum{$one}] = $xval;
   }
}

#----------------------------------------------------------
# Starting point for printing out answers
# Determine which mix of categories to print
sub print_grid {
   my($lastcol) = $#cat;
   my($row, $col);   # category numbers 0 thru last

   # Print first row of boxes all across
   $row = 0;
   for ( $col=1; $col<=$lastcol; $col++ ) {
      print_box($row, $col);
   }
   $lastcol--;
   # Loop thru other rows
   for ( $row=$#cat; $row>=2; $row-- ) {
      for ( $col=1; $col<=$lastcol; $col++ ) {
         print_box($row, $col);
      }
      $lastcol--;
   }
}

# Print box of truths for intersection of two categories
# Params:  row-category-number, column-category-number
sub print_box {
   my($row_catnum, $col_catnum) = @_;
   my($itm, $row, $col, $rowword, $colword, $marker);
   my $fmt = "  %s         ";    # for markers
   my $hfmt = "%12s ";           # for row header (right-justified)
   my $hfmtL = "%-12s";          # for column header (left-justified)

   # Print column headers
   printf $hfmt, '';
   for $itm ( @{$cat[$col_catnum]} ) {
      printf $hfmtL, $itm;
   }
   print "\n";

   # Print each row of data
   #for ( $row=0; $row<$numitem; $row++ ) {
   for $rowword ( @{$cat[$row_catnum]} ) {
      printf $hfmt, $rowword;
      for $colword ( @{$cat[$col_catnum]} ) {
         if ( $truth[$itmnum{$rowword}][$itmnum{$colword}] > 0) {
            $marker = 'X';
         } elsif ( $truth[$itmnum{$rowword}][$itmnum{$colword}] < 0 ) {
            $marker = 'o';
         } else {
            $marker = '_';
         }
         printf $fmt, $marker;
      }
      print "\n";
   }
   print "\n";
}



