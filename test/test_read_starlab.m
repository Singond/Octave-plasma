%!test
%! [d, m] = read_starlab("data/starlab/energy.txt");
%! assert(m.channels(1).name, "PE9");
%! assert(m.channels(1).units, "J");
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
%! assert(d(4158,2), Inf);
%! assert(sum(isinf(d)), [0 134]);

%!test
%! d = read_starlab("data/starlab/overrange.txt", "overvalue", -1);
%! assert(d(4158,2), -1);
%! assert(sum(d == -1), [0 134]);

%!test
%! [d, m] = read_starlab("data/starlab/twoenergy.txt");
%! assert(m.channels(1).id, "A");
%! assert(m.channels(1).name, "PE9-ES-C");
%! assert(m.channels(1).units, "J");
%! assert(m.channels(2).id, "B");
%! assert(m.channels(2).name, "PE9");
%! assert(m.channels(2).units, "J");
%! assert(size(d), [22, 3]);
%! assert(d, [
%!   21.599   8.140e-7  5.950e-6
%!   21.619   NaN       8.210e-6
%!   21.620   1.633e-6  NaN
%!   21.640   9.210e-7  5.970e-6
%!   21.657   Inf       1.060e-05
%!   21.678   Inf       NaN
%!   21.680   NaN       6.130e-06
%!   21.698   Inf       6.780e-06
%!   21.717   Inf       NaN
%!   21.718   NaN       6.850e-06
%!   56.555   Inf       NaN
%!   56.558   NaN       2.105e-05
%!   56.577   Inf       NaN
%!   56.578   NaN       Inf
%!   56.595   Inf       Inf
%!   56.616   NaN       Inf
%!   56.618   Inf       NaN
%!   56.635   Inf       NaN
%!   56.937   Inf       1.895e-05
%!   70.957   2.084e-6  1.225e-05
%!   109.057  4.960e-7  NaN
%!   109.076  8.500e-7  4.340e-06]);

%!test
%! [d, m] = read_starlab("data/starlab/twoenergy.txt", "emptyvalue", -Inf);
%! assert(d(1,2), 8.140e-7);
%! assert(d(2,2), -Inf);
%! assert(sum(d == -Inf), [0 6 8]);

%!test
%! [d, m] = read_starlab("data/starlab/twoenergy.txt",
%!     "emptyvalue", NA, "overvalue", 0);
%! assert(d(6,1), 21.678);
%! assert(d(6,2), 0);
%! assert(d(6,3), NA);
%! assert(sum(isna(d)), [0 6 8]);
%! assert(sum(d == 0), [0 10 3]);

%!test
%! [d, m] = read_starlab("data/starlab/twoenergy.txt", "overvalue", "max");
%! assert(d(5,2),  2.084e-6);
%! assert(d(14,3), 2.105e-5);
%! # For n "Over" values in a column, the number of max values is n + 1
%! # (n "Over" values plus the original maximum itself).
%! assert(sum(d == 2.084e-6), [0 11 0]);
%! assert(sum(d == 2.105e-5), [0  0 4]);

## Splitting the return value
%!test
%! [d1, d2, m] = read_starlab("data/starlab/twoenergy.txt");
%! assert(d1, [
%!   21.599   8.140e-7
%!   21.620   1.633e-6
%!   21.640   9.210e-7
%!   21.657   Inf
%!   21.678   Inf
%!   21.698   Inf
%!   21.717   Inf
%!   56.555   Inf
%!   56.577   Inf
%!   56.595   Inf
%!   56.618   Inf
%!   56.635   Inf
%!   56.937   Inf
%!   70.957   2.084e-6
%!   109.057  4.960e-7
%!   109.076  8.500e-7]);
%! assert(d2, [
%!   21.599   5.950e-6
%!   21.619   8.210e-6
%!   21.640   5.970e-6
%!   21.657   1.060e-05
%!   21.680   6.130e-06
%!   21.698   6.780e-06
%!   21.718   6.850e-06
%!   56.558   2.105e-05
%!   56.578   Inf
%!   56.595   Inf
%!   56.616   Inf
%!   56.937   1.895e-05
%!   70.957   1.225e-05
%!   109.076  4.340e-06]);

## Reads truncated files (those with less points than specified
## in header), but displays a warning.
%!warning <nonempty values in channel A but header states>
%! d = read_starlab("data/starlab/truncated-data.txt");
%! assert(d(1,1), 0);
%! assert(d(1,2), 3.21e-5);
%! assert(d(end,1), 0.917);
%! assert(d(end,2), 3.08e-5);
