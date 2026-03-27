# Package Identity

This file freezes the current package identity choices for the repository so the
project stops carrying placeholder metadata.

## Decisions

- Package name: `amrcartography`
- Canonical repository title: `AMRC-R-package`
- Maintainer: Andrew Balmer
- Maintainer email: `ab69@sanger.ac.uk`
- License: MIT

## Why these values were chosen

- `amrcartography` is already the package name used in `DESCRIPTION`, `NAMESPACE`,
  documentation, and the first package tarball.
- The maintainer identity was aligned to the local git configuration for this
  repository.
- MIT is a reasonable research-software default while development is still
  moving quickly.

## Follow-up checks before public release

- Confirm that `ab69@sanger.ac.uk` is the best long-term contact address for
  external users.
- Decide whether a lab or consortium should also be included in package metadata.
- Review whether MIT is still the preferred license once the package and
  manuscript are ready for public citation.
