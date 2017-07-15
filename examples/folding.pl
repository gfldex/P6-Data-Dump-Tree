
use Data::Dump::Tree ;
use Data::Dump::Tree::Foldable ;
use Data::Dump::Tree::DescribeBaseObjects ;

use NCurses;

my $win = initscr() or die "Failed to initialize ncurses\n";
noecho ;
keypad($win, TRUE) ;

LEAVE 
	{
	delwin($win) if $win;
	endwin;
	}

my $f = Data::Dump::Tree::Foldable.new: get_s() , :title<title>, :!color, does => (DDTR::AsciiGlyphs,) ;
my $g = $f.get_view ; $g.set: :page_size<10> ;

loop
	{
	clear ;
	display($g.get_lines) ;
	debug($g) ;
	nc_refresh ;

	my $command = getch ;

	given $command 
		{
		when $_.chr eq 'q' { last }
		when $_.chr eq 'r' { $g = $f.get_view ; $g.set: :page_size<10> }
		when $_.chr eq 'a' { $g.fold_all }
		when $_.chr eq 'u' { $g.unfold_all }

		when $_ eq KEY_UP    { $g.line_up }
		when $_ eq KEY_DOWN  { $g.line_down }
		when $_ eq KEY_PPAGE { $g.page_up }
		when $_ eq KEY_NPAGE { $g.page_down }

		when KEY_LEFT { $g.set: :selected_line(0) ; $g.fold_flip_selected }
		when KEY_RIGHT { }

		when KEY_HOME { $g.set: :top_line(0) }
		when KEY_END { $g.page_down for ^5 }
		}
	}


# -------------------------------

sub display(@lines)
{	
for @lines Z 0..* -> ($line, $index)
	{
	mvaddstr($index, 5, $line) ;
	}

}

# ---------------------------------------------------------------------------------

# DDT header filter to show the folding internal data in a better way 
sub geometry_filter(\r, $s, ($, $path, $glyph, @renderings), (\k, \b, \v, \f, \final, \want_address))
{
r = Data::Dump::Tree::Type::Nothing if k ~~ /'$.foldable'/ ;

if k ~~ /'@.folds'/ 
	{
	try 
		{
		require Text::Table::Simple <&lol2table> ;

		r = lol2table(
			< index skip folded parent >,
			($s.List Z 0..*).map: -> ($d, $i) { [$i, |$d] },
			).join("\n") ;
		}

	@renderings.push: "$!" if $! ;
	}
}

sub debug ($geometry)
{
my @lines =  get_dump_lines $geometry, :title<Geometry>, :header_filters(&geometry_filter,), :!color, :!display_info, :does(DDTR::AsciiGlyphs,) ;

for @lines Z 0..* -> ($line, $index)
	{
	mvaddstr($index, 40, $line) ;
	}
}

# ---------------------------------------------------------------------------------

class Tomatoe{ has $.color ;}

sub get_s
{
        [
        Tomatoe,
        [ [ [ Tomatoe, ] ], ],
	(^5).list,
        123,
	(^5).list,
        Tomatoe.new( color => 'green'),
	(^5).list,
        ] ;
}
