#!/usr/bin/perl
use strict;
use warnings;
use File::Find;

my @files;
find(sub {
    return unless -f $_ && /\.cs$/;
    push @files, $File::Find::name;
}, @ARGV);

my $converted = 0;

for my $file (@files) {
    open my $fh, '<:raw', $file or die "Cannot read $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    $content =~ s/^\xEF\xBB\xBF//;
    next if $content =~ /^namespace\s+.+;/m;
    next if $content !~ /^namespace\s+.+\n\{/m;

    my @lines = split /\n/, $content, -1;

    my $ns_idx = -1;
    for my $i (0 .. $#lines) {
        if ($lines[$i] =~ /^namespace\s+/) { $ns_idx = $i; last; }
    }
    next if $ns_idx == -1;
    next if $lines[$ns_idx + 1] !~ /^\{/;

    # Convert namespace line
    $lines[$ns_idx] =~ s/\r$//;
    $lines[$ns_idx] .= ";";

    # Find namespace closing brace (depth starts at 1 for the removed opening {)
    my $depth = 1;
    my $close_idx = -1;
    for my $i (($ns_idx + 2) .. $#lines) {
        my $l = $lines[$i];
        while ($l =~ /([{}])/g) {
            if ($1 eq '{') { $depth++; }
            else {
                $depth--;
                if ($depth == 0) { $close_idx = $i; last; }
            }
        }
        last if $close_idx != -1;
    }
    next if $close_idx == -1;

    # Build output: before namespace, namespace line, blank line, unindented inner, after
    my @result;
    push @result, @lines[0 .. ($ns_idx - 1)] if $ns_idx > 0;
    push @result, $lines[$ns_idx];  # namespace X;
    push @result, "\r";              # blank line (preserves \r for CRLF)

    # Unindent inner lines (between namespace { and closing })
    for my $i (($ns_idx + 2) .. ($close_idx - 1)) {
        my $line = $lines[$i];
        $line =~ s/\r$//;
        $line =~ s/^    //;
        push @result, $line;
    }

    push @result, @lines[($close_idx + 1) .. $#lines] if $close_idx < $#lines;

    my $new_content = join("\n", @result);
    $new_content .= "\n" unless $new_content =~ /\n$/;

    open my $out, '>:raw', $file or die "Cannot write $file: $!";
    print $out $new_content;
    close $out;
    $converted++;
    print "Converted: $file\n";
}

print "\nDone. Converted: $converted\n";
