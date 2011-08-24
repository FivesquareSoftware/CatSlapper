#!/usr/bin/perl -w

#    Copyright (C) 2000 and on and on
#    by Robert Bresner
#    Open Link Financial, Inc
#    based on an idea by Danny Sadinoff (Hi Danny :-)
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
# cvstat - parses output of cvs stat and offers it in a handy readable format.
#  cvstat -F parses cvs status only, and does not report files that need first checkout (as cvs status does not)
#  cvstat without the -F parses 'cvs -n update' and the CVS/Entries files and sorts the output
#  cvstat -B will compare file timestamps to CVS/Entries timestamps and report locally modified files
#   ( Could report "Needs first/last checkin" also, but I never got around to it. )
#   -B is very very fast. (cvstat -BL is a nice way to reduce a list to a reg'lar cvstat )
# I wrote this program a long while back while still learning Perl, so it's not the prettiest
#  code in the world. But, it works for me

use strict;
use FileHandle;
use Cwd;

my $Recursive = 1;
my $verbose = 0;
my @Files;
my $Rev;
my $ShowList = 0;
my $FastStat = 0;
my $workdir;
my $DoneHeader = 0;
my $CurTag;
my $ShowEmptyTags = 1;
my $Quiet = 0;
my $FNameOnly = 0;
my $FinTime = 0;
my( $U, $M, $A, $R, $C, $P, $T, $Q) = (0, 1, 1, 1, 1, 1, 0, 0);
my @ListFiles;
my %UpdateHash;  # Keeps track of info during a slow stat
my %EntriesHash; # Saves Entries files files to check for 'needs first checkoout' files
my $Cwd;   # Directory where cvstat is being run from, this part of path is removed from filenames later.
my( $ST, $SF, $SS ) = (0, 0, 0);   # Sort flags;
my( $NewRoot, @CVSVars ) = ('');
my $ZC = '';
my $NoBranch = 0;
my $NetComp = 0;
my $UseCVSROOT = 0;
my $BLAZINGLY_FAST = 0;         # In caps cause it's just THAT fast.
my $tag= '';                    # Tag check for BFast mode
$| = 1;
GetArgs();
Go();
print "@ListFiles\n" if $ShowList;
################################################################################

sub CheckStatus
{
   my $CVStat = shift;

   return 'C' if $CVStat =~ /Needs Merge/;
   return 'U' if $CVStat =~ /Up-to-date/;
   return 'M' if $CVStat =~ /Locally Modified/;
   return 'P' if $CVStat =~ /Needs Update|Needs Patch/;
   return 'A' if $CVStat =~ /Locally Added/;
   return 'R' if $CVStat =~ /Locally Removed/;
   return 'Removed' if $CVStat =~ /Needs Checkout/;

   # Needs Checkout -- ? Deleted from repository, other directory reports this... Perhaps I'll handle that sometime.
   return $CVStat;
}

sub Go
{

   # If FastStating, just read the output of 'cvs status'
   #  otherwise, read the CVS/Entries file and try cvs -n update

   my $Cmd;
   $Cmd = "cvs -q";
   $Cmd .= " $ZC" if $ZC;
   $Cmd .= " $NewRoot";
   $Cmd .= " @CVSVars" if @CVSVars;
   if( $FastStat )  {
      $Cmd .= " status";
      $Cmd .= " -l" unless $Recursive;
      $Cmd .= " @Files" if @Files;
   }
   elsif( $BLAZINGLY_FAST )   {
      BlazeGo( @Files );
      exit( 0 );
   }
   else  {
      $Cmd .= " -n update";
      $Cmd .= " -l" unless $Recursive;
      $Cmd .= " @Files" if @Files;
   }

   my $FH = new FileHandle;
   print "Opening command pipe: $Cmd\n" if $verbose;
   open( $FH, "$Cmd|")
      or die "Cannot run command $Cmd: $!\n";

   if( $FastStat )  {  # FASTSTAT
      # Just parse the cvs status output.
      my( $File, $Status, $Tag);

      while( <$FH> )  {  
         print if $verbose;
         if( /^\? (.*)$/ )  {  PrintEntry('Q', $1);  }
         if( /^File: (.*)\s+Status: (.*)$/ )  {
            $File = $1;
            $Status = CheckStatus($2);
         }

         if( /Repository revision:/ )  {
            print "REPOSITORY\n" if $verbose;
            if( /Repository revision:.*?\/(.*?)$/ )  {
               my $FDir = $1;
               print "File $File in dir $FDir\n" if $verbose;
               if( $Status eq 'newbie' )  {
                  PrintEntry('Added', $File, 'none');
               }
            }
         }
         if( /Sticky Tag:\s+(.*)\s+/ )  {
            $Tag = $1;
            if( $NoBranch and /\(branch\:/ )  {  # If this is a branch, not a tag
               $Tag =~ s/\(branch:.*?\)//;
            }
            PrintEntry($Status, $File, $Tag);
         }
         if( /No entry for/ )   {
            $Status = 'newbie';
         }
      }
   }
   else  {  # ORIGINAL FLAVOR
      # Ok. Since this is the slow mode, read the Entries files for info first, 
      # then compare that info to the data from the cvs update

      while( <$FH> )  {
         /^\? (.*)$/ and do  {
            $UpdateHash{$1} = 'Q';
            next;
         };
         if( /(.) (.*)$/ )  {
            my ($file, $stat) = ($2, $1);
            if( $stat eq 'U' )  {
               $stat = 'P';
            }
            $UpdateHash{$file} = $stat;
            # print "SAVING FOR LATER: $2 => $1\n";
         }
      }
      # Ok, now I have a list of all the files. Search the Entries files for tags and such...
      # Saving info in UpdateHash: $File => $Stat|$Tag
      ReadEntries( $Cwd );

      # Now the %UpdateHash is filled with what needs printed.
      foreach my $File( sort MyHashSort keys %UpdateHash )  {
         my( $Stat, $Tag ) = split /\|/, $UpdateHash{$File};
         PrintEntry($Stat, $File, $Tag);
      }
   }
   close $FH;
}

sub MyHashSort
{
   # $a and $b are keys to %UpdateHash.
   # I wrote this program before I learned about hash of hashes
   return $a cmp $b
      if( $SF );

   my( $AStat, $ATag ) = split /\|/, $UpdateHash{$a};
   my( $BStat, $BTag ) = split /\|/, $UpdateHash{$b};

   $ATag = '' unless defined $ATag;
   $BTag = '' unless defined $BTag;

   return $AStat cmp $BStat
      if( $SS );
   return $ATag cmp $BTag
      if( $ST );

   return 0;
}

sub ReadEntries
{
   my $Dir = shift;
   # First check for and read the CVS/Entries file
   # print "Reading CVS/Entries for $Dir\n";
   if( -e "$Dir/CVS/Entries" )  {
      my $EFH = new IO::File("$Dir/CVS/Entries", 'r')
         or warn "WARNING: Could not read $Dir/CVS/Entries file: $!\n";
      while( <$EFH> )  {
         /^D/ and next;  # Skip directory entries
         chomp;
         my( $ThisFile, $ThisTag);
         if( /\/(.*?)\/.*\/(.*)$/ )  {  # I only want the file and tag info. Thank you.
            ( $ThisFile, $ThisTag ) = ("$Dir/$1", $2);
            # print "GOT THIS: FILE $ThisFile   TAG: $ThisTag\n";
         }
         else  {
            warn "Cannot parse $Dir/CVS/Entries line: $_\n";
            next;
         }
         $ThisTag = '' unless defined $ThisTag;
         $ThisFile =~ s/^$Cwd\///;
         $EntriesHash{$ThisFile} = "$ThisTag";
         if( exists $UpdateHash{$ThisFile} )  {
            $UpdateHash{$ThisFile} .= "|$ThisTag";
         }
         else  {
            $UpdateHash{$ThisFile} = "U|$ThisTag";  # No hash entry yet means it's up-to-date
         }
      }
   }
}

sub GetStat
{
   my $Stat = shift;

   return 'Up-To-Date' if $Stat eq 'U';
   return 'Locally Modified' if $Stat eq 'M';
   return 'Needs First Checkin' if $Stat eq 'A';
   return 'Removed, Needs Last Checkin' if $Stat eq 'R';
   return '*Needs Merged' if $Stat eq 'C';
   return 'Needs Update' if $Stat eq 'P';
   return 'Unknown File' if $Stat eq 'Q';

   return $Stat;
}

sub PrintEntry
{

   my( $Type, $File, $Tag ) = @_;
   print "CHECKING ENTRY FOR PRINT: TYPE $Type\n" if $verbose;

   if( not $T )  {  # If tags are on, everything gets printed, doncha know.
      return if $Type eq 'U' and not $U;
      return if $Type eq 'M' and not $M;
      return if $Type eq 'A' and not $A;
      return if $Type eq 'R' and not $R;
      return if $Type eq 'C' and not $C;
      return if $Type eq 'P' and not $P;
   }
   return if $Type eq 'Q' and not $Q;

   $Type = GetStat($Type);
   $Tag = '' unless $Tag;
   $Tag = $Tag =~ /none/ ? '' : $Tag;  # none may be in parens
   $File =~ s/\s+//g;

   $Tag = '' unless $T;

   if( not $DoneHeader and not $FNameOnly )   {
      my $Header = '';
      $Header .= "Sticky Tag     " if( $T or $ShowEmptyTags );
      $Header .= "Status               File";
      print "$Header\n";
      $DoneHeader = 1;
   }

   printf "%-14s ", $Tag
      if( $T or $ShowEmptyTags and not $FNameOnly );
   printf "%-20s ", $Type
      if( not $FNameOnly );
   print "$File\n";
   push @ListFiles, $File;

}

sub GetArgs
{
   # I wrote this long before learning of the likes of Getopts::Long
   my $RCtr = 0;
   my $DCtr = 0;
   my $usage = '';
   while( <DATA> )  {
      $usage .= $_;
   }

   my $STime = 0;
   $Cwd = cwd();
   $Cwd =~ s/\\/\//g;

   if( exists $ENV{CVSTAT_ARGS} and not (grep /^\-i$/, @ARGV ))  {   # Always the last args, the
      unshift @ARGV, split /\s+/, $ENV{CVSTAT_ARGS};
      warn "\tUsing CVSTAT_ARGS env var: $ENV{CVSTAT_ARGS}\n"
         unless (grep /^\-q$/, @ARGV);
   }

   while( @ARGV )  {
      my $a = shift @ARGV;
      if( $a =~ /^\-r(.*?)$/ )  {
         my $arg = $1 ? $1 : shift @ARGV;
         die "Only one -r, thanks. $0 for help\n"
            if $Rev;
         die "-r requires a tag/branch/revision. $0 -h for help\n"
            unless $arg;
         $a = '-r';
         print "GOT -r ARG: $a $arg\n" if $verbose;
         $Rev = $arg;
         $tag = $arg;
      }
      elsif( $a =~ /^\-B$/ )  {
         print "GOT -B ARG: $a\n" if $verbose;
         $BLAZINGLY_FAST = 1;
      }
      elsif( $a =~ /^\-i$/ )  {
         print "GOT -i ARG: $a\n" if $verbose;
         # The %CVSTAT_ARGS% var wouldn't have been added above if -i was used.
      }
      elsif( $a =~ /^\-d(.*?)$/ )  {
         my $arg = $1 ? $1 : shift @ARGV;
         $a = '-d';
         print "GOT: -d ARG: $a $arg\n" if $verbose;
         $NewRoot = "$a $arg";
      }
      elsif( $a =~ /^\-R$/ )  {
         print "GOT: -R\n" if $verbose;
         if( not exists $ENV{CVSROOT}  )  {
            die "Cannot use -R if env var CVSROOT is not set. -h for help\n";
         }
         $NewRoot = "-d $ENV{CVSROOT}";
      }
      elsif( $a =~ /^\-z(.*?)$/ )  {   # Compression level
         my $arg = $1 ? $1 : shift @ARGV;
         $a = '-z';
         print "GOT: -z ARG: $a $arg\n" if $verbose;
         $ZC = "$a $arg";
      }
      elsif( $a =~ /^\-h$/ )  {
         print "GOT -h ARG: $a\n" if $verbose;
         die "$usage\n";
      }
      elsif( $a =~ /^\-l$/ )  {
         print "GOT -l ARG: $a\n" if $verbose;
         $Recursive = 0;
      }
      elsif( $a =~ /^\-b$/ )  {
         print "GOT -b ARG: $a\n" if $verbose;
         $NoBranch = 1;
      }
      elsif( $a =~ /^\-c$/ )  {
         print "GOT -c ARG: $a\n" if $verbose;
         $ShowEmptyTags = 0;
      }
      elsif( $a =~ /^\-t$/ )  {
         print "GOT -t ARG: $a\n" if $verbose;
         print "Start time: ".(localtime)."\n"
            unless $STime;
         $STime = 1;
      }
      elsif( $a =~ /^\-tt$/ )  {
         print "GOT -tt ARG: $a\n" if $verbose;
         print "Start time: ".(localtime)."\n"
            unless $STime;
         $FinTime = 1;
         $STime = 1;
      }
      elsif( $a =~ /^\-L$/ )  {
         print "GOT -L ARG: $a\n" if $verbose;
         $ShowList = 1;
      }
      elsif( $a =~ /^\-o$/ )  {
         print "GOT -o ARG: $a\n" if $verbose;
         $FNameOnly = 1;
      }
      elsif( $a =~ /^\-F$/ )  {
         print "GOT -F ARG: $a\n" if $verbose;
         $FastStat = 1;
      }
      elsif( $a =~ /^\-q$/ )  {
         print "GOT -q ARG: $a\n" if $verbose;
         $Quiet = 1;
      }
      elsif( $a =~ /^\-V$/ )  {
         print "GOT -V ARG: $a\n" if $verbose;
         $verbose = 1;
      }
      elsif( $a =~ /^\-sf$/ )  {
         print "GOT -sf ARG: $a\n" if $verbose;
         $SF = 1;
      }
      elsif( $a =~ /^\-st$/ )  {
         print "GOT -st ARG: $a\n" if $verbose;
         $ST = 1;
      }
      elsif( $a =~ /^\-ss$/ )  {
         print "GOT -ss ARG: $a\n" if $verbose;
         $SS = 1;
      }
      elsif( $a =~ /^\-s(.*?)$/ )  {   # After the sorts for a reason.
         my $arg = $1 ? $1 : shift @ARGV;
         $a = '-s';
         print "GOT: -s ARG: $a $arg\n" if $verbose;
         push @CVSVars, "$a $arg";
      }
      elsif( $a =~ /^\-/ )  {
         print "GOT UNKNOWN ARG: $a\n" if $verbose;
         die "Unknown option: '$a'\ncvstat -h for help\n";
      }
      elsif( $a =~ /^\+/ )  {
         $a =~ /\+\+/ and $U = $M = $A = $R = $C = $P = $T = $Q = 1;
         $a =~ /U/ and $U = 1;
         $a =~ /M/ and $M = 1;
         $a =~ /A/ and $A = 1;
         $a =~ /R/ and $R = 1;
         $a =~ /C/ and $C = 1;
         $a =~ /P/ and $P = 1;
         $a =~ /T/ and $T = 1;
         $a =~ /Q/ and $Q = 1;
      }
      elsif( $a =~ /^!/ )  {
         $a =~ /!!/ and $U = $M = $A = $R = $C = $P = $T = $Q = 0;
         $a =~ /U/ and $U = 0;
         $a =~ /M/ and $M = 0;
         $a =~ /A/ and $A = 0;
         $a =~ /R/ and $R = 0;
         $a =~ /C/ and $C = 0;
         $a =~ /P/ and $P = 0;
         $a =~ /T/ and $T = 0;
         $a =~ /Q/ and $Q = 0;
      }
      else  {
         push @Files, $a;
      }
   }

   die "Mock mock mock. cvstat is useless unless some file status type is on. cvstat -h for help\n"
      if( $U + $M + $A + $R + $C + $P + $T + $Q == 0 );

   print "\n\t%%% WARNING: Fast-stat does not report files that need first checkout\n"  # not for lack of trying, tho.
      if( $FastStat and not $Quiet );

   if( $verbose )  {
      print "      up-to-date: ". ($U ? 'U' : '!U') . "\n";
      print "locally modified: ". ($M ? 'M' : '!M') . "\n";
      print "   locally added: ". ($A ? 'A' : '!A') . "\n";
      print " locally removed: ". ($R ? 'R' : '!R') . "\n";
      print "    needs merged: ". ($C ? 'C' : '!C') . "\n";
      print "     needs patch: ". ($P ? 'P' : '!P') . "\n";
      print "   unknown files: ". ($Q ? 'Q' : '!Q') . "\n";
   }

   if( $SF + $ST + $SS == 0 )  {
      $SF = 1;
   }
}

END  {
   print "Finished: ".(localtime)."\n"
      if $FinTime;
}


# For BLAZINGLY FAST MODE(tm)
sub GetEntries
{
   my( $Dir, $HRef ) = @_;
   my @Files;
   opendir DIR, $Dir
      or die "Cannot read dir $Dir: $!\n";
   ( @Files ) = grep /Entries/, readdir DIR;
   closedir DIR;

   foreach my $EFile( @Files )  {
      my $FH = new IO::File( "$Dir/$EFile" )
         or die "cannot read $Dir/$EFile: $!\n";
      while( <$FH> )   {
         next if /^D|^.\s+D/;           # dir recursion is handled in Go()
                                        # The second half of that regex should handle Entries.Log files.
         chomp;
         my( $File, $Date, $Tag);
         ( undef, $File, undef, $Date, undef, $Tag ) = split '/', $_;
         $Tag = "MAINLINE" unless $Tag;
         $Tag =~ s/^T//;
         $HRef->{$File} = [$Date,$Tag];
         print "\t$File -> $Date" if $verbose;
         print "   TAG: " . ( $Tag ? $Tag : '' ) . "\n" if $verbose;
      }
   }
}

# I knew a girl named Blaze in college. She might have spelled it differently.
sub BlazeGo
{
   my @Days = qw( Sun Mon Tue Wed Thu Fri Sat );
   my @Months = qw( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec );
   my @List;
   my @Things = @_ ? @_ : ( '.' );

   $tag = 'MAINLINE' if( $tag and $tag eq 'none' );

   foreach my $Dir( @Things )  {
      my %EFiles;

      if( -d "$Dir/CVS" )  {
         print "CHECKING $Dir/CVS/Entries*\n" if $verbose;
         GetEntries( "$Dir/CVS", \%EFiles );
      }
      else  {
         print "NO CVS DIR HERE: $Dir\n" if $verbose;
         next;
      }

      my @Files;
      opendir DIR, $Dir
         or die "Cannot readdir $Dir; $!\n";
      ( @Files ) = readdir DIR;
      closedir DIR;

      foreach my $File( @Files )   {
         next if( -d "$Dir/$File" and $File =~ /^\.\.?/ );
         if( -d "$Dir/$File" )  {
            BlazeGo( "$Dir/$File" );
            next;
         }

         my( $D, $F );
         ( $D = $Dir ) =~ s/^\.\///;
         $F = $D ? "$D/$File" : $File;

         if( exists $EFiles{$File} )   {
            # Found a CVS file, check timestamp for modification
            # CVS Times are reported in GMT, wheras the localtime is indeed in the local
            #  timezone. Convert local time to gmtime.
            # The time string from the Entries file has a little different formatting, so I
            #  have to put the time together myself.

            my $ctime;
            my @gmtime = gmtime( (stat "$Dir/$File")[9]);

            $ctime = sprintf( "%s %s %02d %02d:%02d:%02d %04d",
                              $Days[$gmtime[6]], $Months[$gmtime[4]], $gmtime[3],
                              $gmtime[2], $gmtime[1], $gmtime[0], 1900 + $gmtime[5] );

            # different cvs's seem to form the datetime string differently. So, 
            # rip the cvs time apart and put it back together in the same format.
            # print STDOUT "$EFiles{$File}->[0]\n";
            my $cvtime;
            if( $EFiles{$File}->[0] =~ /Result|dummy/ )   {
               $cvtime = localtime();
            }
            else  {
               my( $w, $m, $d, $h, $mi, $s, $y ) = split /[\:\s]+/, $EFiles{$File}->[0];
               $cvtime = sprintf( "%s %s %02d %02d:%02d:%02d %04d",
                                  $w, $m, $d, $h, $mi, $s, $y );
            }

            print "\t\tCVS FILES LOCAL TIME: $File [$ctime] [$cvtime]]\n"
               if $verbose;

            $F =~ s/\.\///g;
            if( $ctime ne $cvtime )  {
               print STDOUT "\tLocally Modified\t\t$F\n";
               push @List, $F;
            }
            else  {
               #print "UP-TO-DATE: $F [$ctime][$cvtime]\n";
            }
            # Now check tags
            if( $tag and( $EFiles{$File}->[1] ne $tag ))  {
               print STDOUT "\tDIFFERENT TAG   \t\t$F [$tag != $EFiles{$File}->[1]]\n";
            }
         }
         else  {
            print STDOUT "\tUnknown File    \t\t$F\n" if $U;
         }
      }
   }
   print "@List\n" if $ShowList;
}


__DATA__
cvstat prints status and sticky tags from cvs.
        -r tag          report deviations from this tag (Also for Blazingly Fast Mode(tm) )
        -B              Blazingly Fast Mode(tm). It really is fast, ya know.
        -l              do not recurse
        -t|-tt          display start|finish time
        -c              hide tags column when not showing tags
        -L              display single-line file list at end for easy cut'n'paste (only files in stat list)
        -F              Fast-Stat. WARNING: Does not report "needs first checkout" files
        -q              quiet-mode. Hide warnings, only show errors.
        -o              diplay filename info only, no tags, no headers, no status.
        -z#             passed on to CVS. Sets the compression level on communications with the server.
        -i              Ignore CVSTAT_ARGS
        -b              Do not display the branch revision when +T
        -d cvsroot      set CVSROOT to something other than its current value
        -R              use CVSROOT env var with -d
        -s VAR=VAL      set some other cvs var to a value
        -st             sort by TAG
        -ss             sort by STATUS
        -sf             sort by FILENAME
        -h      display this help messageThe following status options can be used in combinations
        !       turns off the following ...
        +       turns on the following ...
        U       display up-to-date files (default: Off)
        M       display locally modified files (default: On)
        A       display locally added files (default: On)
        R       display locally removed files (default: On)
        C       display files with conflicts (default: On)
        P       display files that need patch|checkout (default: On)
        T       display sticky tag info. (default: Off)
        Q       display files not in cvs repository (default: Off)
        !!      Turns off all everything. Useful first option.
        ++      Turns on everything. useful first option.
Example useful commands:
   cvstat +TU !ARCMP    displays only files up-to-date and the sticky tags
   cvstat +MARC !P      displays files you want to check in
   cvstat !! +Q         show only the unknown files
   cvstat ++ !M         show everything except locally modified files
When using -o option, only filenames are displayed (useful for shell scripts). 
Beware
  that all files matching the status options are displayed. When using -o is a 
good time
  to specify the status options.
If sorting is turned on, the whole process takes a little longer, even with -F
Command line args override CVSTAT_ARGS args