#!/usr/local/bin/perl -w

# COMP2041 Assignment 2: Simple Shell compiler using perl
# by Samuel Thorley (z5257239) Trimester 2, 2020

while ($line = <>) {
    chomp($line);

    # Subset 3: Preserve leading white space for loop nesting
    my $lead_space = $line;
    $lead_space =~ /^(\s*)/;
    $lead_space = $1;
    $line =~ s/^\s*//;

    # Special perl syntax handling
    # Ignores comments
    if (!($line =~ /^#.*/)) {
        $line =~ s/;/\\;/;
    }

    # Subset 2: Command line arguments
    if ($line =~ /.*\$[0-9]+.*/) {
        my $num = $line;
        $num =~ /.*\$(\d+).*/;
        $num = $1;
        my $new_num = $num - 1;
        $line =~ s/\$$num/\$ARGV[$new_num]/g;
    }

    # Subset 0: Language declaration
    # Following line adapted from Andrew's lecture (week 8 Friday)
    if ($line =~ /^#!\/.*/) {
        $line =~ s/^#!\/.*/#!\/usr\/local\/bin\/perl -w/;

    # Subset 0: Convert echo
    # Subset 2: Single and double quote handling
    } elsif ($line =~ /^echo\s/) {
        if ($line =~ /^echo "/) {
            $line =~ s/^echo "/echo /;
            $line =~ s/"$//;
        } elsif ($line =~ /^echo '/) {
            $line =~ s/^echo '/echo /;
            $line =~ s/'$//;
            $line =~ s/\$/\\\$/g;
        }
        $line =~ s/"/\\"/g;
        $line =~ s/^echo\s/print "/;
        $line .= '\n";';

    # Subset 2: Convert Expr
    # Result of expr stored in variable called '$expr' and printed
    # If statement added to print 0 if false
    } elsif ($line =~ /^expr\s/) {
        $line =~ s/expr\s/\$expr = /;

        $line =~ s/ \\\* / * /g;
        $line =~ s/ \\\>/ >/g;
        $line =~ s/ \\\</ </g;
        $line =~ s/ \\\| / | /g;
        $line =~ s/ \\\& / & /g;

        $line .= ";\n";
        $line .= $lead_space;
        $line .= "if (\$expr eq \"\") {\n";
        $line .= $lead_space;
        $line .= "    \$expr = 0;\n";
        $line .= $lead_space;
        $line .= "}\n";
        $line .= $lead_space;
        $line .= "print \"\$expr\\n\";";
    
    # Subset 0: Convert variable declaration
    # Subset 2: Single and double quote handling
    # Uses double quotes if shell script double quotes or variable given without quotes
    } elsif ($line =~ /\w+=.*/) {
        my $var = $line;
        $var =~ s/=.*$//;
        $var = "\$" . $var;

        my $assign = $line;
        $assign =~ s/.*=//;

        $line = $var . " = ";
        if ($assign =~ /^["'].*/) {
            $line .= $assign;
            $line .= ";";
        } elsif ($assign =~ /^\$/) {
            $line .= '"';
            $line .= $assign;
            $line .= '";';
        } else {
            $line .= "'";
            $line .= $assign;
            $line .= "';";
        }

    # Subset 0: Commenting
    } elsif ($line =~ /^#.*/) {
        # Do nothing
    
    # Subset 1: 'cd' command
    } elsif ($line =~ /\s*cd\s.*/) {
        $line =~ s/cd\s*//;
        $line = "chdir '" . $line;
        $line .= "';";

    # Subset 1: For loops
    } elsif ($line =~ /^for\s.*/) {
        my $var = $line;
        $var =~ s/^for\s(\S*)\sin.*//;
        $var = $1;
        $var = "\$" . $var;

        my $field = $line;
        $field =~ s/.*in //;
        if ($field =~ /\*/ || $field =~ /.*\?/ || $field =~ /.*\[.*\].*/) {
            $field = 'glob("' . $field;
            $field .= '")';
        } else {
            $field = "'" . $field;
            $field =~ s/\s*$//;
            $field =~ s/\b\s+\b/', '/g;
            $field .= "'";
        }
        
        $line = "foreach " . $var;
        $line .= " (";
        $line .= $field;
        $line .= ") {";

    } elsif ($line =~ /^done\s*$/) {
        $line = "}";

    # Subset 2: If statements
    } elsif ($line =~ /^if\s*/) {
        $line =~ s/\s*\{//g;
        $line .= " {";

    } elsif ($line =~ /^elif\s+/) {
        $line =~ s/^elif\s+/} elsif /;
        $line .= " {";

    } elsif ($line =~ /^else\s*$/) {
        $line = "} else {";

    } elsif ($line =~ /^fi\s*$/) {
        $line = "}";

    # Subset 1: Exit command
    } elsif ($line =~ /^exit\s*/) {
        $line .= ";"

    # Subset 1: Read command
    } elsif ($line =~ /^read\s*/) {
        my $var = $line;
        $var =~ /^read\s*(\S+)\s*/;
        $var = $1;
        $var = '$' . $var;

        $line = $var . "= <STDIN>;\n";
        $line .= $lead_space;
        $line .= "chomp $var;";

    # Subset 0: System commands
    } elsif ($line =~ /\S/ && !($line =~ /^do\s*$/) && !($line =~ /^then\s*$/)) {
        $line = 'system "' . $line;
        $line .= '";';
    }

    # Subset 2: Test command with single and double quote handling
    # Variables are double quoted instead of single
    # Handles string and numeric comparisons
    # Values in numeric comparisons unquoted
    if ($line =~ /.*\stest\s.*/) {
        my $var1 = $line;
        if ($line =~ /\s!?=/) {
            $var1 =~ /test\s*(.*)\s!?=/;
            $var1 = $1;
            $var1 =~ s/\s*$//;
            $var1 =~ s/^["']//;
            $var1 =~ s/["']$//;

            my $var2 = $line;
            $var2 =~ /=\s*(.*)\s+{/;
            $var2 = $1;
            $var2 =~ s/\s*$//;
            $var2 =~ s/^["']//;
            $var2 =~ s/["']$//;

            if ($var1 =~ /^\$/) {
                $var1 = '"' . $var1;
                $var1 .= '"';
            } else {
                $var1 = "'" . $var1;
                $var1 .= "'";
            }

            if ($var2 =~ /^\$/) {
                $var2 = '"' . $var2;
                $var2 .= '"';
            } else {
                $var2 = "'" . $var2;
                $var2 .= "'";
            }
            
            $line =~ s/test\s+/\(/g;
            if ($line =~ /\s!=\s/) {
                $line =~ s/\s\(.*\s{/ ($var1 ne $var2) {/g;
            } else {
                $line =~ s/\s\(.*\s{/ ($var1 eq $var2) {/g;
            }
        } else {
            $var1 =~ /test\s*(.*)\s(-eq|-ne|-gt|-lt|-ge|-le)/;
            $var1 = $1;
            $var1 =~ s/\s*$//;
            $var1 =~ s/^["']//;
            $var1 =~ s/["']$//;

            my $var2 = $line;
            $var2 =~ /.*(-eq|-ne|-gt|-lt|-ge|-le)\s+(.*)\s+{/;
            $var2 = $2;
            $var2 =~ s/\s*$//;
            $var2 =~ s/^["']//;
            $var2 =~ s/["']$//;

            if ($var1 =~ /^\$/) {
                $var1 = '"' . $var1;
                $var1 .= '"';
            }

            if ($var2 =~ /^\$/) {
                $var2 = '"' . $var2;
                $var2 .= '"';
            }
            
            $line =~ s/test\s+/\(/g;
            if ($line =~ /\s-ne\s/) {
                $line =~ s/\s\(.*\s{/ ($var1 != $var2) {/g;
            } elsif ($line =~ /\s-eq\s/) {
                $line =~ s/\s\(.*\s{/ ($var1 == $var2) {/g;
            } elsif ($line =~ /\s-lt\s/) {
                $line =~ s/\s\(.*\s{/ ($var1 < $var2) {/g;
            } elsif ($line =~ /\s-le\s/) {
                $line =~ s/\s\(.*\s{/ ($var1 <= $var2) {/g;
            } elsif ($line =~ /\s-gt\s/) {
                $line =~ s/\s\(.*\s{/ ($var1 > $var2) {/g;
            } elsif ($line =~ /\s-ge\s/) {
                $line =~ s/\s\(.*\s{/ ($var1 >= $var2) {/g;
            }
        }
    }
    
    # Ignore lines with 'do' from for and while loops and 'then' from if statements
    if (!($line =~ /^do\s*$/) && !($line =~ /^then\s*$/)) {
        $line = $lead_space . $line;
        print "$line\n";
    }
}