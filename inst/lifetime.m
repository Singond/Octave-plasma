## -*- texinfo -*-
## @deftypefn  {} {@var{tau} =} lifetime (@var{x}, @var{t})
## @deftypefnx {} {@var{tau} =} lifetime (@var{x}, @var{t}, @var{dim})
## @deftypefnx {} {@var{tau} =} lifetime (@dots{}, @
##     @qcode{"limits"}, @code{[@var{tmin}, @var{tmax}]})
## @deftypefnx {} {@var{tau} =} lifetime (@dots{}, @qcode{"smooth"}, @var{k})
## @deftypefnx {} {@var{tau} =} lifetime (@dots{}, @qcode{"progress"})
## @deftypefnx {} {[@var{tau}, @var{tausig}, @var{fits}, @var{xsmooth}] =} @
##     lifetime (@dots{})
##
## Return the lifetime @var{tau} of exponential decay in quantity @var{x}
## given at times @var{t}, fitted to each column of @var{x}.
##
## Lifetime is the length of time over which the quantity drops
## to 1/e of its original value.
##
## With optional parameter @var{dim}, operate along this dimension
## instead of columns.
## Parameter @qcode{"limits"} sets the interval of @var{t} where the fit
## is performed. Values outside this range are ignored.
## If given the @qcode{"progress"} option, display messages periodically
## showing the progress.
##
## Before fitting, values of @var{x} can be smoothed by a convolution
## with the kernel @var{k}. This kernel will be automatically normalized
## so that the sum of all its elements is one.
##
## @end deftypefn
function [tau, tausig, fits, x] = lifetime(varargin)
	p = inputParser;
	p.addRequired("x");
	p.addRequired("t");
	p.addOptional("dim", 1, @isnumeric);
	p.addParameter("limits", [-Inf Inf]);
	p.addParameter("smooth", []);
	p.addSwitch("progress");
	p.parse(varargin{:});

	x = p.Results.x;
	t = p.Results.t;

	## Smoothing
	kernel = p.Results.smooth;
	if (!isempty(kernel))
		kernel = kernel ./ sum(kernel(:));  # normalize
		x = convn(x, kernel, "same");
	end

	## Fit intensity decay to obtain lifetime tau
	args = {t; x;
		"dim"; p.Results.dim;
		"xmin"; p.Results.limits(1);
		"xmax"; p.Results.limits(2)};
	if (p.Results.progress)
		args{end+1} = "progress";
	end
	fits = fit_decay(args{:});
	tau = arrayfun(@(a) a.fite.tau, fits);
	tausig = arrayfun(@(a) a.fite.tausig, fits);  # uncertainty of tau

	## Select valid data points
	tauvalid = arrayfun(@(a) a.fite.cvg, fits);
	tau(!tauvalid) = NaN;
end
