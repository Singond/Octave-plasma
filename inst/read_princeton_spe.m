## -*- texinfo -*-
## @deftypefn  {} {[@var{img}, @var{meta}] =} read_princeton_spe (@var{file})
## @deftypefnx {} {[~, @var{meta}] =} read_princeton_spe (@dots{})
##
## Read data in binary SPE format produced by @emph{Princeton Instruments}
## software.
##
## The file to read from is given in @var{file}.
## This can be a file path or an open file handle.
## The return value @var{img} is the image data arranged into a 3D array,
## where 2D images (frames) are stacked along the third dimension.
## Metadata read from the header can optionally be returned in the second
## return value @var{meta} in the form of a struct with the following fields:
##
## @table @code
## @item  xdim
## @itemx ydim
## The x- and y-dimensions of the image, respectively.
##
## @item numframes
## Number of frames.
##
## @item datatype
## The original data type used to encode the image.
## This can be either @qcode{"int16"}, @qcode{"int32"},
## @qcode{"uint16"}, @qcode{"uint32"} or @qcode{"float32"}.
##
## @item version
## Version of the SPE file format.
##
## @item datestr
## Date of measurement as string.
## This is the raw string as stored in the file with leading and trailing
## whitespace removed.
## Apparently, the format is always @qcode{"08Jul2004"}.
##
## @item accum
## Number of on-chip accumulations.
##
## @item readouttime
## Experiment readout time in seconds.
## (Note that in the file, the time is stored in milliseconds.)
## @end table
##
## If the first output value is ignored (see the last form),
## only the metadata is read and the rest of the file is skipped.
##
## Note that there are several versions of the SPE format,
## only some of which are supported by this function:
##
## @itemize
## @item
## Versions 2.x (and possibly older) start with a 4100 bytes-long header
## which contains information necessary to correctly read the image data
## and some optional metadata.
## This header is followed by the raw image data.
##
## @item
## Versions 3.x retain the header structure, but may leave its values unset.
## Instead, the information required for understanding the data is placed
## in a XML footer at the end of the file.
## Moreover, individual frames in the image data may be followed by frame
## metadata.
## @end itemize
##
## This function supports parsing SPE versions 2.x.
## Versions 3.x are mostly unsupported, because understanding their structure
## requires parsing the XML footer, for which there is no suitable
## implementation in Octave.
## If the version is not supported, the function fails with an error.
##
## However, in some files, the most important values like image dimensions
## or number of frames are also set in the header to make the file
## backward-compatible with older software.
## In this case, this function ignores the footer and tries reading
## the data based on the information in the header, while guessing the
## amount of metadata between frames from the total size.
## This mode of operation is indicated by a warning message.
## Note that it is a hack at best and errors are to be expected.
## @end deftypefn
function [img, D] = read_princeton_spe(file)
	cleanup = [];

	if (ischar(file))
		filename = file;
		[f, fmsg] = fopen(filename, "r", "ieee-le");
		if (f == -1)
			error("read_princeton_spe: Error reading %s: %s", filename, fmsg);
		endif
		cleanup = onCleanup(@() fclose(f));
	elseif (is_valid_file_id(file))
		filename = "stream";
		f = file;
	end
	[~, name, ext] = fileparts(filename);
	basename = [name ext];

	## Parse header (most values may be empty in SPE 3.x)
	D = struct();
	try
		fseek(f, 20);
		date = fread(f, 10, "int8");
		D.datestr = deblank(char(date'));
		fseek(f, 42);
		D.xdim = fread(f, 1, "uint16");
		fseek(f, 108);
		dt = fread(f, 1, "int16");
		fseek(f, 112);
		D.accum = fread(f, 1, "uint16");
		switch (dt)
			case 0
				datatype = "float32";
				datatypesize = 4;
			case 1
				datatype = "int32";
				datatypesize = 4;
			case 2
				datatype = "int16";
				datatypesize = 2;
			case 3
				datatype = "uint16";
				datatypesize = 2;
			case 8
				datatype = "uint32";
				datatypesize = 4;
			otherwise
				error("Unknown datatype: %d", dt);
		end
		D.datatype = datatype;
		fseek(f, 656);
		D.ydim = fread(f, 1, "uint16");
		fseek(f, 672);
		D.readouttime = fread(f, 1, "float32");
		D.readouttime *= 1e-3;  # To seconds
		fseek(f, 678);
		D.footeroffset = fread(f, 1, "uint64");
		fseek(f, 1446);
		D.numframes = fread(f, 1, "int32");
		fseek(f, 1992);
		D.version = fread(f, 1, "float32");
	catch err
		err.message = sprintf(
			"read_princeton_spe: Bad SPE header in %s: %s",
			basename, err.message);
		rethrow(err);
	end

	## Do not read image data if the return value is not requested
	if (!isargout(1))
		return;
	end

	## Read data
	if (D.version < 3)
		fseek(f, 4100);
		data = fread(f, Inf, datatype);
		data = reshape(data, D.xdim, D.ydim, []);
		if (size(data, 3) != D.numframes)
			error("read_princeton_spe: Expected %d frames, found %d.",
				D.numframes, size(data, 3));
		endif
	elseif (D.xdim > 0 && D.ydim > 0 && D.numframes > 0)
		assert(D.footeroffset != 0);
		warning("read_princeton_spe: Reading SPE 3.x in compatibility mode. Errors may occur.\n");

		## Attempt to determine metadata size between frames
		stride = (D.footeroffset - 4100) / D.numframes;
		framesize = D.xdim * D.ydim;
		skip = stride - framesize * datatypesize;
		if (skip > 0)
			warning(
				"read_princeton_spe: Assuming %d bytes of metadata between frames.\n",
				skip);
		else
			warning("read_princeton_spe: Malformed SPE file, footer starts too early.\n");
			skip = 0;
		endif

		data = zeros(D.xdim, D.ydim, D.numframes);
		fseek(f, 4100);
		for k = 1:D.numframes
			data(:,:,k) = reshape(fread(f, framesize, datatype),
				D.xdim, D.ydim);
			fseek(f, skip, SEEK_CUR);
		endfor
	else
		## Properly parsing SPE3.x data requires parsing the XML footer,
		## which is not implemented in Octave.
		error("read_princeton_spe: Reading SPE 3.x not implemented yet.");
	end
	## Data is in row-major order, Octave expects column-major.
	## Switch first two dimensions to fix this.
	img = permute(data, [2 1 3]);
end

%!error <Error reading>
%! nonfile = char(randi([0x60 0x7a], 1, 12));
%! read_princeton_spe(nonfile);
