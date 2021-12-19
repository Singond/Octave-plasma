%!test
%! s = load_fhr1000("data/fhr1000/data-04.txt");
%! assert(s.title, "W_Ar_DC_3Pa_1493W_439V_3_4A");
%! assert(s.acqtime, 0.07);
%! assert(s.accumulations, 20);
%! assert(numel(s.wl), 2830);
%! assert(s.wl(1), 401.001);
%! assert(s.in(1), 665.5);
%! assert(s.wl(end), 413.997);
%! assert(s.in(end), 627.714);
%! assert(s.metadata("grating"), "2400");
%! assert(s.metadata("temperature"), -75.19);
%! assert(s.metadata("total time"), 240);
