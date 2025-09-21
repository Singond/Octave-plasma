## -*- texinfo -*-
## @deftypefn  {} {@var{corrected} =} correct_image (@var{img}, @var{dark})
## @deftypefnx {} {[@var{corrected}, @var{info}] =} correct_image (@dots{})
##
## Correct image data @var{img}.
##
## Modify @var{img} by subtracting the dark image @var{dark}
## and clipping negative values to 0.
## Image data @var{img} can be a 2-D matrix representing a single image
## or a higher order array of images stacked along the higher dimensions.
## In this case, correct each image.
##
## Similarly, @var{dark} can be one or more images.
## If multiple @var{dark} images are given, compute their mean
## along the third dimension and use that as the single dark image
## to be subtracted.
##
## In any case, the first two dimensions of @var{img} and @var{dark} must
## match, otherwise throw an error.
##
## The optional second output argument @var{info} contains information
## about the corrections of negative values.
## This is a struct containing the largest and average negative value
## (both as positive numbers), and the standard deviation.
## @end deftypefn
function [img, info] = correct_image(img, dark)
	if (!isequal(size(img)(1:2), size(dark)(1:2)))
		error("correct_image: Dimensions of IMG and DARK do not match.\n");
	end

	## TODO: Eliminate outliers?

	## Subtract dark image, using the mean if there are more
	dark = mean(dark, 3);
	img -= dark;
	neg = img < 0;

	if (nargout > 1)
		info.max = -min(img(neg));
		info.mean = -mean(img(neg));
		info.std = std(img(neg));
	end

	## Clip negative values
	img(neg) = 0;
end

%!shared img, dark
%! img = [
%!   6 7 5 9 1
%!   2 4 3 8 2
%!   0 9 2 8 4
%!   1 3 6 7 1
%!   6 2 0 7 9
%! ];
%! dark = [
%!   0 1 0 1 1
%!   0 0 1 2 1
%!   1 1 0 1 0
%!   2 0 0 0 1
%!   0 2 2 0 1
%! ];

%!assert(correct_image(img, dark), [
%!   6 6 5 8 0
%!   2 4 2 6 1
%!   0 8 2 7 4
%!   0 3 6 7 0
%!   6 0 0 7 8
%! ]);

%!test
%! [corr, info] = correct_image(img, dark);
%! assert(corr, [
%!   6 6 5 8 0
%!   2 4 2 6 1
%!   0 8 2 7 4
%!   0 3 6 7 0
%!   6 0 0 7 8
%! ]);
%! assert(info.max, 2);
%! assert(info.mean, mean([1 1 2]));
%! assert(info.std, std([1 1 2]));
