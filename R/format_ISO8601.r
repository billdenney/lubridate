#' Format in ISO8601 character format
#'
#' @param x An object to convert to ISO8601 character format.
#' @param usetz Include the time zone in the formatting (of outputs including
#'   time; date outputs never include time zone information).
#' @param precision The amount of precision to represent with substrings of
#'   "ymdhms", as "y"ear, "m"onth, "d"ay, "h"our, "m"inute, and "s"econd. (e.g.
#'   "ymdhm" would show precision through minutes.  When \code{NULL}, full
#'   precision for the object is shown.
#' @param ... Additional arguments to methods.
#' @return A character vector of ISO8601-formatted text.
#' @examples
#' format_ISO8601(as.Date("02-01-2018", format="%m-%d-%Y"))
#' format_ISO8601(as.POSIXct("2018-02-01 03:04:05", tz="EST"), usetz=TRUE)
#' format_ISO8601(as.POSIXct("2018-02-01 03:04:05", tz="EST"), precision="ymdhm")
#' @export
setGeneric(name = "format_ISO8601",
           def = function(x, usetz=FALSE, precision=NULL, ...) standardGeneric("format_ISO8601"))

#' @rdname format_ISO86901
#' @export
setMethod("format_ISO8601", signature="Date",
          function(x, usetz=FALSE, precision=NULL, ...) {
            precision_format <-
              format_ISO8601_precision_check(precision=precision, max_precision="ymd", usetz=FALSE)
            as.character(x, format=precision_format, usetz=FALSE)
          })

#' @rdname format_ISO86901
#' @export
setMethod("format_ISO8601", signature="POSIXt",
          function(x, usetz=FALSE, precision=NULL, ...) {
            precision_format <-
              format_ISO8601_precision_check(precision=precision, max_precision="ymdhms", usetz=usetz)
            # Note that the usetz argument to as.character is always FALSE because the time zone is handled in the precision argument.
            as.character(x, format=precision_format, usetz=FALSE)
          })

#' @rdname format_ISO86901
#' @export
setMethod("format_ISO8601", signature="Interval",
          function(x, usetz=FALSE, precision=NULL, ...) {
            precision_format <-
              format_ISO8601_precision_check(precision=precision, max_precision="ymdhms", usetz=usetz)
            # Note that the usetz argument to as.character is always FALSE because the time zone is handled in the precision argument.
            sprintf("%s/%s",
                    as.character(x@start, format=precision_format, usetz=FALSE),
                    as.character(x@start + x@.Data, format=precision_format, usetz=FALSE))
          })

#' @rdname format_ISO86901
#' @export
setMethod("format_ISO8601", signature="Duration",
          function(x, usetz=FALSE, precision=NULL, ...) {
            if (!is.null(precision)) {
              warning("precision is not used for Duration objects")
            }
            sprintf("PT%sS", format(x@.Data))
          })

#' @rdname format_ISO86901
#' @export
setMethod("format_ISO8601", signature="Period",
          function(x, usetz=FALSE, precision=NULL, ...) {
            if (!is.null(precision)) {
              warning("precision is not used for Period objects")
            }
            date_part <-
              paste0(
                ifelse(x@year != 0,
                       paste0(x@year, "Y"),
                       ""),
                ifelse(x@month != 0,
                       paste0(x@month, "M"),
                       ""),
                ifelse(x@day != 0,
                       paste0(x@day, "D"),
                       ""))
            time_part <-
              paste0(
                ifelse(x@hour != 0,
                       paste0(x@hour, "H"),
                       ""),
                ifelse(x@minute != 0,
                       paste0(x@minute, "M"),
                       ""),
                ifelse(x@.Data != 0,
                       paste0(x@.Data, "S"),
                       ""))
            mask_neither <- (nchar(date_part) == 0) & (nchar(time_part) == 0)
            time_part[mask_neither] <- "0S"
            ifelse(nchar(time_part),
                   paste0("P", date_part, "T", time_part),
                   paste0("P", date_part))
          })

#' Provide a format for ISO8601 dates and times with the requested precision.
#'
#' @param precision The amount of precision to represent with substrings of
#'   "ymdhms", as "y"ear, "m"onth, "d"ay, "h"our, "m"inute, and "s"econd. (e.g.
#'   "ymdhm" would show precision through minutes.
#' @param max_precision The maximum precision allowed to be output.
#' @param usetz Include the timezone in the output format
#' @return A format string ready for \code{as.character} methods.
#' @details
#' When \code{NULL}, \code{max_precision} is returned.  When \code{precision} is
#' more precise than \code{max_precision}, a warning is given and
#' \code{max_precision} is returned.
format_ISO8601_precision_check <- function(precision, max_precision, usetz=FALSE) {
  precision_map <- list(y="%Y",
                        ym="%Y-%m",
                        ymd="%Y-%m-%d",
                        ymdh="%Y-%m-%dT%H",
                        ymdhm="%Y-%m-%dT%H:%M",
                        ymdhms="%Y-%m-%dT%H:%M:%S")
  if (!(max_precision %in% names(precision_map))) {
    stop("Invalid value for max_precision provided: ", max_precision)
  }
  if (is.null(precision)) {
    precision <- max_precision
  }
  if (!(precision %in% names(precision_map))) {
    stop("Invalid value for precision provided: ", precision)
  }
  if (nchar(precision) > nchar(max_precision)) {
    warning("More precision requested (", precision, ") than allowed (", max_precision, ") for this format.  Using maximum allowed precision.")
    precision <- max_precision
  }
  if (length(precision) != 1) {
    stop("precision must be a scalar")
  }
  ret <- precision_map[[precision]]
  if (usetz) {
    ret <- paste0(ret, "%z")
  }
  ret
}
