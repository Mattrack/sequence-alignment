#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

my $A = "GAATTCAGTTA";
my $B = "GGATCGA";

my $points = {
	match 		=> 4,
	mismatch	=> -3,
	gap		=> -2,
	gap_open	=> -2,
	gap_extend	=> -1
};

my @matrix = ();
my $gaps;

sub init_matrix {
	foreach my $i (0..length($A) - 1) {
		@{ $matrix[$i] } = ();
		foreach my $j (0..length($B) - 1) {
			push @{ $matrix[$i] }, 0;
			$gaps->{$i}->{$j} = 0;
		}
	}

	foreach my $i (0..length($A) - 1) {
		$matrix[$i][0] = $i * $points->{gap_open};
		if ($i gt 1) {
			$matrix[$i][0] = $matrix[$i - 1][0] + $points->{gap_extend};
		}
	}
	foreach my $j (0..length($B) - 1) {
		$matrix[0][$j] = $j * $points->{gap_open};
		if ($j gt 1) {
			$matrix[0][$j] = $matrix[0][$j - 1] + $points->{gap_extend};
		}
	}
}

sub print_matrix {
	print "   | ";
	foreach my $j (0..length($B) - 1) {
		my $cB = substr($B, $j, 1);
		printf "% 3s ", $cB;
	}
	print "\n";

	foreach my $i (0..length($A) - 1) {
		my $cA = substr($A, $i, 1);
		print "-" x (length($B) * 5 - 3), "\n";
		print " $cA | ";

		foreach my $j (0..length($B) - 1) {
			my $n = $matrix[$i][$j];
			printf "% 3d ", $n;
		}
		print "\n";
	}
}

sub score_at {
	my ($i, $j) = @_;

	my $cA = substr($A, $i, 1);
	my $cB = substr($B, $j, 1);
	my $S = $points->{match};
	$S = $points->{mismatch} if ($cA ne $cB);
	return $S;
}

sub fill_matrix {
	foreach my $i (1..length($A) - 1) {
		foreach my $j (1..length($B) - 1) {
			my $S = score_at($i, $j);

			my $choice1 = $matrix[$i - 1][$j - 1] + $S;
			my $choice2 = $matrix[$i - 1][$j] + $points->{gap_open};
			if ($gaps->{$i - 1}->{$j} == $points->{gap_open} ||
			    $gaps->{$i - 1}->{$j} == $points->{gap_extend}) {
				$choice2 = $matrix[$i - 1][$j] + $points->{gap_extend};
			}
			my $choice3 = $matrix[$i][$j - 1] + $points->{gap_open};
			if ($gaps->{$i}->{$j - 1} == $points->{gap_open} ||
			    $gaps->{$i}->{$j - 1} == $points->{gap_extend}) {
				$choice3 = $matrix[$i][$j - 1] + $points->{gap_extend};
			}

			my @choices = ($choice1, $choice2, $choice3);
			my $max = (sort { $a <=> $b } @choices)[-1];
			$matrix[$i][$j] = $max;
			if ($max == $choice2 || $max == $choice3) {
				$gaps->{$i}->{$j} = $points->{gap};
			}
		}
	}
}

sub find_alignment {
	my $alignmentA = "";
	my $alignmentB = "";
	my $totalScore = 0;
	my $i = length($A) - 1;
	my $j = length($B) - 1;
	my $prevGap = 0;
	while ($i > 0 && $j > 0) {
		my $score = $matrix[$i][$j];
		my $scoreDiag = $matrix[$i - 1][$j - 1];
		my $scoreUp = $matrix[$i][$j - 1];
		my $scoreLeft = $matrix[$i - 1][$j];
		my $cA = substr($A, $i, 1);
		my $cB = substr($B, $j, 1);
		my $S = score_at($i, $j);

		# print "[$i][$j] -> $score\n";

		if ($score == $scoreDiag + $S)
		{
			$alignmentA = $cA . $alignmentA;
			$alignmentB = $cB . $alignmentB;
			--$i;
			--$j;
			$prevGap = 0;
			$totalScore += $S;
		}
		elsif ($score == $scoreLeft + $points->{gap_open} ||
			$score == $scoreLeft + $points->{gap_extend})
		{
			$alignmentA = $cA . $alignmentA;
			$alignmentB = "-" . $alignmentB;
			--$i;
			my $gapScore = $points->{gap_open};
			$gapScore = $points->{gap_extend} if ($prevGap);
			$prevGap = 1;
			$totalScore += $gapScore;
		}
		elsif ($score == $scoreUp + $points->{gap_open} ||
			$score == $scoreUp + $points->{gap_extend})
		{
			$alignmentA = "-" . $alignmentA;
			$alignmentB = $cB . $alignmentB;
			--$j;
			my $gapScore = $points->{gap_open};
			$gapScore = $points->{gap_extend} if ($prevGap);
			$prevGap = 1;
			$totalScore += $gapScore;
		}
	}
	return ($alignmentA, $alignmentB, $totalScore);
}

$A = "-$A";
$B = "-$B";
init_matrix();
fill_matrix();

print_matrix();
print "\n";

my ($alA, $alB, $total) = find_alignment();
print "$alA\n$alB\n";
print "Score: $total\n";
