#' Check if tirank Python module is available
#'
#' @param abort Logical. If TRUE, throw an error when tirank is not available.
#'   If FALSE (default), return FALSE without error.
#'
#' @return Logical. TRUE if tirank module is available, FALSE otherwise.
#'
#' @export
is_tirank_installed <- function(abort = FALSE) {
  if (!reticulate::py_available(initialize = TRUE)) {
    if (abort) {
      cli::cli_abort(c(
        "x" = "Python executable not found in this R session, skip checking {.pkg tirank}.",
        "i" = "Returning {.val FALSE}."
      ))
    }
    return(FALSE)
  }

  # 3. 检查 tirank 模块是否可导入
  is_installed <- reticulate::py_module_available("tirank")

  # 4. 根据 abort 参数决定是否中断
  if (!is_installed && abort) {
    cli::cli_abort(
      "x" = "{.pkg tirank} not installed",
      "i" = "Use {.code conda install -c bioconda tirank}"
    )
  }

  return(is_installed)
}
