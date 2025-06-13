## -*- texinfo -*-
## @deftypefn  {} {} show_mask (@var{img}, @var{mask})
## Show @var{mask} overlayed on @var{img}.
## @end deftypefn
function show_mask(img, mask)
	if (size(img, 3) == 3)
		img = rgb2gray(img);
	endif

	range = [min(img(:)) max(img(:))];
	img -= range(1);
	img /= diff(range);
	img3 = repelem(img, 1, 1, 3);

	maskcolor = [1 0 0];
	masked = (reshape(maskcolor, 1, 1, 3) + img3) ./ 2;
	img4 = reshape(img3, [1 size(img3)]);
	combined = masked .* (1 - mask) + img3 .* mask;
	imshow(combined);
endfunction
