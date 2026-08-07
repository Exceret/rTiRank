#' Perform sampling on RNA-seq bulk expression data to handle class imbalance
#'
#' @param bulk_exp_train A matrix of bulk expression training data with genes as rows and samples as columns
#' @param bulk_clinical_train Clinical data for training samples, either a vector or a data frame containing the response variable
#' @param mode Sampling method to use. Must be one of "smote", "downsample", "upsample", or "tomeklinks"
#' @param threshold Threshold for determining class imbalance (default: 0.5)
#' @param seed Random seed for reproducibility (default: 123L)
#' @param ... Additional arguments (currently unused)
#'
#' @return A list containing:
#'   \item{bulk_exp_resampled}{Resampled bulk expression matrix with samples as columns}
#'   \item{bulk_clinical_resampled}{Resampled clinical data corresponding to the expression matrix}
#'
#' @details
#' This function applies various sampling techniques to balance class distribution in bulk RNA-seq data.
#' Supported methods include:
#' \itemize{
#'   \item SMOTE: Synthetic Minority Over-sampling Technique
#'   \item downsample: Random under-sampling of majority class
#'   \item upsample: Random over-sampling of minority class
#'   \item tomeklinks: Removes Tomek links to clean up class boundaries
#' }
#'
#' If classes are already balanced (based on the threshold), the function returns the original data unchanged.
#'
#' @export
perform_sampling_on_RNAseq <- function(
  bulk_exp_train,
  bulk_clinical_train,
  mode = c("smote", "downsample", "upsample", "tomeklinks"),
  threshold = 0.5,
  seed = SigBridgeRUtils::getFuncOption("seed") %||% 123L,
  ...
) {
  rlang::check_dots_empty0()
  mode <- SigBridgeRUtils::MatchArg(
    mode,
    c("smote", "downsample", "upsample", "tomeklinks")
  )

  if (!is_imbalanced(bulk_clinical_train, threshold)) {
    ts_cli$cli_alert_info("Classes are balanced")
    return(list(
      bulk_exp_resampled = bulk_exp_train,
      bulk_clinical_resampled = bulk_clinical_train
    ))
  }

  x <- t(bulk_exp_train)
  y <- if (!is.vector(bulk_clinical_train)) {
    bulk_clinical_train[[1]]
  } else {
    bulk_clinical_train
  }

  sampler <- switch(
    mode,
    "smote" = tirank$SMOTE(random_state = seed),
    "downsample" = tirank$RandomUnderSampler(random_state = seed),
    "upsample" = tirank$RandomOverSampler(random_state = seed),
    "tomeklinks" = tirank$TomekLinks()
  )

  x_res <- NULL
  y_res <- NULL
  c(x_res, y_res) %<-% sampler$fit_resample(x, y)

  n_res <- nrow(x_res)
  samples_order <- paste0("sample_", 0:(n_res - 1))

  bulk_exp_resampled <- t(x_res)
  colnames(bulk_exp_resampled) <- samples_order
  rownames(bulk_exp_resampled) <- rownames(bulk_exp_train)

  bulk_clinical_resampled <- as.data.frame(y_res)
  rownames(bulk_clinical_resampled) <- samples_order
  colnames(bulk_clinical_resampled) <- "bulk_clinical_val"

  list(
    bulk_exp_resampled = bulk_exp_resampled,
    bulk_clinical_resampled = bulk_clinical_resampled
  )
}


#' Checks if the primary clinical variable is imbalanced
#'
#' @param bulk_clinical A vector or data.frame containing clinical variable data
#' @param threshold Numeric threshold for imbalance detection (default: 0.5)
#'
#' @return Logical value indicating whether the data is imbalanced (TRUE if minimum proportion is below threshold)
#'
#' @export
is_imbalanced <- function(bulk_clinical, threshold = 0.5) {
  clinical_var <- if (is.vector(bulk_clinical)) {
    bulk_clinical
  } else {
    bulk_clinical[[1]]
  }
  proportions <- prop.table(table(clinical_var))

  if (length(proportions) == 0) {
    cli::cli_warn("No valid data for imbalance check")
    return(FALSE)
  }

  min(proportions) < threshold
}
