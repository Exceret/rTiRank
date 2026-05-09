#' Normalize gene expression data using z-score normalization (row-wise).
#'
#' @param exp A matrix containing bulk expression data (counts) to be normalized
#' @param ... Additional arguments (currently unused)
#'
#' @return Normalized expression data
#'
#' @details
#' Input should be counts.
#'
#' We don't use `base::scale` here because the difference
#' of ddof between R and Python.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' normalized <- normalize_data(exp_matrix)
#' }
normalize_data <- function(exp, ...) {
  rlang::check_dots_empty0()
  if (!is.matrix(exp)) {
    cli::cli_abort(c(
      "x" = "{.arg exp} is expected to be a {.cls matrix}, \
    but got a {.cls {class(exp)}}"
    ))
  }
  n <- ncol(exp)

  rm <- SigBridgeRUtils::rowMeans3(exp)

  centered <- sweep(exp, 1, rm, "-")

  rsd <- sqrt(SigBridgeRUtils::rowSums3(centered^2) / n)

  rsd[rsd == 0] <- NA

  normalized_exp <- sweep(centered, 1, rsd, "/")
  normalized_exp[
    complete.cases(normalized_exp),
    ,
    drop = FALSE
  ]
}
