## -*- texinfo -*-
## @deftypefn  {} {@var{p} =} fit_voigt (@var{x}, @var{y})
## @deftypefnx {} {@var{p} =} fit_voigt (@var{x}, @var{y}, @var{weight})
## @deftypefnx {} {@var{p} =} fit_voigt (@dots{}, @var{param}, @var{value})
## @deftypefnx {} {[@var{p}, @var{r}] =} fit_voigt (@dots{})
##
## Fit Voigt profile to data.
##
## Weights of data points can be given in the optional argument
## @var{weight}, which must be an array of the same size as @var{y}.
##
## Behaviour of the fit can be controlled by the following key-value pair:
##
## @table @asis
##
## @item scaleratio
## This is a vector of two numbers, which control how the scale of the
## gaussian peak (@var{sigma}), calculated from the preliminary fit,
## is distributed into the starting scale parameters @var{sigma} and
## @var{gamma} of the Voigt profile.
## The default value is @code{[0.7 0.7]}.
##
## @end table
##
## The return value @var{p} is a vector of the fitted parameters
## to the @code{voigt} function (elements 1:3),
## the vertical scaling parameter (element 4)
## and the background (element 5), which acts as a vertical shift.
##
## More information can be obtained from the optional return value
## @var{r}, which is a struct with information about the preliminary
## approximate fit (@code{r.prefit}) and the resulting fit (other fields).
##
## @seealso{voigt, plot_fit_voigt}
## @end deftypefn
function [p, r] = fit_voigt(x, y, varargin)
	p = inputParser;
	p.addOptional("weight", [], @isnumeric);
	p.addParameter("scaleratio", [0.7 0.7], @isnumeric);
	p.parse(varargin{:});
	wt = p.Results.weight;
	scaleratio = p.Results.scaleratio;

	## Select area around the peak for preliminary fit
	idx = 1:length(y);
	[pk, pki] = max(y);                   # Peak and its location
	threshold = pk - 0.8 * (range(y));    # Ignore values below this
	lowi = find(y < threshold);           # Indices of values below threshold
	left = max(lowi(lowi < pki));
	right = min(lowi(lowi > pki));
	r.prefit.xmin = x(left);
	r.prefit.xmax = x(right);
	m = left:right;

	## Calculate the preliminary fit
	d = min(y(m));
	m = m(y(m) - d > 0);
	p = polyfit(x(m), log(y(m) - d), 2);
	r.prefit.y0 = d;
	r.prefit.p = p;
	r.prefit.sigma = sqrt(-1 / (2 * p(1)));
	r.prefit.x0 = -p(2) / (2 * p(1));
	r.prefit.f = @(x) exp(polyval(p, x)) + d;

	## Choose sample weights
	if (isempty(wt))
		wt = ones(size(y));
	end

	model = @(p, x) p(4) * voigt(x, p(1), p(2), p(3)) + p(5);

	## Initial parameters
	p0 = [scaleratio(1) * r.prefit.sigma;
		scaleratio(1) * r.prefit.sigma;
		r.prefit.x0;
		0;
		r.prefit.y0];
	## Match height
	maxy = max(model(x, p0)(:));
	p0(4) = exp(r.prefit.p(3)) / maxy;

	## Fit
	settings = optimset("weights", wt);
	[r.p, yfit, r.cvg, outp] = nonlin_curvefit(model, p0, x, y, settings);
	r.iter = outp.niter;
	if (!r.cvg)
		warning("Convergence not reached after %d iterations.", r.iter);
	end
	r.sigma = r.p(1);
	r.gamma = r.p(2);
	r.x0 = r.p(3);
	r.yscale = r.p(4);
	r.bg = r.p(5);
	r.residual = sumsq(y - yfit);
	r.f0 = @(x) model(p0, x);
	r.f = @(x) model(r.p, x);

	p = r.p;
end
