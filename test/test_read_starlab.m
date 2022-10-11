%!test
%! [d, m] = read_starlab("data/starlab/energy.txt");
%! assert(m.name, "PE9");
%! assert(m.units, "J");
%! assert(size(d), [1141, 2]);
%! assert(d(1,1), 0);
%! assert(d(1,2), 3.21e-5);
%! assert(d(end,1), 22.797);
%! assert(d(end,2), 3.24e-5);

%!warning <No data in>
%! d = read_starlab("data/starlab/no-data.txt");
%! assert(d, []);

%!error <Bad file header in>
%! d = read_starlab("test_read_starlab.m");

%!test
%! d = read_starlab("data/starlab/overrange.txt");
%! assert(size(d), [8760, 2]);
%! assert(d(1,1), 0);
%! assert(d(1,2), 5.5e-7);
%! assert(d(4158,1), 83.734);
%! assert(d(4158,2), nan);
%! assert(sum(isnan(d)), [0 134]);

%!test
%! d = read_starlab("data/starlab/overrange.txt", "emptyvalue", -1);
%! assert(d(4158,2), -1);
%! assert(sum(d == -1), [0 134]);
