#' Save R object to a Python pickle file
#'
#' @param obj An R object to be serialized and saved. It must be transferrable to Python.
#' @param save_path Character string specifying the file path where the pickle file will be saved. Defaults to "./"
#' @param protocol The optional *protocol* argument tells the pickler to use the given protocol;
#'   supported protocols are 0, 1, 2, 3, 4 and 5. The default protocol is 4.
#'   It was introduced in Python 3.4, and is incompatible with previous versions.
#' @param ... pass to python function `pickle.dump()`
#' @param fix_imports If *fix_imports* is TRUE and protocol is less than 3,
#'   pickle will try to map the new Python 3 names to the old module names used in Python2,
#'   so that the pickle data stream is readable with Python 2.
#' @param buffer_callback If *buffer_callback* is NULL (the default), buffer views are serialized into
#'   *file* as part of the pickle stream. It is an error if *buffer_callback* is not NULL
#'   and *protocol* is NULL or smaller than 5.
#' @return Invisible `TRUE` The function is called for its side effect of saving the file
#' @export
pickle_dump <- function(
  obj,
  save_path = NULL,
  protocol = NULL,
  ...,
  fix_imports = TRUE,
  buffer_callback = NULL
) {
  if (is.null(save_path)) {
    save_path <- "./"
  }
  if (!dir.exists(dirname(save_path))) {
    dir.create(dirname(save_path), recursive = TRUE, showWarnings = FALSE)
  }
  # `pickle.dump()` requires a file object (with a `write` method) as its
  # `file` argument, not a path string, so open the file in binary mode and
  # always close it afterwards, even when dumping fails.
  con <- NULL
  on.exit(if (!is.null(con)) con$close(), add = TRUE)
  con <- builtins$open(save_path, "wb")
  pickle$dump(
    obj = obj,
    file = con,
    protocol = protocol,
    ...,
    fix_imports = fix_imports,
    buffer_callback = buffer_callback
  )
  invisible(TRUE)
}
