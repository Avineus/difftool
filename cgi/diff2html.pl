#!/usr/bin/perl 

# diff2html.pl - the Perl script version of html2diff.
#
# Copyright (C) 2007 Ryohei Morita
#
# The original 'html2diff' was written in Python,
# by Yves Bailly and MandrakeSoft S.A.
#
# Copyright (C) 2001 Yves Bailly <diff2html@tuxfamily.org>
#           (C) 2001 MandrakeSoft S.A.
#
# This script is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This script is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, write to the
# Free Software Foundation, Inc., 59 Temple Place - Suite 330,
# Boston, MA 02111-1307, USA, or look at the website 
# http://www.gnu.org/copyleft/gpl.html

use strict;
use warnings;
use Data::Dumper;

# Magic regular expression
my $diffhead = qr/^diff /;
my $diff_pos = qr/^@@ \-(\d+)(,\d+)? \+(\d+)(,\d+)? @@/;
my $diff_ide = qr/^ (.*)$/;
my $diff_add = qr/^\+(.*)$/;
my $diff_del = qr/^\-(.*)$/;
my $diff_old = qr/^\-\-\- (.*)\s+(\d+\-\d+\-\d+) (.*)$/;
my $diff_new = qr/^\+\+\+ (.*)\s+(\d+\-\d+\-\d+) (.*)$/;
    
my ($last_change);
my ($nLine1,$nLine2);
my (@added,@changed,@deleted);
    
my @diffOutput;
my @delQueue;
$last_change=0;

my $default_css = <<END_OF_CSS;
table {
    border-collapse: collapse;
    border-spacing: 0px;
    padding: 0;
    margin: 0;
}

tr.Header { padding: 2ex; } 
tr.separator td { padding: 4ex; }

th {
    padding: 1.5ex 0;
    background-color: #444;
    color: #fff;
}

td.chunk {
    background-color: #ccc;
    color: #444;
    text-align: center;
    font-style: italic;

}

td.date {
    background-color: #444;
    color:  #ccc;
    font-style: italic;
    text-align: center;
}

td.linenum {
    color: #909090; 
    text-align: right;
    vertical-align: center;
}
td.added { background-color: #9f9; }
td.modified { background-color: #ffa; }
td.removed { background-color: #f99; }
td.normal { background-color: #fff; }

td.added, 
td.modified,
td.removed,
td.normal {
    border-top: .5px solid #ccc;
    border-bottom:  .5px solid #ccc;
    font-family: monospace;
}


td.addedlist {
    color: #9f9;
    background-color: #666;
    font-family: sans-serif;
}
td.modifiedlist {
    color: #ffa;
    background-color: #666;
    font-family: sans-serif;
}
td.removedlist {
    color: #f99;
    background-color: #666;
    font-family: sans-serif;
}
END_OF_CSS

sub print_usage {
    print <<END_OF_USAGE;
diff2html.pl - Formats diff(1) UNIFIED output from STDIN to an HTML page on stdout

Usage: diff2html.pl [--help|-?] [--only-changes] [--style-sheet file.css]
                    [diff options] file1 file2

--help                  This message
--only-changes          Do not display lines that have not changed
diff options            All other options are passed to diff(1)

Example:
# Basic use
diff2html.pl file1.txt file2.txt > differences.html

diff2html.pl is released under the GNU GPL.
Feel free to submit bugs or ideas to <diff2html\@tuxfamily.org>.
END_OF_USAGE
}

sub str2html {
    my $s = shift;
    return '' unless(defined $s);
    $s =~ s/[\r\n]*$//g;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/ /&nbsp;/g;
    return $s;
}

sub flushDelete() {
    while (my $del = shift @delQueue) {
        push @diffOutput, {
            'type'  => 'removed',
            'n1'    => $nLine1,
            'old'   => $del,
            'n2'    => 0
        };
        push @deleted, $nLine1++;
    }
}

sub printChunks($@) {
    my $prefix = shift;
    my @diffLines = @_;
    my (%out,$type,$line1,$line2,$old,$new);
    my ($out);
    foreach $out (@diffLines) {
        $type  = $out->{'type'};
        $old   = $out->{'old'};
        $new   = $out->{'new'};
        $line1 = $out->{'n1'};
        $line2 = $out->{'n2'};
        
        $old = "" if (!defined $old);
        $new = "" if (!defined $new);
        if ($type eq "added") {
            $line1 = $line2;
            $prefix = $prefix."plus";
        }
        if ($type eq "chunk") { $line1=""; }
        
        printf <<'END_OF_HTML_CHUNK', $type, $prefix, $line1, $line1, $type, str2html($old), $type, str2html($new);
    <tr class="%s">
        <td class="linenum"><a name="%sline%s">%s</a></td>
        <td class="%s">%s</td>
        <td class="%s">%s</td>
    </tr>
END_OF_HTML_CHUNK
    }
}

# fileinfo, 
sub printFileDiff {
    my ($fileInfo,$diff) = @_;
       
    # Build a prefix for the links
    my $prefix = $fileInfo->{'old'};
    $prefix =~ s%/%_%g;
    
    # Build link list
    my ($added,$changed,$deleted) = ($fileInfo->{'added'}, $fileInfo->{'changed'},$fileInfo->{'deleted'});
    my ($addLinks,$modLinks,$delLinks);
    $addLinks = join(",",map('<a href="#'.$prefix.'newline'.$_.'">'.$_.'</a>', @$added));
    $modLinks = join(",",map('<a href="#'.$prefix.'line'.$_.'">'.$_.'</a>',  @$changed));
    $delLinks = join(",",map('<a href="#'.$prefix.'line'.$_.'">'.$_.'</a>',  @$deleted));
    
    printf <<'END_OF_HTML_DIFF_FILE', $fileInfo->{'old'}, $fileInfo->{'new'}, $fileInfo->{'olddate'}, $fileInfo->{'newdate'}, $modLinks, $addLinks, $delLinks, ;
    <tr class="separator">
        <td></td>
        <td></td>
        <td></td>
    </tr>
    <tr>
        <td>&nbsp;</td>
        <th width="45%%"><strong><big>%s</big></strong></th>
        <th width="45%%"><strong><big>%s</big></strong></th>
    </tr>
    <tr>
        <td>&nbsp;</td>
        <td class="date">%s</td>
        <td class="date">%s</td>
    </tr>
    <tr>
        <td></td>
        <td class="modifiedlist">Modified lines:&nbsp;</td>
        <td class="modifiedlist">%s</td>
    </tr>
    <tr>
        <td></td>
        <td class="addedlist">Added line:&nbsp;</td>
        <td class="addedlist">%s</td>
    </tr>
    <tr>
        <td></td>
        <td class="removedlist">Removed line:&nbsp;</td>
        <td class="removedlist">%s</td>
    </tr> 
END_OF_HTML_DIFF_FILE
    printChunks($prefix, @diffOutput);
}

# MAIN

# Processes command-line options
my $cmd_line = join ' ', $0, @ARGV;

# First, look for "--help"
for my $opt (@ARGV) {
    if ( $opt eq '--help' or $opt eq '-?' ) {
        &print_usage();
        exit(0);
    }
}

my $ind_chg = -1;
my $only_changes = 0;
for my $ind_opt (0..$#ARGV) {
    if ( $ARGV[$ind_opt] eq '--only-changes' ) {
        $ind_chg = $ind_opt;
        $only_changes = 1;
    }
}

my @diff_output = <STDIN>;
    
my %diff;

# Printing the HTML header, and various known informations
#printf <<'END_OF_HEADER_PART1', $default_css;
#<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
# "http://www.w3.org/TR/REC-html40/loose.dtd">
#<html>
#<head>
#    <title>Differences</title>
#    <style type="text/css">
#    <!-- %s -->
#    </style>
#</head>
#<body>
#<table>
#END_OF_HEADER_PART1

# Printing the HTML header, and various known informations
printf <<'END_OF_HEADER_PART1', $default_css;
<table>
END_OF_HEADER_PART1

# Now parse the output from "diff"
for my $diff_line (@diff_output) {
    #
    if (($diff_line =~ /$diffhead/) && (@diffOutput)) {
        flushDelete();
        $diff{'added'}   = \@added;
        $diff{'changed'} = \@changed;
        $diff{'deleted'} = \@deleted;
        printFileDiff(\%diff,\@diffOutput);
        @added = ();
        @changed = ();
        @deleted = ();
        @diffOutput = ();
        $nLine1 = 0;
        $nLine2 = 0;
        %diff = ();
        next;
    }
    
    # OLD file information
    if ($diff_line =~ /$diff_old/) {
        $diff{'old'}     = $1;
        $diff{'olddate'} = $2." ".$3;
        next;
    }
    
    # NEW file information
    if ($diff_line =~ /$diff_new/) {
        $diff{'new'}     = $1;
        $diff{'newdate'} = $2." ".$3;
        next;
    }
        
    # Start of chunk
    if ($diff_line =~ /$diff_pos/) {
        flushDelete();
        # New Chunk
        my $chunk1_start = int($1);
        my $chunk2_start = int($3);
        my $n1 = (defined($2)) ? $2 : 1;
        my $n2 = (defined($4)) ? $4 : 1;
        $n1 =~ s/,//;
        $n2 =~ s/,//;
        my $chunk1_end = $chunk1_start + $n1 - 1;
        my $chunk2_end = $chunk2_start + $n2 - 1;
        push @diffOutput, {
            'type'  => 'chunk',
            'n1'    => $chunk1_start,
            'n2'    => $chunk2_start,
            'old'   => 'Lines '.$chunk1_start.' - '.$chunk1_end,
            'new'   => 'Lines '.$chunk2_start.' - '.$chunk2_end
        };
        $nLine1 = $chunk1_start;
        $nLine2 = $chunk2_start;
        next;
    }
        
    # Unmodified line
    if ($diff_line =~ /$diff_ide/) {
        flushDelete();
        if ($only_changes != 1) {
            push @diffOutput, {
                'type'  => 'normal',
                'n1'    => $nLine1,
                'old'   => $1,
                'new'   => $1,
                'n2'    => $nLine2
            };
        }
        $last_change=0;
        $nLine1++;
        $nLine2++;
        next;
    }
        
    # Deleted line
    if ($diff_line =~ /$diff_del/) {
        $last_change--;
        push @delQueue, $1;
        next;
    }
        
    # New Line
    if (($diff_line =~ /$diff_add/) && ($last_change < 0)) {
        # Changed line
        my $oldLine = shift @delQueue;
        push @diffOutput, {
            'type'  => 'modified',
            'n1'    => $nLine1,
            'old'   => $oldLine,
            'n2'    => $nLine2,
            'new'   => $1               
        };
        $last_change++;
        push @changed, $nLine1++;
        $nLine2++;
        next;
    } elsif ($diff_line =~ /$diff_add/) {
        # Added line
        push @diffOutput, {
            'type'  => 'added',
            'new'   => $1,
            'n2'    => $nLine2,
            'n1'    => 0
        };
        push @added, $nLine2++;
        $nLine1--; # Undo unexistent line
        next;
    }
}

flushDelete();
$diff{'added'}   = \@added;
$diff{'changed'} = \@changed;
$diff{'deleted'} = \@deleted;
printFileDiff(\%diff,\@diffOutput);



# And finally, the end of the HTML
printf <<'END_OF_FOOTER', scalar(localtime(time())), $cmd_line;
</table>
<hr/>
</body>
</html>
END_OF_FOOTER
