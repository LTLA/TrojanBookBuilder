FROM bioconductor/bioconductor_docker:devel

RUN R --quiet -e "options(warn=2); BiocManager::install('git2r')"

COPY transplant.R /

ENTRYPOINT ["Rscript", "/transplant.R"]
