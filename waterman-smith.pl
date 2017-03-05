#!/usr/bin/perl -w

use strict;
use warnings;
use diagnostics;

my $A = "-GAATTCAGTTA";
my $B = "-GGATCGA";

my $points = {
	match 		=> 4,
	mismatch	=> -3,
	gap		=> -2,
	gap_open	=> -2,
	gap_extend	=> -1
};

my @matrix = ();

sub init_matrix {
	foreach my $i (0..length($A) - 1) {
		@{ $matrix[$i] } = ();
		foreach my $j (0..length($B) - 1) {
			push @{ $matrix[$i] }, 0;
		}
	}

	foreach my $i (0..length($A) - 1) {
		$matrix[$i][0] = 0;
	}
	foreach my $j (0..length($B) - 1) {
		$matrix[0][$j] = 0;
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
			my $choice2 = $matrix[$i - 1][$j] + $points->{gap};
			my $choice3 = $matrix[$i][$j - 1] + $points->{gap};

			my @choices = (0, $choice1, $choice2, $choice3);
			my $max = (sort { $a <=> $b } @choices)[-1];
			$matrix[$i][$j] = $max;
		}
	}
}

sub best_score {
	my $bestI;
	my $bestJ;
	my $bestScore = 0;

	foreach my $i (1..length($A) - 1) {
		foreach my $j (1..length($B) - 1) {
			if ($matrix[$i][$j] > $bestScore) {
				$bestScore =  $matrix[$i][$j];
				$bestI = $i;
				$bestJ = $j;
			}
		}
	}
	return ($bestI, $bestJ);
}

sub find_alignment {
	my $alignmentA = "";
	my $alignmentB = "";
	my $totalScore = 0;
	my ($i, $j) = best_score();
	while ($i > 0 && $j > 0) {
		my $score = $matrix[$i][$j];
		my $scoreDiag = $matrix[$i - 1][$j - 1];
		my $scoreUp = $matrix[$i][$j - 1];
		my $scoreLeft = $matrix[$i - 1][$j];
		my $cA = substr($A, $i, 1);
		my $cB = substr($B, $j, 1);
		my $S = score_at($i, $j);

		$totalScore += $score;
		if ($scoreDiag <= 0 &&
		    $scoreUp <= 0 &&
		    $scoreLeft <= 0) {
			last;
		}
		if ($score == $scoreDiag + $S)
		{
			$alignmentA = $cA . $alignmentA;
			$alignmentB = $cB . $alignmentB;
			--$i;
			--$j;
		}
		elsif ($score == $scoreLeft + $points->{gap})
		{
			$alignmentA = $cA . $alignmentA;
			$alignmentB = "-" . $alignmentB;
			--$i;
		}
		elsif ($score == $scoreUp + $points->{gap})
		{
			$alignmentA = "-" . $alignmentA;
			$alignmentB = $cB . $alignmentB;
			--$j;
		}
	}
	return ($alignmentA, $alignmentB, $totalScore);
}

init_matrix();
fill_matrix();

print_matrix();
print "\n";

my ($alA, $alB, $total) = find_alignment();
print "$alA\n$alB\n";
print "Score: $total\n";
