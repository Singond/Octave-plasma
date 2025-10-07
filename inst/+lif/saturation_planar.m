function result = saturation_planar(S, varargin)
	if (!isstruct(S))
		print_usage;
		return;
	end

	result = struct([]);
	for s = S
		printf("Fitting saturation to %s\n", s.name);
		[s.a, s.b, s.fits, s.imgsm] = lif.fit_fluorescence_int_planar(
			reshape(s.E, 1, 1, []), s.imgn, 3, varargin{:});
		if (isfield(s, "info") && iscell(s.info))
			s.info{end+1,1} = "Fitted saturation to each pixel";
		end
		result(end+1) = s;
	end
end
