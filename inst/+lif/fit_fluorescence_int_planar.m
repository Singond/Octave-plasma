function [a, b, fit, x] = fit_fluorescence_int_planar(varargin)
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
				"name", "fit_fluorescence_int_planar",
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
				"fit_fluorescence_int_planar: Fit failed for %d points out of %d\n",...
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
	r.fitl.b = -p(1) * (3 / 2) ./ r.fitl.a;
	r.fitl.f = @(yi,xi,L) polyval(p(yi,xi,:)(:), L);

	## Fit with true model, using the previous fit as a starting point
	p0 = [2 * max(r.fitl.a ./ r.fitl.b, 0); max(r.fitl.b, 0)];

	wt = [];
	# wt = x;
	opts = struct;
	opts.bounds = [0 Inf; 0 Inf];
	# warning off backtrace local;
	try
		[~, p, r.fite.cvg, r.fite.iter] = leasqr(L, x, p0,
			@(L, p) lif.fluorescence_int_planar(L, p),
			[], 30, wt, [], @dfitdp, opts);
		if (!r.fite.cvg)
			warning(
				"fit_fluorescence_int_planar: Convergence not reached after %d iterations.\n",
				r.fite.iter);
		end
	catch err
		warning("singon-plasma:fit-failed", ...
			"fit_fluorescence_int_planar: Fit failed: %s\n", err.message);
		p = p0;
		r.fite.cvg = false;
		r.fite.iter = 0;
	end
	r.fite.a = p(1) .* p(2) ./ 2;
	r.fite.b = p(2);
	r.fite.f = @(L) lif.fluorescence_int_planar(L, p);
end

## Derivative of lif.fluorescence_int_planar
function prt = dfitdp(L, f, p, dp, F, bounds)
	bl = p(2) .* L;
	blp1 = 1 + bl;
	logblp1 = log(blp1);
	prt(:,1) = 1 - logblp1 ./ bl;
	prt(:,2) = p(1) .* (logblp1 ./ (p(2)^2 * L) - 1 ./ (p(2) .* blp1));
end

%!shared L, y
%! a = 4;
%! b = 0.2;
%! L = (1:20)';
%! y = (2 * a / b) * (1 - log(1 + b * L) ./ (b .* L));

%!test
%! [af, bf, fit] = lif.fit_fluorescence_int_planar(L, y);
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);
%! assert(fit.fite.a, 4, 1e-8);
%! assert(fit.fite.b, 0.2, 1e-8);

%!test
%! [af, bf, fit] = lif.fit_fluorescence_int_planar(L', y');
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);
%! assert(fit.fite.a, 4, 1e-8);
%! assert(fit.fite.b, 0.2, 1e-8);

%!test
%! LL = reshape(L, 1, 1, []);
%! yy = reshape(y, 1, 1, []) .* [1 2; 3 4];
%! [af, bf] = lif.fit_fluorescence_int_planar(LL, yy, 3);
%! assert(af, [4 8; 12 16], 1e-8);
%! assert(bf, repelem(0.2, 2, 2), 1e-8);

