#' Splits the bulk expression and clinical data into training and validation sets
#'
#' Loads the full bulk expression and clinical data, combines them, performs a
#' random split, and saves the training and validation sets back to disk in
#' the '2_preprocessing/split_data' directory.
#'
#' @param bulk_exp Matrix or data frame of bulk expression data (genes x samples).
#' @param bulk_clinical Data frame of clinical data with samples as rows.
#' @param validation_proportion Numeric value between 0 and 1 specifying the
#'   proportion of samples to allocate to the validation set. Default is 0.15.
#' @param mode Character string specifying the analysis mode. Must be one of
#'   "Classification", "Cox", or "Regression". Default is "Classification".
#' @param seed Integer seed for reproducible random sampling. Default is 123L.
#' @param save_path Optional character string specifying the directory path
#'   to save the split datasets as pickle files. If NULL, datasets are not saved.
#' @param ... Additional arguments (currently unused).
#'
#' @return A list containing four elements:
#'   \item{bulk_exp_train}{Training set expression data (genes x samples)}
#'   \item{bulk_clinical_train}{Training set clinical data}
#'   \item{bulk_exp_val}{Validation set expression data (genes x samples)}
#'   \item{bulk_clinical_val}{Validation set clinical data}
#'
#' @export
generate_val <- function(
  bulk_exp,
  bulk_clinical,
  validation_proportion = 0.15,
  mode = c("Classification", "Cox", "Regression"),
  seed = 123L,
  save_path = NULL,
  ...
) {
  mode <- SigBridgeRUtils::MatchArg(
    mode,
    c("Classification", "Cox", "Regression"),
    NULL
  )
  set.seed(seed)
  combined <- cbind(t(bulk_exp), bulk_clinical)

  nrow_combined <- nrow(combined)
  ncol_combined <- ncol(combined)
  names_combined <- rownames(combined)

  num_val <- floor(nrow_combined * validation_proportion)

  validx <- sample(seq_len(nrow_combined), num_val)

  combined_val <- combined[validx, ]
  combined_train <- combined[-validx, ]
  names_val <- names_combined[validx]
  names_train <- names_combined[-validx]

  if (mode == "Classification" || mode == "Regression") {
    # if mode == "Bionomial":
    # Separate the training and validation sets back into bulkExp and bulkClinical
    bulk_exp_train <- t(combined_train[, -ncol_combined])
    bulk_clinical_train <- combined_train[, ncol_combined]

    bulk_exp_val <- t(combined_val[, -ncol_combined])
    bulk_clinical_val <- combined_val[, ncol_combined]
  } else if (mode == "Cox") {
    bulk_exp_train <- t(combined_train[, -c(ncol_combined - 1, ncol_combined)])
    bulk_clinical_train <- combined_train[, c(ncol_combined - 1, ncol_combined)]

    bulk_exp_val <- t(combined_val[, -ncol_combined])
    bulk_clinical_val <- combined_val[, ncol_combined]
  }

  bulk_exp_train <- as.data.frame(bulk_exp_train)
  bulk_clinical_train <- as.data.frame(bulk_clinical_train)
  bulk_exp_val <- as.data.frame(bulk_exp_val)
  bulk_clinical_val <- as.data.frame(bulk_clinical_val)

  rownames(bulk_clinical_train) <- names_train
  rownames(bulk_clinical_val) <- names_val

  if (!is.null(save_path)) {
    save_path_2 <- file.path(save_path, "2_preprocessing", "split_data")
    pickle_dump(
      reticulate::r_to_py(bulk_exp_train),
      file.path(save_path_2, "bulkExp_train.pkl")
    )
    pickle_dump(
      reticulate::r_to_py(bulk_clinical_train),
      file.path(save_path_2, "bulkClinical_train.pkl")
    )
    pickle_dump(
      reticulate::r_to_py(bulk_exp_val),
      file.path(save_path_2, "bulkExp_val.pkl")
    )
    pickle_dump(
      reticulate::r_to_py(bulk_clinical_val),
      file.path(save_path_2, "bulkClinical_val.pkl")
    )
  }

  list(
    bulk_exp_train = bulk_exp_train,
    bulk_clinical_train = bulk_clinical_train,
    bulk_exp_val = bulk_exp_val,
    bulk_clinical_val = bulk_clinical_val
  )
}
