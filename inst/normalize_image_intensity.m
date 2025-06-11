## -*- texinfo -*-
## @deftypefn  {} {@var{in} =} normalize_image_intensity (@var{raw}, @var{accums})
## @deftypefnx {} {@var{s} =} normalize_image_intensity (@var{s})
##
## Normalize the intensity of image @var{raw}
## by dividing it by the number of accumulations @var{accums}.
##
## If the first argument is a struct @var{s}, operate on its fields
## @code{img} and @code{acc} and return a copy of the struct with
## field @code{in} set to the result.
## @end deftypefn
function r = normalize_image_intensity(varargin)
	if (nargin == 0)
		print_usage;
	end

	if (isstruct(varargin{1}))
		r = varargin{1};
		r.in = normalize_image_intensity(r.img, r.acc);
		return;
	end

	if (nargin < 2)
		print_usage;
	end
	[raw, acc] = varargin{1:2};

	validateattributes(raw, {"numeric"}, {}, 1);
	validateattributes(acc, {"numeric"}, {}, 1);

	r = raw ./ acc;
end

%!shared img
%! img = [
%!   6 7 5 9 1
%!   2 4 3 8 2
%!   0 9 2 8 4
%!   1 3 6 7 1
%!   6 2 0 7 9
%! ];

%!assert(normalize_image_intensity(40*img, 40), img);

%!test
%! img_nd = repmat(img, 1, 1, 3);
%! in = normalize_image_intensity(40 * img_nd, 40);
%! assert(in, img_nd);

%!test
%! x.img = 8 * img;
%! x.acc = 8;
%! x = normalize_image_intensity(x);
%! assert(x.in, img);
%! assert(x.img, 8 * img);
%! assert(x.acc, 8);

