#' Checks and filters bulk data for common samples.
#'
#' @param bulk_exp A matrix or data frame of bulk expression data with samples as columns
#' @param bulk_clinical A data frame of clinical data with samples as rownames
#' @param save_path Optional path to save the aligned data as pickle files. If NULL, data is not saved.
#' @param ... Additional arguments (currently unused, will error if provided)
#'
#' @return A list containing two elements:
#'   \item{bulk_exp}{The aligned bulk expression matrix with only common samples}
#'   \item{bulk_clinical}{The aligned clinical data frame with only common samples}
#'
#' @details This function performs the following operations:
#' \enumerate{
#'   \item Identifies common samples between expression data (columns) and clinical data (rows)
#'   \item Subsets both datasets to retain only the common samples
#'   \item Optionally saves the aligned data to pickle files in the \code{1_loaddata} subdirectory
#' }
#'
#' @export
check_bulk <- function(bulk_exp, bulk_clinical, save_path = NULL, ...) {
  stopifnot(
    !anyNA(bulk_exp),
    !anyNA(bulk_clinical)
  )
  rlang::check_dots_empty0()
  exp_samples <- colnames(bulk_exp)
  clinical_samples <- rownames(bulk_clinical)

  common_elements <- intersect(exp_samples, clinical_samples)

  if (length(common_elements) == 0) {
    cli::cli_abort(c(
      "x" = "No common elements found between {.arg bulk_exp} and {.arg bulk_clinical}"
    ))
  }

  bulk_exp <- bulk_exp[, common_elements]
  bulk_clinical <- bulk_clinical[common_elements, , drop = FALSE]

  if (!is.null(save_path)) {
    dir.create(
      file.path(save_path, "1_loaddata"),
      recursive = TRUE,
      showWarnings = FALSE
    )
    pickle_dump(
      as.data.frame(bulk_exp),
      file.path(
        save_path,
        "1_loaddata",
        "bulk_exp.pkl"
      )
    )
    pickle_dump(
      bulk_clinical,
      file.path(
        save_path,
        "1_loaddata",
        "bulk_clinical.pkl"
      )
    )
  }

  list(bulk_exp = bulk_exp, bulk_clinical = bulk_clinical)
}
