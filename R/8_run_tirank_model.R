#' Run a TiRank model
#'
#' @param seurat A Seurat object containing single-cell RNA-seq data
#' @param bulk_exp_train Training bulk expression data (data.frame)
#' @param bulk_clinical_train Training bulk clinical data (data.frame)
#' @param bulk_exp_val Validation bulk expression data (data.frame)
#' @param bulk_clinical_val Validation bulk clinical data (data.frame)
#' @param save_dir Directory path to save model and intermediate results
#' @param device Device to use for model training, either "cuda" or "cpu"
#' @param load_cache Whether to use existing data in `save_dir` instead of overwriting it.
#' @param gpextractor_params List of parameters for gene pair extraction
#' \describe{
#'   \item{top_var_genes}{Number of top variable genes to select}
#'   \item{top_gene_pairs}{Number of top gene pairs to extract}
#'   \item{p_value_threshold}{P-value threshold for gene pair selection}
#'   \item{max_cutoff}{Maximum correlation cutoff}
#'   \item{min_cutoff}{Minimum correlation cutoff}
#' }
#' @param model_params List of parameters for model architecture and training
#' \describe{
#'   \item{batch_size}{Batch size for training}
#'   \item{nhead}{Number of attention heads (for Transformer encoder)}
#'   \item{nhid1}{Hidden layer size 1}
#'   \item{nhid2}{Hidden layer size 2}
#'   \item{n_output}{Output dimension}
#'   \item{nlayers}{Number of encoder layers}
#'   \item{n_pred}{Number of prediction heads}
#'   \item{dropout}{Dropout rate}
#'   \item{mode}{Prediction mode: "Cox", "Classification", or "Regression"}
#'   \item{encoder_type}{Encoder type: "MLP", "Transformer", or "DenseNet"}
#'   \item{infer_mode}{Inference mode: "SC" (single-cell) or "ST" (spatial transcriptomics)}
#'   \item{n_trials}{Number of trials for optimization}
#'   \item{do_reject}{Whether to perform rejection sampling}
#'   \item{tolerance}{Tolerance threshold for rejection}
#'   \item{reject_mode}{Rejection mode: "GMM" or "Strict"}
#' }
#' @param sc_response_file Path to the single-cell response pipeline script
#' @param ... Additional arguments, including:
#' \describe{
#'   \item{seed}{Random seed for reproducibility (default: 123)}
#'   \item{assay}{Assay name to use from Seurat object (default: "RNA")}
#' }
#'
#' @return Invisibly returns NULL. The model and results are saved to `save_dir`.
#'
#' @details
#' This function is the last step in TiRank analysis pipline, all data in R session
#' will be stored in `save_dir` according to TiRank's original implementation.
#'
#'
#' @export
run_tirank_model <- function(
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
  sc_response_file = system.file(
    "python/Example/sc_pipeline.py",
    package = "rTiRank"
  ),
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
  # named list -> dict
  py_env <- reticulate::py
  py_env$model_params <- reticulate::r_to_py(model_params)
  py_env$gpextractor_params <- reticulate::r_to_py(gpextractor_params)
  py_env$savePath <- save_dir
  py_env$device <- device

  if (!load_cache) {
    save_data(
      sc_data = seurat,
      bulk_exp_train = bulk_exp_train,
      bulk_clinical_train = bulk_clinical_train,
      bulk_exp_val = bulk_exp_val,
      bulk_clinical_val = bulk_clinical_val,
      save_dir = save_dir,
      assay = assay
    )
  }

  reticulate::py_run_file(sc_response_file) # see `0_zzz.R`
}


#' Get default GPextractor parameters
#'
#' @param user_list A named list of user-provided parameters to override defaults
#'
#' @return A list of parameters for GPextractor with user overrides applied
#'
#' @export
get_default_gpextractor_params <- function(user_list = NULL) {
  default <- list(
    top_var_genes = 2000L,
    top_gene_pairs = 1000L,
    p_value_threshold = 0.05,
    max_cutoff = 0.8,
    min_cutoff = -0.8
  )
  utils::modifyList(default, user_list)
}

#' Get Default Model Parameters
#'
#' @param user_list A list of user-specified parameters to override defaults. If NULL, only default parameters are returned.
#'
#' @return A list containing the complete model parameters with user overrides applied.
#'
#' @export
#'
#' @description
#' Returns the default hyperparameters for the TiRank model. The defaults include:
#' \describe{
#'   \item{nhead}{Number of attention heads (default: 2)}
#'   \item{nhid1}{First hidden layer dimension (default: 96)}
#'   \item{nhid2}{Second hidden layer dimension (default: 8)}
#'   \item{n_output}{Output dimension (default: 32)}
#'   \item{nlayers}{Number of layers (default: 3)}
#'   \item{n_pred}{Number of prediction heads (default: 2)}
#'   \item{dropout}{Dropout rate (default: 0.5)}
#'   \item{mode}{Model mode: "Cox", "Classification", or "Regression"}
#'   \item{encoder_type}{Encoder architecture: "MLP", "Transformer", or "DenseNet"}
#'   \item{infer_mode}{Inference mode: "SC" (single-cell) or "ST" (spatial transcriptomics)}
#'   \item{n_trials}{Number of trials for hyperparameter optimization (default: 5)}
#'   \item{do_reject}{Whether to perform rejection sampling (default: TRUE)}
#'   \item{tolerance}{Tolerance threshold for rejection sampling (default: 0.05)}
#' }
#'
get_default_model_params <- function(user_list = NULL) {
  default <- list(
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
    tolerance = 0.05
  )
  utils::modifyList(default, user_list)
}

#' Save training and validation data to pickle files
#'
#' @param sc_data Single-cell data object (e.g., SingleCellExperiment)
#' @param bulk_exp_train Data frame of bulk RNA-seq expression for training
#' @param bulk_clinical_train Data frame of clinical data for training
#' @param bulk_exp_val Data frame of bulk RNA-seq expression for validation
#' @param bulk_clinical_val Data frame of clinical data for validation
#' @param save_dir Directory path to save the output files
#' @param assay Name of the assay to use from single-cell data (default: "RNA")
#' @param ... Additional arguments (currently unused)
#'
#' @return Invisible NULL. Files are saved to disk:
#'   \itemize{
#'     \item split_data/bulkExp_train.pkl
#'     \item split_data/bulkClinical_train.pkl
#'     \item split_data/bulkExp_val.pkl
#'     \item split_data/bulkClinical_val.pkl
#'     \item 2_preprocessing/scAnndata.pkl
#'   }
#'
#' @keywords internal
save_data <- function(
  sc_data,
  bulk_exp_train,
  bulk_clinical_train,
  bulk_exp_val,
  bulk_clinical_val,
  save_dir,
  assay = "RNA",
  ...
) {
  stopifnot(
    is.data.frame(bulk_exp_train),
    is.data.frame(bulk_clinical_train),
    is.data.frame(bulk_exp_val),
    is.data.frame(bulk_clinical_val)
  )

  dir.create(
    file.path(save_dir, "2_preprocessing/split_data"),
    recursive = TRUE,
    showWarnings = FALSE
  )
  py_env <- reticulate::py
  pickle_dump(
    x = bulk_exp_train,
    file.path(save_dir, "2_preprocessing/split_data/bulkExp_train.pkl")
  )
  pickle_dump(
    x = bulk_clinical_train,
    file.path(save_dir, "2_preprocessing/split_data/bulkClinical_train.pkl")
  )
  pickle_dump(
    x = bulk_exp_val,
    file.path(save_dir, "2_preprocessing/split_data/bulkExp_val.pkl")
  )
  pickle_dump(
    x = bulk_clinical_val,
    file.path(save_dir, "2_preprocessing/split_data/bulkClinical_val.pkl")
  )

  py_env$anndata <- anndataR::as_AnnData(
    sc_data,
    x_mapping = "data",
    output_class = "ReticulateAnnData",
    assay_name = assay
  )

  reticulate::py_run_string(sprintf(
    "with open('%s', 'wb') as f:\n\tpickle.dump(anndata, f)",
    file.path(save_dir, "2_preprocessing/scAnndata.pkl")
  ))
  invisible()
}
