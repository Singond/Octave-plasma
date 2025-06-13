## -*- texinfo -*-
## @deftypefn  {} {@var{mask} =} drawpolygon (@var{size}, @var{poly})
## @deftypefnx {} {@var{mask} =} drawpolygon (@var{size}, @var{polyx}, @
##     @var{polyy})
## @deftypefnx {} {@var{mask} =} drawpolygon @
##     (@var{width}, @var{height}, @dots{})
## @deftypefnx {} {@var{mask} =} drawpolygon @
##     (@dots{}, @qcode{"smooth"}, @var{smoothval})
## @end deftypefn
function m = drawpolygon(varargin)
	[height, width, varargin, opts, other] = drawargs(varargin{:});

	k = 1;
	if (isnumeric(varargin{k}) && isvector(varargin{k}))
		polyx = varargin{k++};
		if (k > nargin || !isnumeric(varargin{k}) || !isvector(varargin{k}))
			print_usage();
		endif
		polyy = varargin{k++};
	elseif (isnumeric(varargin{k}) && ndims(varargin{k}) == 2
			&& size(varargin{k}, 2) == 2)
		polys = varargin{k++};
		polyx = polys(:,1);
		polyy = polys(:,2);
	else
		print_usage();
	endif

	fun = @(x, y) inpolygon(x, y, polyx, polyy);
	m = smoothshape(height, width, fun, opts.smooth);
endfunction

%!shared checkmask

%!test
%! m = drawpolygon(100, 150, [10 20 80 30], [45 30 50 80]);
%! assert(size(m), [100 150]);
%! checkmask = m;

%!test
%! m = drawpolygon([100 150], [10 20 80 30], [45 30 50 80]);
%! assert(m, checkmask);

%!test
%! m = drawpolygon(100, 150, [10 45; 20 30; 80 50; 30 80]);
%! assert(m, checkmask);

%!test
%! m = drawpolygon([100 150], [10 45; 20 30; 80 50; 30 80]);
%! assert(m, checkmask);
