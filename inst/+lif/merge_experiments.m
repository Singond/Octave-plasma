## -*- texinfo -*-
## @deftypefn  {} {@var{merged} =} lif.merge_experiments (@var{s1}, @var{s2}, @dots{})
##
## Merge several LIF data series into one.
##
## Return a new struct @var{merged} whose fields are formed by joining
## the corresponding fields in the arguments @var{s1}, @var{s2}@dots{}.
##
## Generally, the fields are joined as if more images were added to the data.
## Image data (namely @code{img}, @code{imgn} and @code{dark}) are
## concatenated along the third dimension.
## Vectors (@code{pwrdata}, @code{t}, @code{E}) are joined vertically
## to make the result also a vector.
## Image metadata (@code{imgm}, @code{darkm} and @code{pwrmeta}),
## which are originally scalar, are concatenated into struct arrays.
## @end deftypefn
function result = merge_experiments(a)
	if (nargin < 1)
		error("merge_experiments: No argument");
	elseif (nargin > 1)
		error("merge_experiments: Too many arguments");
	elseif (!isstruct(a))
		error("merge_experiments: Argument must be a struct array");
	elseif (numel(a) == 1)
		result = a;
		return;
	end

	result = a(1);
	for s = a(2:end)
		assert(isequal(s.xpos, result.xpos), "x-positions differ");
		assert(isequal(s.ypos, result.ypos), "y-positions differ");

		result.name = [result.name "+" s.name];
		if (!isequal(s.acc, result.acc))
			warning("merge_experiments: numbers of accumulations differ");
		end
		result.img = cat(3, result.img, s.img);
		result.imgm = [result.imgm s.imgm];
		if (isfield(result, "dark") && isfield(s, "dark"))
			result.dark = cat(3, result.dark, s.dark);
			result.darkm = [result.darkm s.darkm];
		end
		if (isfield(result, "pwrdata") && isfield(s, "pwrdata"))
			result.pwrdata = [result.pwrdata; s.pwrdata];
			result.pwrmeta = [result.pwrmeta; s.pwrmeta];
		end

		if (isfield(result, "imgn") && isfield(s, "imgn"))
			result.imgn = cat(3, result.imgn, s.imgn);
		end

		if (isfield(result, "imgt") && isfield(s, "imgt"))
			result.imgt = [result.imgt; s.imgt];
		end
		if (isfield(result, "t") && isfield(s, "t"))
			result.t = [result.t; s.t];
		end
		if (isfield(result, "E") && isfield(s, "E"))
			result.E = [result.E; s.E];
		end
	end

	if (isfield(result, "info") && iscell(result.info))
		result.info{end+1,1} = sprintf("Merged %d series", numel(a));
	end
end
