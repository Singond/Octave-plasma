function varargout = fit_fluorescence_int(varargin)
	persistent geoms = {"planar"};

	## Filter the "geometry" parameter from arguments to be passed on
	k = 0;
	args = {};
	geometry = "planar";
	while ++k <= nargin
		argk = varargin{k};
		if (strncmpi(argk, "geometry", length(argk)))
			## Remove "geometry" parameter and its value
			if (k == nargin)
				error("The 'geometry' parameter requires an argument");
			end
			geometry = validatestring(varargin{++k}, geoms);
		elseif (isstruct(argk) && isfield(argk, "geometry"))
			## Remove "geometry" field from struct
			geometry = argk.geometry;
			args {end+1} = rmfield(argk, "geometry");
		else
			args{end+1} = argk;
		end
	end

	## Call the appropriate fit function with the remaining arguments
	switch (geometry)
		case "planar"
			varargout = nthargout([1:nargout],
				@lif.fit_fluorescence_int_planar, args{:});
		otherwise
			error("Unknown geometry %s\n", geometry);
	end
end

%!shared L, y
%! a = 4;
%! b = 0.2;
%! L = (1:20)';
%! y = (2 * a / b) * (1 - log(1 + b * L) ./ (b .* L));

%!test
%! [af, bf, fit] = lif.fit_fluorescence_int(L, y, "geometry", "planar");
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);

%!test
%! [af, bf, fit] = lif.fit_fluorescence_int(L, y, "geom", "plan");
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);

%!test
%! opts.geometry = "planar";
%! [af, bf, fit] = lif.fit_fluorescence_int(L, y, opts);
%! assert(af, 4, 1e-8);
%! assert(bf, 0.2, 1e-8);
