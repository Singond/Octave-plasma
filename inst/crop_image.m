## -*- texinfo -*-
## @deftypefn  {} {@var{s} =} crop_image (@var{s}, @var{rows}, @var{cols})
## @deftypefnx {} {@var{s} =} crop_image (@dots{}, @qcode{"keepOriginal"})
##
## Crop image data in @var{s} to the region given by @var{rows} and @var{cols}.
##
## The image data are the fields @code{@var{S}.img} and @code{@var{S}.dark}.
## Replace these with their cropped equivalents.
## If the @qcode{"keepOriginal"} option is given, move the original
## data into the fields @code{img_orig} and @code{dark_orig} of @var{s},
## otherwise replace them with their cropped equivalents.
## @end deftypefn
function x = crop_image(x, rows, cols, varargin)
	p = inputParser();
	p.addSwitch("keepOriginal");
	p.parse(varargin{:});
	args = p.Results;

	if (args.keepOriginal)
		x.img_orig = x.img;
		if (isfield(x, "dark"))
			x.dark_orig = x.dark;
		end
	end
	x.img  = x.img (rows(1):rows(2), cols(1):cols(2), :);
	x.imgn = x.imgn(rows(1):rows(2), cols(1):cols(2), :);
	if (isfield(x, "dark"))
		x.dark = x.dark(rows(1):rows(2), cols(1):cols(2), :);
	end
	x.xpos = x.xpos(cols(1):cols(2));
	x.ypos = x.ypos(rows(1):rows(2));
	if (iscell(x.info))
		x.info{end+1,1} = sprintf(
			"Cropped image data to x = [%d, %d], y = [%d, %d]",
			cols(1), cols(2), rows(1), rows(2));
end

%!shared s
%! s.img = [0   0.4 0.6 0.2
%!          0.3 0.9 0.8 0.5
%!          0.2 0.7 0.8 0
%!          0   0.2 0.1 0.1];
%! s.dark = zeros(4);
%! s.xpos = 1:4;
%! s.ypos = (1:4)';

%!test
%! c = crop_image(s, [2 3], [2 4]);
%! assert(c.img, [0.9 0.8 0.5
%!                0.7 0.8 0]);
%! assert(!isfield(c, "img_orig"));

%!test
%! c = crop_image(s, [2 3], [2 4], "keepOriginal");
%! assert(c.img, [0.9 0.8 0.5
%!                0.7 0.8 0]);
%! assert(c.img_orig, s.img);
