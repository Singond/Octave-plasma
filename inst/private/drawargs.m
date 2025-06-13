## -*- texinfo
## @deftypefn  {} {@var{h}, @var{w}, @var{args}, @var{opts}, @var{other} =} @
##     drawellipse (@var{size}, @var{c}, @var{rx}, @var{ry})
##
## Parse arguments to @code{draw*} functions.
## @end deftypefn
function [h, w, args, opts, other] = drawargs(varargin)
	k = 1;
	if (isnumeric(varargin{k}) && isscalar(varargin{k}))
		h = varargin{k++};
		if (k > nargin || !isnumeric(varargin{k}) || !isscalar(varargin{k}))
			print_usage();
		endif
		w = varargin{k++};
	elseif (isnumeric(varargin{k}) && numel(varargin{k}) == 2)
		sizes = varargin{k++};
		h = sizes(1);
		w = sizes(2);
	else
		error("Error parsing sizes");
	endif

	args = {};
	while (k <= length(varargin) && !ischar(varargin{k}))
		args(end+1) = varargin{k++};
	end

	opts = struct;
	opts.smooth = 1;
	other = {};
	while (k <= length(varargin))
		a = varargin{k++};
		if (strcmp(a, "smooth"))
			if (k > length(varargin))
				error("Missing value for parameter SMOOTH");
			end
			opts.smooth = varargin{k++};
		else
			other(end+1) = a;
		end
	end
end
