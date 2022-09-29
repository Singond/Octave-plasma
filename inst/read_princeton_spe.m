function D = read_princeton_spe(file)
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

	## Parse header (most values may be empty in SPE 3.x)
	D = struct();
	try
		fseek(f, 20);
		D.date = fread(f, 10, "int8");
		fseek(f, 42);
		D.xdim = fread(f, 1, "uint16");
		fseek(f, 108);
		dt = fread(f, 1, "int16");
		switch (dt)
			case 0
				datatype = "float32";
			case 1
				datatype = "int32";
			case 2
				datatype = "int16";
			case 3
				datatype = "uint16";
			case 8
				datatype = "uint32";
			otherwise
				error("Unknown datatype: %d", dt);
		end
		D.datatype = datatype;
		fseek(f, 656);
		D.ydim = fread(f, 1, "uint16");
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

	## Data
	if (D.version < 3)
		fseek(f, 4100);
		data = fread(f, Inf, datatype);
		data = reshape(data, D.xdim, D.ydim, []);
		if (size(data, 3) != D.numframes)
			error("Expected %d frames, found %d.",
				D.numframes, size(data, 3));
		endif
		## Data is in row-major order, Octave expects column-major.
		## Switch first two dimensions to fix this.
		D.data = permute(data, [2 1 3]);
	else
		error("reading SPE version 3.x not implemented yet");
	end
end

%!error <Error reading>
%! nonfile = char(randi([0x60 0x7a], 1, 12));
%! read_princeton_spe(nonfile);
