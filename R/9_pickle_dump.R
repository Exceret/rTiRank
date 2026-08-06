#' Save R object to a Python pickle file
#'
#' @param obj An R object to be serialized and saved. It must be transferrable to Python.
#' @param save_path Character string specifying the file path where the pickle file will be saved. Defaults to "./"
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
