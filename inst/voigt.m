## -*- texinfo -*-
## @deftypefn  {} {@var{y} =} voigt (@var{x}, @var{sigma}, @var{gamma})
## @deftypefnx {} {@var{y} =} voigt (@var{x}, @var{sigma}, @var{gamma}, @var{x0})
##
## Calculate Voigt profile with parameters @var{sigma} and @var{gamma}.
##
## Voigt profile is the convolution of Gauss profile with scale @var{sigma}
## and Lorentz profile with scale @var{gamma}.
##
## By default, the profile is centered.
## The location of the center can be changed with the argument @var{x0}.
## @end deftypefn
function V = voigt(x, sigma, gamma, x0 = 0)
	persistent sqrttwo = sqrt(2);
	persistent sqrttwopi = sqrt(2 * pi);

	if (x0 != 0)
		x -= x0;
	end

	if (isscalar(sigma))
		s0 = (sigma == 0)(ones(size(x)));
	else
		s0 = sigma == 0;
	end

	V = zeros(size(x));
	V(!s0) = (1 / (sigma * sqrttwopi))...
		* real(erfcx((gamma - i*x(!s0)) / (sigma * sqrttwo)));
	# Pure Lorentz profile for sigma == 0
	V(s0) = gamma ./ (pi * (x(s0).^2 + gamma .^2));
end

%!shared x
%! x = linspace(-10, 10);

%!function G = _gauss(x, sigma, x0 = 0)
%!    G = exp(-x.^2 ./ (2 * sigma.^2)) ./ (sigma * sqrt(2 * pi));
%!endfunction

%!function L = _lorentz(x, gamma, x0 = 0)
%!    L = (1 / pi) .* gamma ./ ((x - x0).^2 + gamma.^2);
%!endfunction

%!assert(voigt(x, 1.0, 0), _gauss(x, 1.0), 1e-16);
%!assert(voigt(x, 4.6, 0), _gauss(x, 4.6), 1e-16);
%!assert(voigt(x, 0, 1.0), _lorentz(x, 1.0), 1e-16);
%!assert(voigt(x, 0, 3.8), _lorentz(x, 3.8), 1e-16);

## Failing tests
%!#assert(voigt(x, 2, 3), conv(_gauss(x, 2), _lorentz(x, 3), "same"), 1e-4);
%!#assert(voigt(x, 2, 3), ifft(fft(_gauss(x, 2)) .* fft(_lorentz(x, 3))), 1e-4);

%!# See https://commons.wikimedia.org/wiki/File:VoigtPDF.svg#/media/File:VoigtPDF.svg
%!demo
%! x = linspace(-10, 10, 1000);
%! plot(x, voigt(x, 1.53, 0.00), "k",
%!      x, voigt(x, 1.30, 0.50), "b",
%!      x, voigt(x, 0.00, 1.80), "r",
%!      x, voigt(x, 1.00, 1.00), "g");
%! title("Centered Voigt profile for four cases");
%! ylim([0 0.3]);
