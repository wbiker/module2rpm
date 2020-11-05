#!/usr/bin/env raku

my constant DOCDIR = $*PROGRAM.parent.parent.add('doc');

for DOCDIR.IO.dir(test => /'.pod'/) -> $file  {
    write-file($file, "txt", ["raku", "--doc=Text", $file.absolute]);
    write-file($file, "html", ["raku", "--doc=HTML", $file.absolute]);
}

sub write-file($file, $new-extension, @command) {
    my $output-file = $file.extension($new-extension);
    $output-file.unlink if $output-file.e;

    my $proc = run @command, :out;
    my $pod-converted = $proc.out.slurp(:close);
    $output-file.spurt($pod-converted);
}