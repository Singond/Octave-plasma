## -*- texinfo -*-
## @deftypefn  {} {@var{prof} =} lif.beamprofile (@var{b})
## @deftypefnx {} {@var{prof} =} lif.beamprofile (@var{b}, @var{E})
## @deftypefnx {} {@var{prof} =} lif.beamprofile (@var{b}, @var{E}, @var{dim})
## @deftypefnx {} {@var{prof} =} lif.beamprofile (@dots{}, @var{param}, @var{value})
## @deftypefnx {} {[@var{prof}, @var{E}, @var{fn}] =} lif.beamprofile (@dots{})
##
## @table @asis
## @item @qcode{"smooth"}
## Length of window used to smooth the profile in direction @var{dim}.
##
## @item @qcode{"energysmooth"}
## Length of window used to smooth the profile in energy direction.
##
## @item @qcode{"energypolyfit"}
## Degree of polynomial to fit in the energy direction.
## Only one of @qcode{"energysmooth"} and @qcode{"energypolyfit"} may be given.
## @end table
##
## @end deftypefn
function [profile, E, profilefun] = beamprofile(b, E=[], dim=1, varargin)
	ip = inputParser;
	ip.addParameter("smooth", [], @isnumeric);
	ip.addParameter("energysmooth", [], @isnumeric);
	ip.addParameter("energypolyfit", []);
	ip.parse(varargin{:});

	if (!isempty(E) && !isvector(E))
		error("lif.beamprofile: E must be a vector\n");
	end

	## Find which dimension corresponds to the energy vector E
	Edim = 0;
	if (length(E) > 1)
		samedims = find(size(b) == length(E));
		if (!isempty(samedims))
			Edim = samedims(1);
		else
			error("lif.beamprofile: Size mismatch: length(E) is %d, but size(B) is %s\n",
				length(E), sprintf("%dx", size(b))(1:end-1));
		end
	end
	Edim || (Edim = find((1:ndims(b)) != dim)(end));

	## Sum along all other dimensions
	profile = b;
	otherdims = 1:ndims(b);
	otherdims = otherdims(otherdims != dim & otherdims != Edim);
	for d = otherdims
		profile = sum(profile, d);
	end

	## Make sure profiles are columns and energy is rows
	profile = squeeze(permute(profile, [dim Edim otherdims]));

	## Sort by energy (needed for smoothing)
	[E, Eorder] = sort(E(:));
	profile = profile(:,Eorder);

	## Smooth in spatial dimension (assume uniform spacing)
	if (!isempty(win = ip.Results.smooth))
		profile = movmean(profile, win);
	end

	## Smooth in energy dimension (allow non-uniform spacing)
	if (!isempty(win = ip.Results.energysmooth))
		profile = movmean(profile, win, 2, "SamplePoints", E);
	elseif (!isempty(n = ip.Results.energypolyfit))
		polys = polyfitm(E(:)', profile, n, 2);
		EE = repmat(E(:)', rows(profile), 1);
		y = polys(:,1);
		for k = 2:columns(polys)
			y = y .* EE + polys(:,k);
		end
		profile = y;
	end

	if (isargout(3))
		profilefun = @(E1) interp1(E, profile', E1, "extrap")';
	end
end

%!shared bi, b
%! bi = [0 1 1 2 4 7 9 8 6 2 1 1 2 1 0]';
%! b = bi .* [2 4 5 6 7];

%!test
%! [B, E] = lif.beamprofile(b, [2 4 5 6 7]);
%! assert(B, b);

%!test
%! [B, E] = lif.beamprofile(b, [2 4 5 6 7], 1, "smooth", 3);
%! assert(B(:,1), movmean(bi * 2, 3));
%! assert(B(:,2), movmean(bi * 4, 3));
%! assert(B(:,3), movmean(bi * 5, 3));
%! assert(B(:,4), movmean(bi * 6, 3));
%! assert(B(:,5), movmean(bi * 7, 3));

%!test
%! [~, ~, fn] = lif.beamprofile(b, [2 4 5 6 7]);
%! assert(fn(2), bi * 2);  # given value
%! assert(fn(4), bi * 4);  # given value
%! assert(fn(3), bi * 3);  # interpolated value

%!# Higher dimensions
%!shared bi, b
%! bi = [0 1 1 2 4 7 9 8 6 2 1 1 2 1 0]';
%! b = repmat(bi, 1, 8) .* reshape([2 4 5 6 7], 1, 1, []);

%!test
%! [B, E] = lif.beamprofile(b, [2 4 5 6 7]);
%! assert(B, squeeze(sum(b, 2)));
