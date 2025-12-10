function [profile, E, profilefun] = beamprofile(b, E=[], dim=1, varargin)
	ip = inputParser;
	ip.addParameter("smooth", [], @isnumeric);
	ip.addParameter("energysmooth", [], @isnumeric);
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
	end

	if (isargout(3))
		profilefun = @(E1) interp1(E, profile', E1, "extrap")';
	end
end
