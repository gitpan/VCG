package VCG;

use strict;
use vars qw($AUTOLOAD $VERSION $DEBUG $program);

use IPC::Run qw(run);

$VERSION = '0.2';
$DEBUG = 0;
$program = "xvcg";

=head1 NAME

VCG - Interface to the VCG graphing tool

=head1 SYNOPSIS


  use VCG;
  my $vcg = VCG->new(filename=>'resulta.vcg');
  $vcg->add_node(title => 'aaa');
  $vcg->add_node(title => 'bbb', label='b');
  $vcg->add_node(title => 'ccc', color=>'yellow');

  $vcg->add_edge(source => 'aaa', target=>'bbb');

  $vcg->output_as_pbm('mygraph.pbm');

  my $data = $vcg->as_ppm();
  open (OUTFILE, 'outfile.ppm') or die "error $!\n";
  print OUTFILE $data;
  close OUTFILE;

=head1 DESCRIPTION

This module provides an interface to to the vcg graphing tool. It supports a 
limited selection of options and file formats. The vcg graphing tool homepage 
is currently http://rw4.cs.uni-sb.de/users/sander/html/gsvcg1.html but is being actively
developed elsewhere.

This module is based on Leon Brocard's GraphViz module, it tries
to provide a similar interface to offer some sense of consistency.

VCG is now in active development and although Graph::Writer::VCG already exists,
this module provides a similar interface to graphviz and will be more closely tied
into vcg as it becomes more actively developed - see James Micheal DuPonts announcement
at http://mail.gnome.org/archives/dia-list/2003-February/msg00029.html.

=cut

=head1 METHODS

=head2 new

new objects are created using the constructor method 'new'.

This method accepts name attributes in the form :

my $vcg = VCG->new(outfile=>'foo.ps')
my $vcg = VCG->new(title=>'Dia Dependancies Diagram',debug=>1);
my $vcg = VCG->new();

=cut

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
  $self->{'x'} ||= 30;
  $self->{'y'} ||= 30;
  $self->{title} ||= "untitled";
  $self->{outfile} ||= "vcg.out";

  $DEBUG = 1 if ($config{debug});

  return $self;
}

=head2 add_egde

add_edge allows you to add edges to your vcg object (edges are the lines or relationships between nodes).

In a Finite State Diagram, edges would represent transitions between states.

This method accepts the source, target and colour of the edge :

$vcg->add_edge( source=>'from_node', target=>'to_node');
$vcg->add_edge( source=>'aaa', target=>'bbb', color=>'grey');

=cut

sub add_edge {
  my $self = shift;
  my %args = @_;
  $args{color} ||= 'black';
  my $edge = qq(edge: { sourcename: "$args{source}" targetname: "$args{target}"  color: $args{color}});
  push (@{$self->{edges}}, $edge);
  return 1;
}

=head2 add_node

add_node allows you to add nodes to your vcg object (nodes are the things connected, while edges are the connections).

In a Finite State Diagram, nodes would be the individual states.

This method accepts the label, title and background colour of the node :

$vcg->add_node( title=>'aaa' );
$vcg->add_node( label=>'aaa' );
$vcg->add_node( label=>'aaa', title=>'A', color=>'yellow' );


=cut

sub add_node {
  my $self = shift;
  my %args = @_;
  $args{color} ||= 'white';
  $args{label} ||= $args{title};
  my $node = qq(node: { title: "$args{title}" color: $args{color} label: "$args{label}"});
  push (@{$self->{nodes}}, $node);
  return 1;
}


######################################################################################
# generate the vcg grammar for the graph

sub _get_graph {
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

=head2 as_ps, as_pbm, as_ppm, as_vcg, as_plainvcg

The VCG object allows you to access the output of the vcg tool directly, suitable for using with graphic libraries - although some libraries or older versions may not be able to cope with these formats.

You can access the output in any of postscript, pbm, ppm, vcg (annotated) and vcg (plain) :

my $image_as_ppm = $vcg->as_ppm(); # string of image as formatted as ppm



my $vcg_with_coords = $vcg->as_vcg();

=head2 output_as_ps, output_as_pbm, output_as_ppm

The VCG object allows you to output straight to a file through the vcg tool in any of postscript, pbm and ppm. This functionality requires that the vcg tool be installed.



=head2 output_as_vcg, output_as_plainvcg

The VCG object also allows you to output straight to file in annotated vcg with coordinates, or plain vcg syntax. The plain syntax does not require the vcg tool to be installed.

=cut

######################################################################################
# Generate magic methods to save typing

sub AUTOLOAD {
  my $self = shift;
  my $type = ref($self)
    or die "$self is not an object";

  my $name = $AUTOLOAD;
  $name =~ s/.*://;   # strip fully-qualified portion

  return if $name =~ /DESTROY/;

  if ($name =~ /^(output_)?as_(ps|pbm|ppm|vcgplain|vcg)$/) {
    my $filename = shift || $self->{config}{outfile};
    my $vcg = $self->_get_graph();
    my $output;
    my $return_file = $1;
    my $filetype = $2;

    if ($filetype eq /vcgplain/) {
      return $vcg unless ($1);
      open OUTFILE,">$filename" or die "couldn't open $filename for output : $!\n";
      print OUTFILE $vcg;
      close OUTFILE;
      return 1;
    }

    run [$program, "-$filetype".'output', $filename, "- "], \$vcg, \$output;
    warn $output if ($DEBUG);
    unless ($1) {
      open (FILE,$filename) or die "unable to open $filename : $!\n";
      my $data = join ('',(<FILE>));
      close FILE;
      return $data;
      unlink $filename or die "unable to remove tempory file $filename : $! \n";
    }
    return $output;
  }
  die "Method $name not defined!";
}

##########################################################################

=head1 SEE ALSO

  GraphViz : http://www.graphviz.org

  GraphViz perl module

  Graph::Writer::VCG perl module

=head1 AUTHOR

Aaron Trevena E<lt>F<aaron@droogs.org>E<gt>

=head1 COPYRIGHT

Copyright (C) 2003, Aaron Trevena, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

##########################################################################

1;

##########################################################################
##########################################################################
