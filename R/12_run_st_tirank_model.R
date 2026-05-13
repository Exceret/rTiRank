#' Run the TiRank Model for Spatial Transcriptomics Data
#'
#' Executes the full TiRank pipeline on spatial transcriptomics (ST) data,
#' including gene-pair extraction, model training with hyperparameter tuning,
#' and hub detection. Results are saved to the specified output directory.
#'
#' @param seurat A Seurat object containing the spatial transcriptomics data.
#' @param bulk_exp_train A matrix or data frame of bulk expression data for training.
#' @param bulk_clinical_train A data frame of clinical data corresponding to the training bulk samples.
#' @param bulk_exp_val A matrix or data frame of bulk expression data for validation.
#' @param bulk_clinical_val A data frame of clinical data corresponding to the validation bulk samples.
#' @param save_dir Character. Directory path where results are saved. Default is \code{"./TiRank_res"}.
#' @param device Character. Compute device to use. One of \code{"cuda"} or \code{"cpu"}. Default is \code{"cuda"}.
#' @param load_cache Logical. Whether to load cached intermediate results. Default is \code{FALSE}.
#' @param gpextractor_params A named list of parameters for gene-pair extraction:
#'   \describe{
#'     \item{top_var_genes}{Integer. Number of top variable genes to select. Default is 2000L.}
#'     \item{top_gene_pairs}{Integer. Number of top gene pairs to retain. Default is 1000L.}
#'     \item{p_value_threshold}{Numeric. P-value cutoff for gene-pair significance. Default is 0.05.}
#'     \item{max_cutoff}{Numeric. Maximum correlation cutoff. Default is 0.8.}
#'     \item{min_cutoff}{Numeric. Minimum correlation cutoff. Default is -0.8.}
#'   }
#' @param model_params A named list of parameters for model configuration:
#'   \describe{
#'     \item{batch_size}{Integer. Training batch size. Default is 1024L.}
#'     \item{nhead}{Integer. Number of attention heads (Transformer only). Default is 2L.}
#'     \item{nhid1}{Integer. Size of the first hidden layer. Default is 96L.}
#'     \item{nhid2}{Integer. Size of the second hidden layer. Default is 8L.}
#'     \item{n_output}{Integer. Dimension of the output embedding. Default is 32L.}
#'     \item{nlayers}{Integer. Number of encoder layers. Default is 3L.}
#'     \item{n_pred}{Integer. Number of prediction heads. Default is 2L.}
#'     \item{dropout}{Numeric. Dropout rate. Default is 0.5.}
#'     \item{mode}{Character. Training mode: \code{"Cox"}, \code{"Classification"}, or \code{"Regression"}. Default is \code{"Cox"}.}
#'     \item{encoder_type}{Character. Encoder architecture: \code{"MLP"}, \code{"Transformer"}, or \code{"DenseNet"}. Default is \code{"MLP"}.}
#'     \item{infer_mode}{Character. Inference mode: \code{"SC"} or \code{"ST"}. Default is \code{"ST"}.}
#'     \item{n_trials}{Integer. Number of Optuna hyperparameter optimization trials. Default is 5L.}
#'     \item{do_reject}{Logical. Whether to apply rejection sampling. Default is \code{TRUE}.}
#'     \item{tolerance}{Numeric. Tolerance for rejection. Default is 0.05.}
#'     \item{reject_mode}{Character. Rejection method: \code{"GMM"} or \code{"Strict"}. Default is \code{"GMM"}.}
#'   }
#' @param hub_params A named list of parameters for hub detection:
#'   \describe{
#'     \item{cateCol1}{Character. First categorical column name (e.g., pathological class). Default is \code{"patho_class"}.}
#'     \item{cateCol2}{Character. Second categorical column name (e.g., clustering result). Default is \code{"leiden_clusters"}.}
#'     \item{min_spots}{Integer. Minimum number of spots to consider a hub. Default is 10L.}
#'     \item{perm_n}{Integer. Number of permutations for significance testing. Default is 1001L.}
#'   }
#' @param sc_response_file Character. Path to the Python pipeline script for single-cell response computation.
#'   Default uses \code{system.file("python/Example/sc_pipeline.py", package = "rTiRank")}.
#' @param n_trials Integer. Number of hyperparameter optimization trials. Default is 5L.
#' @param ... Additional arguments:
#'   \describe{
#'     \item{seed}{Integer. Random seed. Default is 123L.}
#'     \item{assay}{Character. Seurat assay name to use. Default is \code{"RNA"}.}
#'   }
#'
#' @return Results are written to \code{save_dir}; the function returns invisibly.
#' @export
run_st_tirank_model <- function(
  seurat,
  bulk_exp_train,
  bulk_clinical_train,
  bulk_exp_val,
  bulk_clinical_val,
  save_dir = "./TiRank_res",
  device = c("cuda", "cpu"),
  load_cache = FALSE,
  gpextractor_params = list(
    top_var_genes = 2000L,
    top_gene_pairs = 1000L,
    p_value_threshold = 0.05,
    max_cutoff = 0.8,
    min_cutoff = -0.8
  ),
  model_params = list(
    batch_size = 1024L,
    nhead = 2L,
    nhid1 = 96L,
    nhid2 = 8L,
    n_output = 32L,
    nlayers = 3L,
    n_pred = 2L,
    dropout = 0.5,
    mode = c("Cox", "Classification", "Regression"),
    encoder_type = c("MLP", "Transformer", "DenseNet"),
    infer_mode = c("SC", "ST"),
    n_trials = 5L,
    do_reject = TRUE,
    tolerance = 0.05,
    reject_mode = c("GMM", "Strict")
  ),
  hub_params = list(
    cateCol1 = "patho_class", # First categorical column (e.g., pathological class)
    cateCol2 = "leiden_clusters", # Second categorical column (e.g., clustering result)
    min_spots = 10L, # Optional: minimum number of spots to consider a hub
    perm_n = 1001L
  ),
  sc_response_file = system.file(
    "python/Example/sc_pipeline.py",
    package = "rTiRank"
  ),
  n_trials = 5L,
  ...
) {
  dots <- rlang::list2(...)
  seed <- dots$seed %||% 123L
  set.seed(seed)

  assay <- dots$assay %||% "RNA"

  if (!is.list(gpextractor_params)) {
    cli::cli_abort(c(
      "x" = "{.arg gpextractor_params} is expected to be an {.cls list}, \
    but got a {.cls {class(gpextractor_params)}}"
    ))
  }
  if (!is.list(model_params)) {
    cli::cli_abort(c(
      "x" = "{.arg model_params} is expected to be an {.cls list}, \
    but got a {.cls {class(model_params)}}"
    ))
  }

  model_params$mode <- SigBridgeRUtils::MatchArg(
    model_params$mode,
    c("Cox", "Classification", "Regression")
  )
  model_params$encoder_type <- SigBridgeRUtils::MatchArg(
    model_params$encoder_type,
    c("MLP", "Transformer", "DenseNet")
  )
  model_params$infer_mode <- SigBridgeRUtils::MatchArg(
    model_params$infer_mode,
    c("SC", "ST")
  )
  model_params$reject_mode <- SigBridgeRUtils::MatchArg(
    model_params$reject_mode,
    c("GMM", "Strict")
  )
  device <- SigBridgeRUtils::MatchArg(device, c("cuda", "cpu"))

  gpextractor_params <- get_default_gpextractor_params(gpextractor_params)
  model_params <- get_default_model_params(model_params)

  if (!dir.exists(save_dir)) {
    dir.create(save_dir, recursive = TRUE)
  }

  py_env <- reticulate::py

  py_env$anndata <- anndataR::as_AnnData(
    sc_data,
    x_mapping = "data",
    output_class = "ReticulateAnnData",
    assay_name = assay
  )
  py_env$model_params <- reticulate::r_to_py(model_params)
  py_env$gpextractor_params <- gpextractor_params
  py_env$savePath <- save_dir
  py_env$device <- device

  save_data(
    sc_data = seurat,
    bulk_exp_train = bulk_exp_train,
    bulk_clinical_train = bulk_clinical_train,
    bulk_exp_val = bulk_exp_val,
    bulk_clinical_val = bulk_clinical_val,
    save_dir = save_dir,
    assay = assay
  )

  reticulate::py_run_file(sc_response_file) # see `0_zzz.R`
}

#' @keywords internal
get_hub_params <- function(user_list = NULL) {
  default <- list(
    cateCol1 = "patho_class", # First categorical column (e.g., pathological class)
    cateCol2 = "leiden_clusters", # Second categorical column (e.g., clustering result)
    min_spots = 10L, # Optional: minimum number of spots to consider a hub
    perm_n = 1001L
  )
  utils::modifyList(default, user_list)
}
