package VCG;

use strict;
use vars qw($AUTOLOAD $VERSION);

use Carp;
use IPC::Run qw(run);

$VERSION = '0.1';


=head1 NAME

VCG - Interface to the VCG graphing tool

=head1 SYNOPSIS


  use VCG;
  my $vcg = VCG->new(filename=>'resulta.vcg');
  $vcg->add_node(title => 'aaa');
  $vcg->add_node(title => 'bbb', label='b');
  $vcg->add_node(title => 'ccc', color=>'yellow');

  $vcg->add_edge(source => 'aaa', target=>'bbb');

  $vcg->as_pbm('mygraph.pbm');

=head1 DESCRIPTION

This module provides an interface to to the vcg graphing tool. It supports a 
limited selection of options and file formats.

This module is based very heavily on Leon Brocard's GraphViz module, it tries
to provide a similar interface to offer some sense of consistency.

=cut

my $program = "xvcg";

sub new {
  my $class = shift;
  my %config = @_;

  my $self = {};
  bless($self, $class);
  $self->{config} = \%config;
  $self->{edges} = [];
  $self->{nodes} = [];
  $self->{xmax} ||= 700;
  $self->{ymax} ||= 700;
  $self->{x} ||= 30;
  $self->{y} ||= 30;
  $self->{title} ||= "untitled";

  return $self;
}

sub add_edge {
  my $self = shift;
  my %args = @_;
  $args{color} ||= 'black';
  my $edge = qq(edge: { sourcename: "$args{source}" targetname: "$args{target}"  color: $args{color}});
  push (@{$self->{edges}}, $edge);
  return 1;
}

sub add_node {
  my $self = shift;
  my %args = @_;
  $args{color} ||= 'white';
  $args{label} ||= $args{title};
  my $node = qq(node: { title: "$args{title}" color: $args{color} label: "$args{label}"});
  push (@{$self->{nodes}}, $node);
  return 1;
}


sub get_graph {
  my $self = shift;
  my $nodes = join ("\n",@{$self->{nodes}});
  my $edges =  join ("\n",@{$self->{edges}});
  my $graph = <<end;
graph: { title: "$self->{title}"
xmax: $self->{xmax} ymax: $self->{ymax} x: $self->{x} y: $self->{y}
$nodes
$edges
}
end
  return $graph;
}

######################################################################################
# Generate magic methods to save typing

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self)
    or croak "$self is not an object";

  my $name = $AUTOLOAD;
  $name =~ s/.*://;   # strip fully-qualified portion

  return if $name =~ /DESTROY/;

  if ($name =~ /^as_(ps|pbm|ppm)$/) {
    my $filename = shift || $self->{config}{outfile};

    my $vcg = $self->get_graph();
    my $output;
    run [$program, "-$1".'output', $filename, "- "], \$vcg, \$output;
    return;
  }
  croak "Method $name not defined!";
}


##########################################################################

1;

##########################################################################
##########################################################################
