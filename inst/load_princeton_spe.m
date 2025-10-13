## -*- texinfo -*-
## @deftypefn  {} {@var{x} =} load_princeton_spe (@var{name})
##
## Load experiment data from @emph{Princeton Instruments} SPE file
## and do some common preliminary processing.
##
## Read image data from an SPE file (see @code{read_princeton_spe})
## along with metadata from the header.
## Normalize the intensity in the image to one accumulation,
## estimate times when each image frame was taken
## and subtract dark image, if available.
##
## @var{name} specifies the image to be read.
## This can either be a full file name, or a base name to be combined with
## a pattern to yield the full name (see parameter @qcode{"image"}).
##
## The function accepts the following named parameters:
##
## @table @asis
## @item @qcode{"image"}
## A pattern used to derive the full file name of the base image.
## This is a string where an asterisk (@code{*}) is substituted with the
## base name from the parameter @var{name}.
## If empty, the parameter @var{name} must be a full file name.
## The default value is @qcode{"*.SPE"}.
##
## @item @qcode{"dark"}
## Path to a dark image to be subtracted from image data.
## This can be a file name or a pattern similar to @qcode{"image"}.
## If left empty, no dark image is used.
## If it is a pattern and the image does not exist,
## print a warning.
## If it is a full name (not a pattern) and the image does not exist,
## exit with an error.
## The default value is empty.
##
## @item @qcode{"triggerFrequency"}
## Camera triggering frequency, disregarding number of accumulations per frame.
## This is used to compute times corresponding to individual image frames
## (@code{imgt}).
## (see @code{frametimes_princeton_spe}).
##
## @item @qcode{"triggerDelay"}
## Time offset of image frame times.
## This will be added to every value in @code{imgt}.
## @end table
##
## The return value @var{x} is a struct with the following fields:
##
## @table @asis
## @item @code{img}
## The image data, possibly corrected by subtracting the dark image.
##
## @item @code{imgn}
## Value of @code{img} divided by the number of accumulations.
##
## @item @code{imgt}
## Estimated times corresponding to the beginning and end of each frame.
## in @code{img}.
##
## @item @code{acc}
## Number of accumulations from the image metadata.
## @end table
##
## @seealso{read_princeton_spe}
## @end deftypefn
function x = load_princeton_spe(varargin)
	p = inputParser;
	p.addRequired("basename", @ischar);
	p.addParameter("image", "*.SPE", @ischar);
	p.addParameter("dark", "", @ischar);
	p.addParameter("triggerFrequency", 0, @isnumeric);
	p.addParameter("triggerDelay", 0, @isnumeric);
	p.parse(varargin{:});
	args = p.Results;

	%% Base image
	if (isempty(args.image))
		x.img_filename = args.basename;
	else
		x.img_filename = strrep(args.image, "*", args.basename);
	end
	x.name = args.basename;
	[x.img, x.imgm] = read_princeton_spe(x.img_filename);
	x.xpos = 1:size(x.img, 2);
	x.ypos = (1:size(x.img, 1))';
	x.acc = x.imgm.accum;
	x.readout = x.imgm.readouttime;
	x.info = {["Loaded from " x.img_filename]};

	%% Dark image
	dark = strrep(args.dark, "*", args.basename);
	if (isfile(dark))
		[x.dark, x.darkm] = read_princeton_spe(dark);
		x.dark_filename = dark;
		x.img = correct_image(x.img, x.dark);
		x.info{end+1,1} = sprintf(
			"Subtracted dark image (mean %g, std %g)",
			mean(x.dark(:)), std(x.dark(:)));
	elseif (strcmp(dark, args.dark))
		%% Filename was given exactly
		error("load_princeton_spe: Cannot find file %s", dark);
	elseif (!isempty(args.dark))
		%% Filename was given as pattern: allow missing files
		x.dark = [];
		x.darkm = [];
		warning("load_princeton_spe: No dark image for %s\n", args.basename);
	endif

	%% Correct for number of accumulations
	x.imgn = normalize_image_intensity(x.img, x.acc);
	x.info{end+1,1} = sprintf(
		"Normalized intensity to one accumulation (divided by %d)", x.acc);

	%% Estimate times corresponding to each frame
	if (args.triggerFrequency > 0)
		x.imgt = (frametimes_princeton_spe(x.imgm, 1/args.triggerFrequency) +
			args.triggerDelay);
		x.info{end+1,1} = sprintf(
			"Estimated frame times from frequency %g",
			args.triggerFrequency);
	end
end
