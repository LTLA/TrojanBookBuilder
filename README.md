# Trojan Book Packages for the BBS

## Overview

This is a GitHub Action to construct a "trojan package" to sneak books into the Bioconductor Build System (BBS).
To use it, you will need:

- A GitHub repository containing a **bookdown** book, compilable by running `bookdown::render_book` in its top-level directory.
This should have a `DESCRIPTION` file describing all the necessary dependencies.
- A GitHub repository containing the trojan R package, following the Bioconductor requirements for a workflow package.
Non-book dependencies should be listed in `OriginalDepends:`, `OriginalImports:` or `OriginalSuggests:`.

## Effects

This action will "transplant" the book contents into the `vignettes/` subdirectory of the trojan.
Combined with appropriate `Makefile` instructions, this can trick the BBS into compiling the book along with the usual vignettes.
The subsequent tarball will contain the compiled book for downloading and posting online.

The book's dependencies are added to the trojan's `DESCRIPTION` so that the correct packages are available.
Note that this will wipe any existing dependencies, so anything important should instead be listed in the `Original*` fields.
The version and date are also bumped if there were any changes in the trojan's contents due to these actions.

## Deployment

This action should be used in a scheduled GHA workflow in the trojan repository:

```yaml
      - name: Transplant book contents
        uses: LTLA/TrojanBookBuilder@master
        with:
          book: Bioconductor/OrchestratingSingleCellAnalysis
```

It should be used after [`checkout`](https://github.com/actions/checkout) whereupon it will make changes to the workspace;
such changes can be committed with [`create-pull-request`](https://github.com/peter-evans/create-pull-request).

The maintainer is then in charge of merging this into the `master` and pushing it to Bioconductor Git servers.
Unfortunately, I haven't figured out a way of automatically doing that last step.
