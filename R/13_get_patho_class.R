#' Classify Pathological Subtypes Using a Pretrained CTransPath Model
#'
#' Crops tiles, generates embeddings using CTransPath, performs PCA and K-means,
#' and adds the results to the AnnData object.
#'
#' @param seurat A Seurat object containing spatial transcriptomics data.
#' @param pretrain_path Path to the pretrained CTransPath model weights file (.pth).
#' @param save_dir Path to save results.
#' @param n_components Integer. Number of principal components for dimensionality reduction. Default is 50.
#' @param n_clusters Integer. Number of pathological clusters to identify. Default is 6.
#' @param plot_classes Logical. Whether to generate a plot of the classified subtypes. Default is TRUE.
#' @param image_save_path Path to save the classification plot. If NULL, the plot is not saved to disk. Default is NULL.
#' @param ... Additional arguments:
#'   \describe{
#'     \item{seed}{Integer. Random seed for reproducibility. Default is 123.}
#'     \item{assay}{Character. Name of the assay in the Seurat object to use. Default is "RNA".}
#' }
#'
#' @return Invisible TRUE upon successful completion.
#'
#' @export
#'
get_patho_class <- function(
  seurat,
  pretrain_path,
  save_dir,
  n_components = 50L,
  n_clusters = 6L,
  plot_classes = TRUE,
  image_save_path = NULL,
  ...
) {
  if (!file.exists(pretrain_path)) {
    cli::cli_abort(c(
      "x" = "{.file ctranspath.pth} not found",
      ">" = "Use {.fun download_ctranspath} to download pretrained model"
    ))
  }
  dots <- rlang::list2(...)
  seed <- dots$seed %||% 123L
  set.seed(seed)

  assay <- dots$assay %||% "RNA"
  py_env <- reticulate::py

  py_env$anndata <- anndataR::as_AnnData(
    seurat,
    x_mapping = "data",
    output_class = "ReticulateAnnData",
    assay_name = assay
  )
  py_env$pretrain_path <- pretrain_path
  py_env$n_components <- n_components
  py_env$n_clusters <- n_clusters
  py_env$plot_classes <- plot_classes
  py_env$image_save_path <- image_save_path
  py_env$savePath <- save_dir

  py_run_file(system.file(
    "python/Example/get_patho_class.py",
    package = "rTiRank"
  ))

  invisible(TRUE)
}
