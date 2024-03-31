Changelog
=========
This is a changelog for the Octave `singon-plasma` package.

[0.7.1] - 2024-03-31
--------------------
### Fixed
- `fit_voigt` now returns both plain and weighted residuals.
  The weighted residuals are in the `residualw` field of the second
  output value.

[0.7.0] - 2024-03-31
--------------------
### Changed
- Improved the fits returned by `fit_voigt` by performing the fit with
  the peak centered at zero, then moving the data back.
  The function now also returns more structured output in its second
  output argument, including the total residual.

[0.6.0] - 2024-03-27
--------------------
### Added
- More options to control the style of `plot_fit_voigt`.

[0.5.1] - 2024-03-27
--------------------
### Fixed
- Removed warning displayed when running `help fit_voigt`
  caused by a syntax error in the function documentation.

[0.5.0] - 2024-03-27
--------------------
### Added
- Support for fitting Voigt profile to data (see `fit_voigt`).

[0.4.0] - 2024-03-26
--------------------
### Added
- Implemented Voigt profile function (see `voigt`).

[0.3.3] - 2024-03-07
--------------------
### Fixed
- Made the `read_starlab` function compatible with older versions
  of Octave.

[0.3.2] - 2024-02-24
--------------------
Fixed output directory in Github actions to correct missing
artifact in release.

[0.3.1] - 2024-02-24
--------------------
Removed tests from Github actions to fix deployment,
otherwise same as `0.3.0`.

[0.3.0] - 2024-02-23
--------------------
### Added
- Imported function `fit_decay` and `plot_fit_decay`.

### Changed
- Improved the documentation of several functions.

[0.2.0] - 2023-02-19
--------------------
### Added
- Separate handling of over-range values in Starlab files.
- Support for Starlab files with multiple data channels.

### Changed
- Removed `read_starlab` dependency on the `startsWith` function,
  as it is only available in newer Octave versions.

[0.1.0] - 2022-11-25
--------------------
### Added
- Functions to load data from several file formats produced by instruments.
- Function `eedffit` to fit data with common EEDF shapes.
