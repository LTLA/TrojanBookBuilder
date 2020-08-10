# Trojan Book Packages for the BBS

## Overview

This is a GitHub Action to construct a "trojan package" to sneak books into the Bioconductor Build System (BBS).
To use it, you will need:

- A GitHub repository containing a **bookdown** book, compilable by running `bookdown::render_book` in its top-level directory.
This should have a `DESCRIPTION` file describing all the necessary dependencies.
- A GitHub repository containing the trojan R package, minimally containing a `DESCRIPTION` and `vignettes/` subdirectory.
This usually also has `Workflow: True` set to indicate that it should be subjected to workflow builds.

This action will then "transplant" the book contents into the `vignettes/` subdirectory of the trojan,
allowing the latter to be built on the BBS as if it were a regular workflow package.
The subsequent tarball will contain the compiled book for downloading and posting online.

## Deployment

This action should be used in a scheduled GHA workflow in the trojan repository.
It should be used after [`checkout`](https://github.com/actions/checkout) whereupon it will make changes to the workspace;
such changes can be committed with [`create-pull-request`](https://github.com/marketplace/actions/create-pull-request).

The maintainer is then in charge of merging this into the `master` and pushing it to Bioconductor Git servers.
Unfortunately, I haven't figured out a way of automatically doing that last step.
