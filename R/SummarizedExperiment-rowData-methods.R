## colData-as-GRanges compatibility: allow direct access to GRanges /
## GRangesList colData for select functions

## Not supported:
## 
## Not consistent SummarizedExperiment structure: length, names,
##   as.data.frame, c.
## Length-changing endomorphisms: disjoin, gaps, reduce, unique.
## 'legacy' data types / functions: as "RangedData", as "RangesList",
##   renameSeqlevels, keepSeqlevels.
## Possile to implement, but not yet: Ops, map, window, window<-

## mcols
setMethod(mcols, "SummarizedExperiment",
    function(x, use.names=FALSE, ...)
{
    mcols(rowRanges(x), use.names=use.names, ...)
})

setReplaceMethod("mcols", "SummarizedExperiment",
    function(x, ..., value)
{
    clone(x, rowData=local({
        r <- rowRanges(x)
        mcols(r) <- value
        r
    }))
})

### mcols() is the recommended way for accessing the metadata columns.
### Use of values() or elementMetadata() is discouraged.

setMethod(elementMetadata, "SummarizedExperiment",
    function(x, use.names=FALSE, ...)
{
    elementMetadata(rowRanges(x), use.names=use.names, ...)
})

setReplaceMethod("elementMetadata", "SummarizedExperiment",
    function(x, ..., value)
{
    elementMetadata(rowRanges(x), ...) <- value
    x
})

setMethod(values, "SummarizedExperiment",
    function(x, ...)
{
    values(rowRanges(x), ...)
})

setReplaceMethod("values", "SummarizedExperiment",
    function(x, ..., value)
{
    values(rowRanges(x), ...) <- value
    x
})

## Single dispatch, generic signature fun(x, ...)
local({
    .funs <-
        c("coverage", "disjointBins", "duplicated", "end", "end<-",
          "flank", "isDisjoint", "narrow", "ranges", "resize",
          "restrict", "seqinfo", "seqnames", "shift", "start",
          "start<-", "strand", "width", "width<-")

    endomorphisms <-
        c(.funs[grepl("<-$", .funs)], "flank", "narrow", "resize",
          "restrict", "shift")

    tmpl <- function() {}
    environment(tmpl) <- parent.frame(2)
    for (.fun in .funs) {
        generic <- getGeneric(.fun)
        formals(tmpl) <- formals(generic)
        fmls <- as.list(formals(tmpl))
        fmls[] <- sapply(names(fmls), as.symbol)
        fmls[[generic@signature]] <- quote(rowRanges(x))
        if (.fun %in% endomorphisms)
            body(tmpl) <- substitute({
                rowRanges(x) <- do.call(FUN, ARGS)
                x
            }, list(FUN=.fun, ARGS=fmls))
        else
            body(tmpl) <-
                substitute(do.call(FUN, ARGS),
                           list(FUN=as.symbol(.fun), ARGS=fmls))
        setMethod(.fun, "SummarizedExperiment", tmpl)
    }
})

setMethod("granges", "SummarizedExperiment",
    function(x, use.mcols=FALSE, ...)
{
    if (!identical(use.mcols, FALSE))
        stop("\"granges\" method for SummarizedExperiment objects ",
             "does not support the 'use.mcols' argument")
    rowRanges(x)
})

## 2-argument dispatch:
## compare / Compare 
## precede, follow, nearest, distance, distanceToNearest
## 
## findOverlaps / countOverlaps, match, subsetByOverlaps: see
## findOverlaps-method.R
.SummarizedExperiment.compare <-
    function(x, y)
{
    if (is(x, "SummarizedExperiment"))
        x <- rowRanges(x)
    if (is(y, "SummarizedExperiment"))
        y <- rowRanges(y)
    compare(x, y)
}

.SummarizedExperiment.Compare <-
    function(e1, e2)
{
    if (is(e1, "SummarizedExperiment"))
        e1 <- rowRanges(e1)
    if (is(e2, "SummarizedExperiment"))
        e2 <- rowRanges(e2)
    callGeneric(e1=e1, e2=e2)
}

.SummarizedExperiment.nearest.missing <-
    function(x, subject, select = c("arbitrary", "all"),
             algorithm = c("nclist", "intervaltree"), ignore.strand = FALSE)
{
    select <- match.arg(select)
    x <- rowRanges(x)
    nearest(x=x, select=select,
            algorithm=match.arg(algorithm), ignore.strand=ignore.strand)
}

.SummarizedExperiment.distance <-
    function(x, y, ignore.strand = FALSE, ...)
{
    if (is(x, "SummarizedExperiment"))
        x <- rowRanges(x)
    if (is(y, "SummarizedExperiment"))
        y <- rowRanges(y)
    distance(x, y, ignore.strand=ignore.strand, ...)
}

.SummarizedExperiment.distanceToNearest <-
    function(x, subject, algorithm = c("nclist", "intervaltree"),
             ignore.strand = FALSE, ...)
{
    if (is(x, "SummarizedExperiment"))
        x <- rowRanges(x)
    if (is(subject, "SummarizedExperiment"))
        subject <- rowRanges(subject)
    distanceToNearest(x, subject, algorithm=match.arg(algorithm),
                      ignore.strand=ignore.strand, ...)
}

local({
    .signatures <- list(
        c("SummarizedExperiment", "ANY"),
        c("ANY", "SummarizedExperiment"),
        c("SummarizedExperiment", "SummarizedExperiment"))

    for (.sig in .signatures) {
        .funs <- c("precede", "follow")
        tmpl <- function(x, subject, select = c("arbitrary", "all"),
                         ignore.strand = FALSE) {}
        environment(tmpl) <- parent.frame(2)
        for (.fun in .funs) {
            body(tmpl) <- substitute({
                select <- match.arg(select)
                if (is(x, "SummarizedExperiment"))
                    x <- rowRanges(x)
                if (is(subject, "SummarizedExperiment"))
                    subject <- rowRanges(subject)
                FUN(x=x, subject=subject, select=select,
                    ignore.strand=ignore.strand)
            }, list(FUN=as.symbol(.fun)))
            setMethod(.fun, .sig, tmpl)
        }
        .funs <- "nearest"
        tmpl <- function(x, subject, select = c("arbitrary", "all"),
                         algorithm=c("nclist", "intervaltree"),
                         ignore.strand = FALSE) {}
        environment(tmpl) <- parent.frame(2)
        for (.fun in .funs) {
            body(tmpl) <- substitute({
                select <- match.arg(select)
                if (is(x, "SummarizedExperiment"))
                    x <- rowRanges(x)
                if (is(subject, "SummarizedExperiment"))
                    subject <- rowRanges(subject)
                FUN(x=x, subject=subject, select=select,
                    ignore.strand=ignore.strand)
            }, list(FUN=as.symbol(.fun)))
            setMethod(.fun, .sig, tmpl)
        }
        setMethod("nearest", c("SummarizedExperiment", "missing"),
            .SummarizedExperiment.nearest.missing)
        setMethod("compare", .sig, .SummarizedExperiment.compare)
        setMethod("Compare", .sig, .SummarizedExperiment.Compare)
        setMethod("distance", .sig, .SummarizedExperiment.distance)
        setMethod("distanceToNearest", .sig,
            .SummarizedExperiment.distanceToNearest)
    }
})

## additional getters / setters

setReplaceMethod("strand", "SummarizedExperiment",
    function(x, ..., value)
{
    strand(rowRanges(x)) <- value
    x
})

setReplaceMethod("ranges", "SummarizedExperiment",
    function(x, ..., value)
{
    ranges(rowRanges(x)) <- value
    x
})

## order, rank, sort

setMethod("order", "SummarizedExperiment",
    function(..., na.last = TRUE, decreasing = FALSE)
{
    args <- lapply(list(...), rowRanges)
    do.call("order",
            c(args, list(na.last=na.last, decreasing=decreasing)))
})

setMethod("rank", "SummarizedExperiment",
    function (x, na.last = TRUE,
              ties.method = c("average", "first", "random", "max", "min"))
{
    ties.method <- match.arg(ties.method)
    rank(rowRanges(x), na.last=na.last, ties.method=ties.method)
})

setMethod("sort", "SummarizedExperiment",
    function(x, decreasing = FALSE, ...)
{
    x[order(rowRanges(x), decreasing=decreasing),]
})

## subset

setMethod("subset", "SummarizedExperiment",
    function(x, subset, select, ...)
{
    i <- S4Vectors:::evalqForSubset(subset, rowRanges(x), ...)
    j <- S4Vectors:::evalqForSubset(select, colData(x), ...)
    x[i, j]
})

## seqinfo (also seqlevels, genome, seqlevels<-, genome<-), seqinfo<-

setMethod(seqinfo, "SummarizedExperiment",
    function(x)
{
    seqinfo(x@rowData)
})

setReplaceMethod("seqinfo", "SummarizedExperiment",
    function (x, new2old = NULL, force = FALSE, value)
{
    if (!is(value, "Seqinfo")) 
        stop("the supplied 'seqinfo' must be a Seqinfo object")
    dangling_seqlevels <-
        GenomeInfoDb:::getDanglingSeqlevels(x@rowData, new2old = new2old,
                                            force = force, seqlevels(value))
    if (length(dangling_seqlevels) != 0L) 
        x <- x[!(seqnames(x) %in% dangling_seqlevels)]
    x@rowData <-
        update(x@rowData,
               seqnames = GenomeInfoDb:::makeNewSeqnames(x, new2old,
                                                         seqlevels(value)),
               seqinfo = value)
    if (is.character(msg <- .valid.SummarizedExperiment(x)))
        stop(msg)
    x
})

## extractROWS, replaceROWS

setMethod("extractROWS", "SummarizedExperiment",
    function(x, i)
{
    ridx <- extractROWS(seq_len(nrow(x)), i)
    x[ridx,]
})

setMethod("replaceROWS", "SummarizedExperiment",
    function (x, i, value)
{
    ridx <- extractROWS(seq_len(nrow(x)), i)
    x[ridx,] <- value
    x
})

setMethod(split, "SummarizedExperiment",
    function(x, f, drop=FALSE, ...) 
{
    splitAsList(x, f, drop=drop)
})
