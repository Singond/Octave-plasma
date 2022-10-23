%!error <Bad SPE header in>
%! d = read_princeton_spe("data/starlab/energy.txt");

%!test
%! [~, d] = read_princeton_spe("data/princeton_spe/beam-headeronly.spe");
%! assert(d.version, 2.2, 1e-6);
%! assert(d.xdim, 1024);
%! assert(d.ydim, 256);
%! assert(d.numframes, 61);
%! assert(d.datestr, "15Aug2022");
%! assert(d.accum, 500);
%! assert(d.readouttime, 0.26954, 0.0001);

%!test
%! [~, d] = read_princeton_spe("data/princeton_spe/discharge-headeronly.spe");
%! assert(d.version, 3);
%! assert(d.xdim, 1024);
%! assert(d.ydim, 1024);
%! assert(d.numframes, 50);
