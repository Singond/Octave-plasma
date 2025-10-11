## -*- texinfo -*-
## @deftypefn  {} {[@var{a}, @var{b}] =} lif.fit_fluorescence_int_cylindrical @
##   (@var{L}, @var{F})
## @deftypefnx {} {[@var{a}, @var{b}] =} lif.fit_fluorescence_int_cylindrical @
##   (@var{L}, @var{F}, @var{dim})
## @deftypefnx {} {[@var{a}, @var{b}] =} lif.fit_fluorescence_int_cylindrical @
##   (@dots{}, @qcode{"smooth"}, @var{kernel})
## @deftypefnx {} {[@var{a}, @var{b}] =} lif.fit_fluorescence_int_cylindrical @
##   (@dots{}, @qcode{"progress"})
## @deftypefnx {} {[@var{a}, @var{b}, @var{fit}, @var{Fmod}] =} @
##   lif.fit_fluorescence_int_cylindrical (@dots{})
##
## Fit @code{lif.fluorescence_int_cylindrical} to fluorescence data @var{F}
## detected at laser energies @var{L}.
##
## If the optional parameter @qcode{"smooth"} is given, first smooth
## the data @var{F} by convolution with the given @var{kernel}.
## The sum of @var{kernel} need not be equal to one,
## it will be normalized automatically.
##
## The switch @qcode{"progress"} turns on printing messages with progress
## when number of series is large.
##
## Return the parameters @var{a} and @var{b} which minimize the sum
## of squared residuals
## @code{lif.fluorescence_int_cylindrical(@var{L}, @var{a}, @var{b}) - @var{F}}.
##
## The optional return value @var{fit} is a struct with additional
## information about the fit:
## Its field @code{@var{fit}.fitl} (also a struct) describes
## the preliminary polynomial fit, while @code{@var{fit}.fite}
## describes the final fit of the true function.
## In particular, @code{@var{fit}.fite.cvg} is a flag indicating
## whether the fit converged and @code{@var{fit}.fite.iter} is the number
## of iterations.
##
## The return value @var{Fmod} returns data actually used for the fit,
## that is, the argument @var{F} after the modification done by the
## @qcode{"smooth"} parameter.
##
## @seealso{lif.fluorescence_int_cylindrical}
## @end deftypefn
function [a, b, fit, x] = fit_fluorescence_int_cylindrical(varargin)
	pkg load optim;
	pkg load singon-ext;

	p = inputParser;
	p.addRequired("L");
	p.addRequired("x");
	p.addOptional("dim", 1, @isnumeric);
##	p.addParameter("limits", [-Inf Inf]);
	p.addParameter("smooth", []);
	p.addSwitch("progress");
	p.parse(varargin{:});

	x = p.Results.x;

	if (isvector(x) && isvector(p.Results.L))
		fit = fit1(x, p.Results.L);
		a = fit.fite.a;
		b = fit.fite.b;
	else
		## Smoothing
		kernel = p.Results.smooth;
		if (!isempty(kernel))
			kernel = kernel ./ sum(kernel(:));  # normalize
			x = convn(x, kernel, "same");
		end

		## Progress meter
		if (p.Results.progress)
			total = numel(x) / size(x, p.Results.dim);
			pm = ProgressMeter(total,
				"name", "fit_fluorescence_int_cylindrical",
				"every", 10);
		else
			pm = [];
		end

		fit = dimfun(@(x,L) fit1(x, L, pm), p.Results.dim, x, p.Results.L);
		a = arrayfun(@(s) s.fite.a, fit);
		b = arrayfun(@(s) s.fite.b, fit);

		failed = !arrayfun(@(s) s.fite.cvg, fit);
		if (any(failed))
			warning("singon-plasma:convergence",
				"fit_fluorescence_int_cylindrical: Fit failed for %d points out of %d\n",...
				sum(failed(:)), numel(fit));
		end
	end
end

function r = fit1(x, L, pm = [])
	## Print progress info
	if (!isempty(pm))
		pm.increment;
	end

	## Fit with approximate polynomial
	p = polyfit(L, x, logical([1 1 0]));
	r.fitl.a = p(2);
	r.fitl.b = -2 * p(1) ./ r.fitl.a;
	r.fitl.f = @(L) polyval(p, L);

	## Fit with true model, using the previous fit as a starting point
	p0 = [2 * max(r.fitl.a ./ r.fitl.b, 0); max(r.fitl.b, 0)];

	wt = [];
	# wt = x;
	opts = struct;
	opts.bounds = [0 Inf; 0 Inf];
	# warning off backtrace local;
	try
		[~, p, r.fite.cvg, r.fite.iter] = leasqr(L, x, p0,
			@fluorint,
			[], 30, wt, [], @dfluorintdp, opts);
		if (!r.fite.cvg)
			warning(
				"fit_fluorescence_int_cylindrical: Convergence not reached after %d iterations.\n",
				r.fite.iter);
		end
	catch err
		warning("singon-plasma:fit-failed", ...
			"fit_fluorescence_int_cylindrical: Fit failed: %s\n", err.message);
		p = p0;
		r.fite.cvg = false;
		r.fite.iter = 0;
	end
	r.fite.a = p(1) .* p(2);
	r.fite.b = p(2);
	r.fite.f = @(L) lif.fluorescence_int_cylindrical(L, r.fite.a, r.fite.b);
end

## Private variant of lif.fluorescence_int_cylindrical with a different
## set of the two parameters: p(1) = a/b; p(2) = b
## This should be equivalent to
## lif.fluorescence_int_cylindrical(L, p(1) .* p(2), p(2));
function F = fluorint(L, p)
	F = p(1) * log(1 + p(2) * L);
end

## Derivative of fluorint
function prt = dfluorintdp(L, f, p, dp, F, bounds)
	blp1 = 1 + p(2) .* L;
	prt(:,1) = log(blp1);
	prt(:,2) = p(1) .* L ./ blp1;
end

%!shared L, y
%! a = 4;
%! b = 0.2;
%! L = (1:20)';
%! y = (a / b) * log(1 + b * L);

%!test
%! [af, bf, fit] = lif.fit_fluorescence_int_cylindrical(L, y);
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);
%! assert(fit.fite.a, 4, 1e-8);
%! assert(fit.fite.b, 0.2, 1e-8);

%!test
%! [af, bf, fit] = lif.fit_fluorescence_int_cylindrical(L', y');
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);
%! assert(fit.fite.a, 4, 1e-8);
%! assert(fit.fite.b, 0.2, 1e-8);

%!test
%! LL = reshape(L, 1, 1, []);
%! yy = reshape(y, 1, 1, []) .* [1 2; 3 4];
%! [af, bf] = lif.fit_fluorescence_int_cylindrical(LL, yy, 3);
%! assert(af, [4 8; 12 16], 1e-8);
%! assert(bf, repelem(0.2, 2, 2), 1e-8);

