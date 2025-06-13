## -*- texinfo -*-
## @deftypefn  {} {@var{mask} =} drawellipse @
##     (@var{size}, @var{c}, @var{rx}, @var{ry})
## @deftypefnx {} {@var{mask} =} drawellipse (@var{size}, @var{c}, @var{r})
## @deftypefnx {} {@var{mask} =} drawellipse @
##     (@var{size}, @var{x1}, @var{x2}, @var{y1}, @var{y2})
## @deftypefnx {} {@var{mask} =} drawellipse @
##     (@var{width}, @var{height}, @dots{})
## @deftypefnx {} {@var{mask} =} drawellipse @
##     (@dots{}, @qcode{"smooth"}, @var{smoothval})
##
## Draw ellipse into new image of size (@var{height}, @var{width}).
## @end deftypefn
function m = drawellipse(varargin)
	[height, width, ellipseargs, opts, other] = drawargs(varargin{:});

	switch (length(ellipseargs))
	case 3
		[ctr, rx, ry] = ellipseargs{:};
	case 2
		[ctr, rx] = ellipseargs{:};
		ry = rx;
	case 4
		[x1, x2, y1, y2] = ellipseargs{:};
		ctr = [(x1 + x2) / 2 (y1 + y2) / 2];
		rx = (x1 - x2) / 2;
		ry = (y1 - y2) / 2;
	otherwise
		print_usage();
	end

	x0 = ctr(1);
	y0 = ctr(2);
	fun = @(x, y) ((x - x0) ./ rx).^2 + ((y - y0) ./ ry).^2 < 1;
	m = smoothshape(height, width, fun, opts.smooth);
end
