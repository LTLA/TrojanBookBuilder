# This will clone the book repository and and copy all of the former's contents
# into the latter's vignettes/. It will then check if there is anything to
# commit, and if so, it will bump the version and date of the trojan. 

args <- commandArgs(trailing=TRUE)
book <- args[1]
branch <- args[2]
biocViews <- args[3]
name <- args[4]

##########################################################
################ Downloading the file ####################
##########################################################

tmp <- tempfile(fileext=".tar.gz")
download.file(file.path("https://github.com", book, "tarball", branch), tmp)

target <- "vignettes/book"
tmp2 <- tempfile(tmpdir="vignettes")
untar(tmp, exdir=tmp2)

unlink(target, recursive=TRUE)
file.rename(list.files(tmp2, full.names=TRUE)[1], target)
unlink(tmp2, recursive=TRUE)

unlink(file.path(target, "README.md"))
unlink(file.path(target, ".github"), recursive=TRUE)

##########################################################
############### Updating DESCRIPTION #####################
##########################################################

if (file.exists("DESCRIPTION")) {
    troj.desc <- read.dcf("DESCRIPTION")
    VERSION <- troj.desc[,"Version"]
    DATE <- troj.desc[,"Date"]
} else {
    VERSION <- "0.99.0"
    DATE <- as.character(Sys.date())
}

bpath <- file.path(target, "DESCRIPTION")
book.desc <- read.dcf(bpath)
book.desc <- read.dcf(bpath, keep.white=colnames(book.desc))
book.desc[,"Version"] <- VERSION
book.desc[,"Date"] <- DATE

original.name <- book.desc[,"Package"]
if (name!="*") {
    book.desc[,"Package"] <- name
}

provided <- strsplit(biocViews, split=",")[[1]]
if ("biocViews" %in% colnames(book.desc)) {
    existing <- strsplit(book.desc[,"biocViews"], split=",")[[1]]
    book.desc[,"biocViews"] <- paste(union(provided, existing), collapse=", ")
} else {
    book.desc <- cbind(book.desc, biocViews=paste(provided, collapse=", "))
}

# Not sure if this is still needed?
if ("Workflow" %in% colnames(book.desc)) {
    book.desc[,"Workflow"] <- "True"
} else {
    book.desc <- cbind(book.desc, Workflow="True")
}

# Adding the VignetteBuilder, otherwise the Makefile doesn't get run.
if (!"VignetteBuilder" %in% colnames(book.desc)) {
    book.desc <- cbind(book.desc, VignetteBuilder="knitr")
}

# Humor R CMD build, as bookdown creates RDS files.
if ("Depends" %in% colnames(book.desc)) {
    book.desc[,"Depends"] <- paste0("R (>= 4.0), ", book.desc[,"Depends"])
} else {
    book.desc <- cbind(book.desc, Depends="R (>= 4.0)")
}

write.dcf(book.desc, "DESCRIPTION", keep.white=colnames(book.desc))
unlink(bpath)

##########################################################
############# Inserting the trojan make ##################
##########################################################

write('all: compiled

compiled: 
	cd book && "${R_HOME}/bin/R" -e "bookdown::render_book(\'index.Rmd\')"
	rm -rf book/_bookdown_files
	find book/ -maxdepth 1 -type f -delete
	mkdir -p ../inst && cp -r book/docs ../inst/

clean: 
	rm -rf book/*_cache book/*_files',
    file="vignettes/Makefile")

##########################################################
############### Creating a stub file #####################
##########################################################

# Need this for R CMD build to recognize that there are even
# vignettes to be compiled via a separate Makefile.
write(file="vignettes/stub.Rmd", 
    sprintf("---
title: Source code for %s
package: %s
date: \"`r Sys.Date()`\"
vignette: >
  %%\\VignetteIndexEntry{Source code}
  %%\\VignetteEngine{knitr::rmarkdown}
  %%\\VignetteEncoding{UTF-8}    
output: 
  BiocStyle::html_document:
    titlecaps: false
    toc: false
---

Source code for this book can be found at https://github.com/%s.
", original.name, book.desc[,'Package'], book))

##########################################################
############# Checking for version bump ##################
##########################################################

library(git2r)
changes <- status(".")

if (any(lengths(changes) > 0)) {
    troj.desc <- read.dcf("DESCRIPTION")
    troj.desc <- read.dcf("DESCRIPTION", keep.white=colnames(troj.desc))

    V <- package_version(troj.desc[,"Version"])
    V[1,3] <- as.integer(V[1,3]) + 1
    troj.desc[,"Version"] <- as.character(V)
    troj.desc[,"Date"] <- as.character(Sys.Date())
    write.dcf(troj.desc, "DESCRIPTION", keep.white=colnames(troj.desc))
}
