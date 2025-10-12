## -*- texinfo -*-
## @deftypefn  {} {@var{r} =} fit_decay (@var{x}, @var{y})
## @deftypefnx {} {@var{r} =} fit_decay (@dots{}, @var{param}, @var{value})
## @deftypefnx {} {@var{r} =} fit_decay (@dots{}, @qcode{"dim"}, @var{dim})
## @deftypefnx {} {@var{s} =} fit_decay (@var{s})
##
## Fit exponential decay to data.
##
## @var{x} and @var{y} are the x- and y-coordinates of the data points.
##
## The function accepts several optional parameters:
##
## @table @code
##
## @item xmin
## @itemx xmax
## @itemx ymin
## @itemx ymax
## Fit only data where @var{x} is larger than @var{xmin}.
## All other data points will be ignored.
## The options @var{xmax}, @var{ymin} and @var{ymax} are analogous.
## The default values are @code{-Inf} and @code{Inf}, meaning that
## no points are ignored.
## As a special case, setting @var{xmin} to "peak" sets @var{xmin}
## to the value corresponding to maximum @var{y}.
##
## @item dim
## Fit matrix @var{y} along dimension @qcode{"dim"} (see below).
##
## @end table
##
## If @var{y} is a matrix, fit vectors along dimension @var{dim}
## individually, putting the results into a struct array.
## The dimensions of the result are the same as those of @var{y}
## with size in dimension @var{dim} set to one.
## When not specified, the default @var{dim} is one.
##
## If instead of @var{x} and @var{y} a single struct argument @var{s}
## is provided, use its fields @code{@var{s}.t} and @code{@var{s}.in}
## as the arguments @var{x} and @var{y}, respectively,
## and put the fields @code{fitl}, @code{fite} and @code{fitb} directly
## into a copy of @var{s}, which is returned.
## @end deftypefn
function r = fit_decay(varargin)
	pkg load optim;

	## Overload for struct argument
	if (isstruct(varargin{1}))
		x = varargin{1};
		if (nargin > 1)
			fits = fit_decay(x.t, x.in, varargin{2:end});
		else
			fits = fit_decay(x.t, x.in);
		end
		x.fitl = fits.fitl;
		x.fite = fits.fite;
		x.fitb = fits.fitb;
		r = x;
		return;
	end

	p = inputParser;
	p.addRequired("x", @isnumeric);
	p.addRequired("y", @isnumeric);
	p.addParameter("xmin", -Inf);
	p.addParameter("xmax", Inf);
	p.addParameter("ymin", -Inf);
	p.addParameter("ymax", Inf);
	p.addParameter("dim", 1, @isnumeric);
	p.addSwitch("progress");
	p.parse(varargin{:});
	t = p.Results.x;
	in = p.Results.y;
	tmin = p.Results.xmin;
	tmax = p.Results.xmax;
	ymin = p.Results.ymin;
	ymax = p.Results.ymax;
	dim = p.Results.dim;
	progress = p.Results.progress;

	if (ischar(tmin) && strcmp(tmin, "peak"))
		[~, pk] = max(in);
		tmin = t(pk(1));
	elseif (!isnumeric(tmin))
		print_usage();
	end

	## Select region to be fitted
	m = tmin <= t & t <= tmax;

	if (isvector(in))
		m = m & ymin <= in & in <= ymax;
		r = _fit_decay(t(m), in(m));
	else
		## Matrix argument.
		## Process each vector in dimension DIM individually.

		## Check dimensions
		sz = size(in);
		if (length(t) != size(in, dim))
			error("fit_decay: Incompatible dimensions of X and Y");
		end

		## Move dimension DIM to the beginning
		dims = 1:ndims(in);
		otherdims = dims(dims != dim);
		in = permute(in, [dim otherdims]);
		## Squash higher dimensions to obtain a 2D array
		in = reshape(in, length(t), []);

		## Process each column
		r = struct();
		resultsize = sz;
		resultsize(dim) = 1;
		totalk = prod(resultsize);
		for k = 1:columns(in)
			if (progress && mod(k, 10) == 0)
				fprintf(stderr, "fit_decay: %d/%d\n", k, totalk);
			end
			m = m & ymin <= in(:,k) & in(:,k) <= ymax;
			r(k) = _fit_decay(t(m), in(m,k));
		end

		## Make the result match the input in dimensions
		## other than DIM.
		r = reshape(r, resultsize);
	end
end

function x = _fit_decay(t, in)
	## Non-zero elements
	nz = in > 0;

	## Linearized model (preliminary fit)
	[x.fitl.beta, s] = polyfit(t(nz), log(in(nz)), 1);
	x.fitl.tau = -1 / x.fitl.beta(1);
	x.fitl.f = @(t) exp(polyval(x.fitl.beta, t));
	x.fitl.beta_std = s.normr * sqrt(diag(s.C) / s.df);

	model_simple = @(t, b) b(1) .* exp(-t./b(2));
	model_yconst = @(t, b) b(1) .* exp(-t./b(2)) + b(3);

	## Exponential model
	b0 = [exp(x.fitl.beta(2)), x.fitl.tau];
	s = struct();
	[~, s.beta, s.cvg, s.iter] = leasqr(t, in, b0, model_simple, [], 30);
	if (!s.cvg)
		warning("singon-plasma:convergence",...
			"Convergence not reached after %d iterations.", s.iter);
	end
	s.f = @(t) model_simple(t, s.beta);
	s.tau = s.beta(2);
	x.fite = s;

	## Exponential model with constant
	b0 = [exp(x.fitl.beta(2)), x.fite.tau, 0];
	s = struct();
	[~, s.beta, s.cvg, s.iter] = leasqr(t, in, b0, model_yconst, [], 30);
	if (!s.cvg)
		warning("singon-plasma:convergence",...
			"Convergence not reached after %d iterations.", s.iter);
	end
	s.f = @(t) model_yconst(t, s.beta);
	s.tau = s.beta(2);
	s.bg = s.beta(3);
	x.fitb = s;

	## Correct exponential model using new y-intercept
	b0 = x.fitb.beta(1:2);
	s = struct();
	[inm, s.beta, s.cvg, s.iter, s.cor, s.cov]...
		= leasqr(t, in, b0, model_simple, [], 30);
	if (!s.cvg)
		warning("singon-plasma:convergence",...
			"Convergence not reached after %d iterations.", s.iter);
	end
	s.f = @(t) model_simple(t, s.beta);
	s.dof = length(in) - length(s.beta);
	s.resid = sumsq(in - inm);
	s.sig2 = s.resid ./ s.dof;
	s.betacov = s.sig2 * s.cov;
	s.betasig = sqrt(diag(s.betacov));
	s.tau = s.beta(2);
	s.tausig = s.betasig(2);
	x.fite = s;
end

%!shared x, y
%! x = (0:7)';
%! tau = 1.25;
%! y = [87 95 100 * exp(-(1 ./ tau) .* (0:5))]';

## Fit whole data.
## The value -0.60438927 is equal to polyfit(x, log(y), 1)(1).
%!test
%! fit = fit_decay(x, y);
%! assert(fit.fitl.beta(1), -0.60438927, 1e-6);

## Fit the data from the maximum (which is at the start
## of the exponential data and should provide an exact result).
%!test
%! fit = fit_decay(x, y, "xmin", "peak");
%! assert(fit.fitl.tau, 1.25, 1e-12);
%! assert(fit.fitb.tau, 1.25, 1e-12);
%! assert(fit.fite.tau, 1.25, 1e-12);

## Fit the data with x >= 2, which is the same data as above.
%!test
%! fit = fit_decay(x, y, "xmin", 2);
%! assert(fit.fitl.tau, 1.25, 1e-12);
%! assert(fit.fitb.tau, 1.25, 1e-12);
%! assert(fit.fite.tau, 1.25, 1e-12);

## Fit data with background
%!test
%! fit = fit_decay(x, y + 5, "xmin", 2);
%! assert(fit.fitb.tau, 1.25, 1e-12);

## Use a struct argument and preserve its fields.
%!test
%! s = struct;
%! s.t = x;
%! s.in = y;
%! s.myfield = 45;
%! s = fit_decay(s);
%! assert(s.fitl.beta(1), -0.60438927, 1e-6);
%! assert(s.myfield, 45);

%!shared x, y, z
%! x = (0:2)';
%! y = exp([4  3.5  3
%!          3  2.5  2
%!          2  1.5  1]);
%! z = cat(3, y * exp(4), y * exp(2), y);

## Fit 2D matrix along dimension 1 (columns).
%!test
%! fits = fit_decay(x, y);
%! assert(size(fits), [1, 3]);
%! beta = arrayfun(@(c) c.fitl.beta(1), fits);
%! assert(beta, [-1 -1 -1], 1e-12);

## Fit 2D matrix along dimension 2 (rows).
%!test
%! fits = fit_decay(x, y, "dim", 2);
%! assert(size(fits), [3, 1]);
%! beta = arrayfun(@(c) c.fitl.beta(1), fits);
%! assert(beta, [-0.5; -0.5; -0.5], 1e-12);

## Fit 3D matrix along dimension 3.
%!test
%! fits = fit_decay(x, z, "dim", 3);
%! assert(size(fits), [3, 3]);
%! beta = arrayfun(@(c) c.fitl.beta(1), fits);
%! assert(beta, [-2 -2 -2; -2 -2 -2; -2 -2 -2], 1e-12);

## Clipping data (parameter "xmin") in higher dimensions.
%!test
%! x2 = (0:3)';
%! y2 = [exp([3 2 0.8]); y];
%! fits = fit_decay(x2, y2, "xmin", 1);
%! assert(size(fits), [1, 3]);
%! beta = arrayfun(@(c) c.fitl.beta(1), fits);
%! assert(beta, [-1 -1 -1], 1e-12);
