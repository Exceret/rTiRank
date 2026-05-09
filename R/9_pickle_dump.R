#' Save R object to a Python pickle file
#'
#' @param x An R object to be serialized and saved. It must be transferrable to Python.
#' @param save_path Character string specifying the file path where the pickle file will be saved. Defaults to "./"
#' @return Invisible `TRUE` The function is called for its side effect of saving the file
#' @export
pickle_dump <- function(x, save_path = NULL) {
  if (is.null(save_path)) {
    save_path <- "./"
  }
  py_env <- reticulate::py
  py_env$TRANSFER_FROM_R <- reticulate::r_to_py(x)
  reticulate::py_run_string(sprintf(
    "import pickle\nwith open('%s', 'wb') as f:\n\tpickle.dump(TRANSFER_FROM_R, f)",
    save_path
  ))
  invisible(TRUE)
}
