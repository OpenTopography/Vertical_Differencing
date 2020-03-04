#!/usr/bin/perl

#############################################################################################
# LICENSE
#
# Copyright (c) 2007 The Regents of the University of California#
#
# Permission to use, copy, modify, and distribute this software and its documentation
# for educational, research and non-profit purposes, without fee, and without a written
# agreement is hereby granted, provided that the above copyright notice, this
# paragraph and the following three paragraphs appear in all copies.
#
# Permission to make commercial use of this software may be obtained
# by contacting:
# Technology Transfer Office
# 9500 Gilman Drive, Mail Code 0910
# University of California
# La Jolla, CA 92093-0910
# (858) 534-5815
# invent@ucsd.edu
#
# THIS SOFTWARE IS PROVIDED BY THE REGENTS OF THE UNIVERSITY OF CALIFORNIA AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT
# NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED.
# IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
# THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#############################################################################################

#############################################################################################
# REQUIRES:
#    GDAL installed
#    imagemagik installed
#
# USAGE:
#
#    vertical_differencing.pl
#            -i1 <input_ref_file>
#            -i2 <input_cmp_file>
#            -o <output file>
#            -mlod <minimum_level_of_detection_user_defined>
#            -se <survey_error>
#
#    All parameters are mandatory, and may be presented in any order
#
#############################################################################################

use strict;
use Time::HiRes qw(gettimeofday);    #provides millisecond-level+ timing
use Scalar::Util qw(looks_like_number);
use JSON;
use POSIX qw/ceil/;

# set the PATH to find gdal binaries
my $gdal_location = "/gdal/bin/";
my $histogram_py_location = "vertical_differencing_histogram.py";
my $colorbar_py_location = "vertical_differencing_colorbar.py";

my $time = gettimeofday();

#set the following to the path for the las2dem location
my $output_name = "output";
my $input_ref_file = "";
my $input_cmp_file = "";

my $mlod = -1;
my $surveyError = 0;

my $x1 = undef;
my $y1 = undef;
my $x2 = undef;
my $y2 = undef;
my $bind;
my $unit = "m";

sub startsWith {
    return index($_[0], $_[1]) == 0;
}

#this function encapsulates executing a command-line program, printing of stdout from
#a `` system call, and proper handling of the status code.
sub executeString {
    #execute line passed to function eg: 'cat myfile.txt'
    #redirect output to stderr to stdout
    my $cmd = "$_[0] 2>&1";
    my @status = `$cmd`;
    print "\n>>cmd: $cmd\n";

    #stdout has been captured in the @status array
    #the status code returned by the system call is stored in $?
    if($? != 0) {
        die "An error ($?) occured during processing. Aborting...\n";
    }

    my $errorMessage = undef;

    foreach my $s(@status) {
        print "\t$s";

        # work around in case, the error returned as stdout, not stderr
        if (index(lc($s), "error") >= 0) {
            $errorMessage = $s;
        }
    }

    if(defined $errorMessage) {
        die "An error occured during processing: $errorMessage\n";
    }
}

sub getXYBound {
    my $fileName = $_[0];

    my $gdal_cmd = $gdal_location . "gdalinfo -json " . $fileName ;
    print "\ngdal $gdal_cmd\n";

    my $json_output = `$gdal_cmd 2>&1`;

    print "\njson: $json_output.\n";

    my $data = decode_json($json_output);

    my $minx = undef;
    my $miny = undef;
    my $maxx = undef;
    my $maxy = undef;
    my $pixel_size = undef;
    my $dimensions = undef;

    if (defined $data->{cornerCoordinates}->{lowerLeft}) {
        my @lowerLeft = @{$data->{cornerCoordinates}->{lowerLeft}};
        $minx = $lowerLeft[0];
        $miny = $lowerLeft[1];
    }

    if (defined $data->{cornerCoordinates}->{upperRight}) {
        my @upperRight = @{$data->{cornerCoordinates}->{upperRight}};
        $maxx = $upperRight[0];
        $maxy = $upperRight[1];
    }

    return ($minx, $miny, $maxx, $maxy);
}

sub max {
    return $_[0] >= $_[1] ? $_[0] : $_[1];
}

sub min {
    return $_[0] >= $_[1] ? $_[1] : $_[0];
}

sub make_histogram {
    my $input_tif = $_[0];
    my $output_xyz = $_[1];
    my $output3_xyz = $_[2];
    my $output_png = $_[3];
    my $cur_mlod = $_[4];

    print ("\n-------------------------------------------------\n");
    print ("\nMaking histogram\n");
    print ("\nMake a text file with the differencing results \n");
    executeString($gdal_location . "gdal_translate -of XYZ " . $input_tif . " " . $output_xyz);

    print ("\nExtract the third column \n");
    executeString("awk '{\$1=\$2=\"\"; print \$0}' " . $output_xyz . " > " . $output3_xyz);

    print ("\nMaking histogram with python\n");
    my $histogram_cmd = "python3 " . $histogram_py_location . " " . $output3_xyz . " " . $output_png . " " . $bind . " " . $cur_mlod . " " . $unit;
    executeString($histogram_cmd);
}


my $num_argv = $#ARGV + 1;

for(my $i = 0; $i < $num_argv; $i++) {
    if($ARGV[$i] eq "-i1") {
        $input_ref_file = $ARGV[$i+1];
    }

    if($ARGV[$i] eq "-i2") {
        $input_cmp_file = $ARGV[$i+1];
    }

    if($ARGV[$i] eq "-o") {
        $output_name = $ARGV[$i+1];
    }

    if($ARGV[$i] eq "-mlod") {
        $mlod = $ARGV[$i+1];
    }

    if($ARGV[$i] eq "-se") {
        $surveyError = 1;
    }

    if($ARGV[$i] eq "-unit") {
        $unit = $ARGV[$i+1];
    }
}

if(!(-e $input_ref_file)) {
    die("Input ref file must be specified");
}

if(!(-e $input_cmp_file)) {
    die("Input cmp file must be specified");
}

my @status;

my @bound_ref = getXYBound("reference.tif");
my @bound_cmp = getXYBound("compare.tif");

#$minx, $miny, $maxx, $maxy
print ("\n\tx1: " . $bound_ref[0] . "\n\ty1: " . $bound_ref[1] . "\n\tx2: " . $bound_ref[2] . "\n\ty2: " . $bound_ref[3]);
print ("\n\n\tx3: " . $bound_cmp[0] . "\n\ty3: " . $bound_cmp[1] . "\n\tx4: " . $bound_cmp[2] . "\n\ty4: " . $bound_cmp[3]);
print "\n\n";

$x1 = max($bound_ref[0], $bound_cmp[0]);
$y1 = min($bound_ref[1], $bound_cmp[1]);
$x2 = min($bound_ref[2], $bound_cmp[2]);
$y2 = max($bound_ref[3], $bound_cmp[3]);

if ($bound_ref[0] != $x1 || $bound_ref[1] != $y1 || $bound_ref[2] != $x2 || $bound_ref[3] != $y2) {
    my $ref_cropCmd = $gdal_location . "gdalwarp -te " . $x1 . " " . $y1 . " " . $x2 . " " . $y2 . " " . $input_ref_file . " reference_crop.tif";
    print "\nrefrence will be cropped\n" . $ref_cropCmd;
    executeString($ref_cropCmd);
    $input_ref_file = "reference_crop.tif";
}

if ($bound_cmp[0] != $x1 || $bound_cmp[1] != $y1 || $bound_cmp[2] != $x2 || $bound_cmp[3] != $y2) {
    my $cmp_cropCmd = $gdal_location . "gdalwarp -te " . $x1 . " " . $y1 . " " . $x2 . " " . $y2 . " compare.tif compare_crop.tif";
    print "\ncompare will be cropped\n" . $cmp_cropCmd;
    executeString($cmp_cropCmd);
    $input_cmp_file = "compare_crop.tif";
}

print ("\n\tx1: " . $x1 . "\n\ty1: " . $y1 . "\n\tx2: " . $x2 . "\n\ty2: " . $y2 . "\n");

executeString("python " . $gdal_location . "gdal_calc.py -A " . $input_cmp_file . " -B " . $input_ref_file . " --outfile=" . $output_name . ".tif --calc=\"B-A\" --NoDataValue=-9999");
print ("\nCreate differencing from refrence and compare tif \n");

print ("\n-------------------------------------------------\n");
print ("\nMake PNG file: vertical_differencing.png\n");

#generatePng ($output_name . ".tif", "vertical_differencing.png");
my $thumbFile = "tmb_vertical_differencing.png";

executeString($gdal_location . "gdal_translate -stats " . $output_name . ".tif temp_" . $output_name . ".tif");
print ("\nCreate temp tif with metadata \n");

print ("\nCreate color file \n");
my $gdal_cmd = $gdal_location . "gdalinfo temp_" . $output_name . ".tif";
print "\n $gdal_cmd\n";

my $output = `$gdal_cmd 2>&1`;

my $statistics_stddev;
my $statistics_mean;

foreach my $line (split /[\r\n]+/, $output) {
    $line =~ s/^\s+|\s+$//g;
    if (startsWith($line, "STATISTICS_STDDEV") ) {
        my @tokens = split("=", $line);
        $statistics_stddev = $tokens[1];
        #print ("\n>>line: " . $line . "\n");
        print ("\n>>statistics_stddev: " . $statistics_stddev . "\n");
    }

    if (startsWith($line, "STATISTICS_MEAN") ) {
        my @tokens = split("=", $line);
        $statistics_mean = $tokens[1];
        #print ("\n>>line: " . $line . "\n");
        print ("\n>>statistics_mean: " . $statistics_mean . "\n");
    }
}

my $value = (2 * $statistics_stddev) + abs($statistics_mean);
print ("\n>>value: " . $value . "\n");

my $stddevVal = sprintf("%.1f", $value);
$bind = ceil(abs($statistics_mean) + (4*$statistics_stddev));

open(my $fh, '>', "color.txt") or die "Could not open file 'color.txt' $!";
print $fh "-9999 gray\n";
print $fh "-" . $value . " red\n";
print $fh "0 white\n";
print $fh $value . " blue\n";
close $fh;

if ($mlod > 0) {
    open(my $fh2, '>', "color2.txt") or die "Could not open file 'color2.txt' $!";
    print $fh2 "-9999 gray\n";
    print $fh2 "-" . $value . " red\n";
    print $fh2 "0 white\n";
    print $fh2 $value . " blue\n";
    print $fh2 "9999 black\n";
    close $fh2;
}


print ("\nMake the tiff file with the col.txt color palette.\n");
executeString($gdal_location . "gdaldem color-relief temp_" . $output_name . ".tif color.txt temp2_" . $output_name . ".tif");

print ("\nImageMagick: create main PNG file\n");
executeString("convert temp2_" . $output_name . ".tif vertical_differencing.png");

print ("\nImageMagick: Create thumbnail 400 x 400 of main image.\n");
executeString("convert -resize 400x400 vertical_differencing.png " . $thumbFile);

make_histogram (
    $output_name . ".tif",
    "vertical_differencing.xyz",
    "vertical_differencing_3.xyz",
    "histogram.png",
    -1);

print ("\nMake colorbar with python \n");
my $colorbar_cmd = "python3 " . $colorbar_py_location . " " . $stddevVal . " " . $unit . " colorbar_blue_white_red.png";
executeString($colorbar_cmd);


`mv $input_ref_file output.reference.tif`;
`mv $input_cmp_file output.compare.tif`;

if ($mlod > 0) {
    print ("\n-------------------------------------------------\n");
    print ("\nMake Error Detection \n");

    my $gdal_calc_cmd1 = "python " . $gdal_location . "gdal_calc.py -A " . $output_name . ".tif --outfile=abs.tif --calc=\"abs(A)\" --NoDataValue=-9999";
    executeString($gdal_calc_cmd1);
    print ("\n" . $gdal_calc_cmd1 . "\n");

    my $gdal_calc_cmd2 = "python " . $gdal_location . "gdal_calc.py -A " . $output_name . ".tif -B abs.tif --outfile=e1.tif --calc=\"A*(B>=" . $mlod . ")\" --NoDataValue=-9999";
    executeString($gdal_calc_cmd2);
    print ("\n" . $gdal_calc_cmd2 . "\n");

    my $gdal_calc_cmd3 = "python " . $gdal_location . "gdal_calc.py -A e1.tif -B abs.tif --outfile=errUserMinDet.tif --calc=\"(B<" . $mlod . ")*+9999+A\" --NoDataValue=-9999";
    executeString($gdal_calc_cmd3);
    print ("\n" . $gdal_calc_cmd3 . "\n");

    print ("\nMake the tiff file with the col.txt color palette.\n");
    executeString($gdal_location . "gdaldem color-relief errUserMinDet.tif color2.txt out_errUserMinDet.tif ");

    print ("\nImageMagick: create main PNG file\n");
    executeString("convert out_errUserMinDet.tif out_errUserMinDet.png");

    print ("\nImageMagick: Create thumbnail 400 x 400 of main image.\n");
    executeString("convert -resize 400x400 out_errUserMinDet.png tmb_out_errUserMinDet.png");

    make_histogram (
        "errUserMinDet.tif",
        "errUserMinDet.xyz",
        "errUserMinDet_3.xyz",
        "histogram_mlod.png",
        $mlod);
}

print "\nCompressing output...\n";

my $cmd = "tar -cvf " . $output_name. ".tar --remove-files " . $output_name . ".tif output.reference.tif output.compare.tif 2>/dev/null";

# tar cvf some.tar file1 file2 file3
print ("\n" . $cmd);
@status = `$cmd`;

$cmd = "gzip " . $output_name . ".tar 2>/dev/null";
print ("\n" . $cmd);
@status = `$cmd`;

print "\n\nCleaning up...\n";
@status = `rm *.tif`;

print "Process Completed.\n";
$time = gettimeofday() - $time;
print "Total time taken: $time seconds\n";
