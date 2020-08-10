# This will clone the book repository and and copy all of the former's contents
# into the latter's vignettes/. It will then check if there is anything to
# commit, and if so, it will bump the version and date of the trojan. 

##########################################################
################ Downloading the file ####################
##########################################################

location <- commandArgs(trailing=TRUE)
tmp <- tempfile(fileext=".tar.gz")
download.file(file.path("https://github.com", location, "tarball/master"), tmp)

target <- "vignettes/book"
tmp2 <- tempfile()
untar(tmp, exdir=tmp2)

unlink(target, recursive=TRUE)
file.rename(list.files(tmp2, full.names=TRUE)[1], target)

##########################################################
############### Updating dependencies ####################
##########################################################

book.desc <- read.dcf(file.path(target, "DESCRIPTION"))
troj.desc <- read.dcf("DESCRIPTION")
troj.desc <- read.dcf("DESCRIPTION", keep.white=colnames(troj.desc))

.clean <- function(x) {
    x <- sub("^[\n\\s]*", "", x)
    x <- sub("[\n\\s]*$", "", x)
    strsplit(x, ",\n?\\s*")[[1]]
}

for (i in c("Depends", "Imports", "Suggests")) {
    everything <- character(0)

    o <- paste0("Original", i)
    if (o %in% colnames(troj.desc)) {
        everything <- c(everything, .clean(troj.desc[,o]))
    }

    if (i %in% colnames(book.desc)) {
        everything <- c(everything, .clean(book.desc[,i]))
    }

    everything <- sort(unique(everything))
    if (length(everything)) {
        everything <- paste0(everything, collapse=",\n")
        if (i %in% troj.desc) {
            troj.desc[,i] <- everything
        } else {
            extra <- matrix(everything, ncol=1, dimnames=list(NULL, i))
            troj.desc <- cbind(troj.desc, extra) 
        }
    } else if (i %in% troj.desc) {
        troj.desc <- troj.desc[,colnames(troj.desc)!=i,drop=FALSE]
    }
}

write.dcf(troj.desc, "DESCRIPTION", indent=2, keep.white=colnames(troj.desc))

##########################################################
############# Inserting the trojan make ##################
##########################################################

write('all: compiled

# Need to get rebook submitted so this is no longer required.
compiled: 
	for x in $(shell ls book/*.Rmd); do \
		cat $$x | sed "s/rebook/simpleSingleCell/g" > blah; \
		mv blah $$x; \
	done
	cd book && ${R_HOME}/bin/R -e "bookdown::render_book(\'index.Rmd\')"
	rm -rf book/_bookdown_files/

clean: 
	rm -rf *_cache *_files',
    file="vignettes/Makefile")

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
    troj.desc[,"Date"] <- Sys.Date()
    write.dcf(troj.desc, "DESCRIPTION", indent=2, keep.white=colnames(troj.desc))
}
