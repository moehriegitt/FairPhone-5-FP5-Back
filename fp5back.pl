#! /usr/bin/perl

use strict;
use warnings;
use autodie;
use Carp;
use Data::Dumper;

my $th = 161.80;      # total height:
my $tw =  76.00;      # total width:
my $cw =  72.40;      # cover width
my $ch = $cw - $tw + $th; # cover height;
# camera from cover edge
my $ct =   6.45;      # top
my $cl =   6.45;      # left
my $cr =  34.00;      # right
my $cb = 119.90;      # bottom
# camera hole
my $kw =  32.00;      # width (horiz)
my $kh =  32.00;      # height (vert)
# camera opening
my $kd =  13.00;      # diameter
my $ke =   2.00;      # edge
# hole corner
my $kc =  17.00;      # diameter
my $kr =  $kc/2;      # radius
# 45° cutoff of hole
my $kq =  35.40;      # from corner
# cover corner radius
my $ef =   7.50;      # edge to hole
my $eo =   4.62;      # to intersect
my $es =  11.13;      # => radius
# outer corner radius
my $eu =   5.24;      # to intersect
my $et =  12.62;      # => radius
my $er = ($es + ($et - 1.5)) / 2;

my $PI = 3.1415926535897932385;

######################################################################

sub tag($$@)
{
    my $body_attr = (shift @_) // '_body';
    my $name = shift @_;
    my $attr = @_ && (ref($_[0]) eq 'HASH') ? shift @_ : {};
    my $body = [@_];
    $attr->{_tag} = $name;
    $attr->{$body_attr} = $body;
    return $attr;
}

sub svg(@)     { return tag(undef, 'svg',  @_); }
sub g(@)       { return tag(undef, 'g',    @_); }
sub path(@)    { return tag('d',   'path', @_); }

######################################################################

sub is_empty($)
{
    my ($x) = @_;
    return 1 unless defined $x;
    return 1 if !ref($x) && ($x eq '');
    return 1 if (ref($x) eq 'ARRAY') && (@$x == 0);
    return 1 if (ref($x) eq 'HASH')  && (scalar(keys %$x) == 0);
    return 0;
}

sub svg_indent($)
{
    my ($i) = @_;
    return '    ' x $i;
}

sub svg_render_attr($$)
{
    my ($a, $i) = @_;
    my @t = ();
    for my $k (sort keys %$a) {
        my $v = $a->{$k};
        (my $kk = $k) =~ s(_)(-)g;
        $v = join(' ', @$v) if ref($v) eq 'ARRAY';
        $v =~ s(\&)(&amp;)g;
        $v =~ s(\")(&quot;)g;
        push @t, "\n".svg_indent($i).qq($kk="$v");
    }
    return join('', @t);
}

sub svg_render_rec($$;$);
sub svg_render_rec($$;$)
{
    my ($x, $i, $more_attr) = @_;
    return unless defined $x;
    if (ref($x) eq 'ARRAY') {
        return join('', map { svg_render_rec($_, $i) } @$x);
    }
    if (ref($x) eq 'HASH') {
        $more_attr //= {};
        my %attr = (%$x, %$more_attr);
        my $tag  = delete $attr{_tag};
        my $body = delete $attr{_body};
        return svg_indent($i).qq(<$tag).
            svg_render_attr(\%attr, $i+1).
            (is_empty($body) ? qq( />\n)
            :   qq(>\n).
                svg_render_rec($body, $i+1).
                svg_indent($i).qq(</$tag>\n));
    }
    die "ERROR: Cannot render ref='".ref($x)."' object\n";
}

sub svg_render($)
{
    my ($x) = @_;

    return qq(<?xml version="1.0" encoding="UTF-8" standalone="no"?>\n).
        svg_render_rec($x, 0, { xmlns => "http://www.w3.org/2000/svg" });
}

sub sin_deg($)
{
    my ($a) = @_;
    return sin($a / 180 * $PI);
}

sub cos_deg($)
{
    my ($a) = @_;
    return cos($a / 180 * $PI);
}

######################################################################

# SVG frame:
my $sf = 1.00;

# SVG size:
my $sw = int(0.9999 + ($cw + 2*$sf));
my $sh = int(0.9999 + ($ch + 2*$sf));

# 45deg arc coordinate correction:
my $krx = $kr - ($kr * sin_deg(135));
my $kry = -$kr * cos_deg(135);

my $s = svg(
    {
        width => "${sw}mm",
        height => "${sh}mm",
        viewBox => [0, 0, $sw, $sh],
    },
    g(
        {
            fill => "none",
            stroke => "#000000",
            stroke_width => [0.4],
            transform => ['translate(', $sf, $sf, ')'],
        },
        path(
            'M', 0, +$er,
            'a', $er, $er, 90, 0, 1, +$er, -$er,
            'h', +($cw - 2*$er),
            'a', $er, $er, 90, 0, 1, +$er, +$er,
            'v', +($ch - 2*$er),
            'a', $er, $er, 90, 0, 1, -$er, +$er,
            'h', -($cw - 2*$er),
            'a', $er, $er, 90, 0, 1, -$er, -$er,
            'z'
        ),
        undef&&path({ stroke => '#ff0000' },
            'M', $cl, +($ct + $kh - $kr),
            'v', -($kh - 2*$kr),
            'a', $kr, $kr, 90, 0, 1, +$kr, -$kr,
            'h', +($kw - 2*$kr),
            'a', $kr, $kr, 90, 0, 1, +$kr, +$kr,
            'l', -($kw - $kr), +($kh - $kr),
            'a', $kr, $kr, 90, 0, 1, -$kr, -$kr,
            'z',
        ),
        path({ stroke => '#00ff00' },
            'M', $cl, +($ct + $kh - $kr),
            'v', -($kh - 2*$kr),
            'a', $kr, $kr, 90, 0, 1, +$kr, -$kr,
            'h', +($kw - 2*$kr),
            'a', $kr, $kr, 135, 0, 1, +($kr - $krx), +($kr + $kry),
            'l',
                -($kw - 2*$kr),
                +($kh - 2*$kr),
            'A', $kr, $kr, 135, 0, 1, $cl, +($ct + $kh - $kr),
            'z',
        ),
    ));

print svg_render($s);
