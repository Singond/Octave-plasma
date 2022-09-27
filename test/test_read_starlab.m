%!test
%! d = read_starlab("data/starlab/energy.txt");
%! assert(d.name, "PE9");
%! assert(d.units, "J");
%! assert(size(d.t), [1141, 1]);
%! assert(size(d.in), [1141, 1]);
%! assert(d.t(1), 0);
%! assert(d.in(1), 3.21e-5);
%! assert(d.t(end), 22.797);
%! assert(d.in(end), 3.24e-5);

%!warning <No data in>
%! d = read_starlab("data/starlab/no-data.txt");
%! assert(d.t, []);
%! assert(d.in, []);

%!test
%! d = read_starlab("data/starlab/overrange.txt");
%! assert(size(d.t), [8760, 1]);
%! assert(size(d.in), [8760, 1]);
%! assert(d.t(1), 0);
%! assert(d.in(1), 5.5e-7);
%! assert(d.t(4158), 83.734);
%! assert(d.in(4158), nan);
%! assert(sum(isnan(d.in)), 134);

%!test
%! d = read_starlab("data/starlab/overrange.txt", "emptyvalue", -1);
%! assert(d.in(4158), -1);
%! assert(sum(d.in == -1), 134);
