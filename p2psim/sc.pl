#!/usr/local/bin/perl
use strict;

#
# sc.pl <topfile> <eventfile> <protocolfile> (<seed>) < scenerio
# 
# takes as input a scenario and generates topology, event, and protocol file
#
# syntax of a scenario:
#
# protocol: <name>[,<variable>=<value>[ <variable>=<value>[ ...]]]
#     notice that there's only one comma
#     this line has to come first
#
# net: <number of nodes>, <topology>, <placement>
#  <placement> ::= linear | random <number> <number>
#
# event: <node id>, <event-type>, <args>
#
# events: <number of events>, <start>, <interval>, <event-type>, <args>
#

my $line;
my $nnodes;
my $time = 1;
my $protocol;
my @keys;
my $nk = 0;
my @allnodes;
my @deadnodes;

sub main {
  srand($ARGV[3]) if ($#ARGV >= 3);

  open PROT, ">$ARGV[0]" || die "Could not open $ARGV[0]: $!\n";
  open TOP, ">$ARGV[1]" || die "Could not open $ARGV[1]: $!\n";
  open EV, ">$ARGV[2]" || die "Could not open $ARGV[2]: $!\n";

  while ($line = <STDIN>) {
    chomp($line);

    #this is an ugly hack
    if ($line =~ /wellknown\s*=\s*(\d+)/) {
      die if $#allnodes < 0;
      my $well;
      $well = sprintf("%x", $allnodes[$1]);
      $line =~ s/wellknown\s*=\s*\d+/wellknown=$well/;
    }

    if ($line =~/^\s*net:\s*(.*)/) {
      &donet(split(/,\s*/ , $1));
    } elsif ($line =~/^\s*event:\s*(.*)/) {
      &doevent(split(/,\s*/, $1));
    } elsif ($line =~/^\s*events:\s*(.*)/) {
      &doevents(split(/,\s*/, $1));
    } elsif ($line =~/^\s*observe:\s*(.*)/) {
      &doobserve(split(/,\s*/, $1));
    } elsif ($line =~/^\s*protocol:\s*(.*)/) {
      &doprotocol(split(/,\s*/, $1));
    } else {
      print EV "$line\n";
    }
  }

  close TOP || die "Could not close $ARGV[0]: $!\n";
  close EV || die "Could not close $ARGV[1]: $!\n";
  close PROT || die "Could not close $ARGV[2]: $!\n";
}


sub doprotocol {
  my ($prot, $assignments) = @_;
  print "doprotocol: $prot $assignments\n";
  $protocol = $prot;
  print PROT "$prot $assignments\n";
}



sub donet {
  my ($n, $top, $place) = @_;
  print "donet: $n $top $place\n";
  $nnodes = $n;
  print TOP "topology $top\n\n";

  &generate_randnodes($n);
  for (my $i = 1; $i <= $n; $i++) {
    if ($place =~ /random (\d+) (\d+)/) {
      my $x = int(rand $1) + 1;
      my $y = int(rand $2) + 1;
      print TOP "$allnodes[$i] $x,$y\n";
    } elsif ($place == "linear") {
      print TOP "$allnodes[$i] $i,0\n";
    } else {
      print STDERR "Unknown placement $place\n";
      exit (-1);
    }
  }
}



sub doevent {
  my ($n, $type, @args) = @_;
  print "doevent: $n $type @args\n";
  print EV "node $time $allnodes[$n] $type @args\n";
}



sub doevents {
  my ($n, $start, $interval, $distr, $type, @args) = @_;
  my $node = 1;
  $time = $start;
  print "doevents: $n $start $interval $distr $type @args\n";
  for (my $i = 1; $i <= $n; $i++) {
    if ($distr =~ /linear/) {
      $node = ($node % $nnodes) + 1;
    } elsif ($distr =~ /constant/) {
      $node = 1;
    } elsif ($distr =~ /random/) {
      $node =  int(rand ($nnodes-1)) + 2; # this will not ensure all nodes join the network
    }
    if ($type =~ /join/) {
      print EV "node $time $allnodes[$node] $type @args\n";
    } elsif ($type =~ /lookup/) {
      do{
        $node = int(rand ($nnodes)) + 1;
      }while($deadnodes[$node]);
      $keys[$nk] = makekey();
      print EV "node $time $allnodes[$node] $type key=$keys[$nk]\n";
      $nk++;
    } elsif ($type =~ /crash/) {
      while ($deadnodes[$node] == 1) {
        $node = int(rand ($nnodes)) + 1;
      }
      $deadnodes[$node] = 1;
      print EV "node $time $allnodes[$node] $type\n";
    }

    $time = $time + $interval;
  }
}



sub doobserve {
   my ($start,@args) = @_;
   print EV "observe $start numnodes=$nnodes @args\n";
}

sub makekey {  
  my $id = "0x";
  for(my $i = 0; $i < 16; $i++) {
    my $h = int(rand 16);
    my $c = sprintf "%x", $h;
    $id = $id . $c;
  }
  return $id;
}



sub generate_randnodes {
  my ($n) = @_;
  my %h;
  my $node;
  for (my $i = 1; $i <= $n; $i++) {
#do {
#    $node = int (rand 4294967295);
#  }while (defined($h{$node}) || ($node == 0));
  $h{$node} = 1;
#  $allnodes[$i] = $node;
  $allnodes[$i] = $i;
  $deadnodes[$i] = 0;
  }
}


&main();
