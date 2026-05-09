#' Get expression profile from Seurat object
#'
#' @param sc_seurat A Seurat object containing single-cell expression data
#' @param assay Name of the assay to extract expression data from, defaults to "RNA"
#' @param ... Additional arguments (currently unused, reserved for future extension)
#'
#' @return A data frame containing the expression matrix with genes as rows and cells as columns
#'
#'
#' @export
transfer_exp_profile <- function(sc_seurat, assay = "RNA", ...) {
  rlang::check_dots_empty0()
  if (!inherits(sc_seurat, "Seurat")) {
    "x" = "{.arg sc_seurat} is expected to be an {.cls Seurat}, \
    but got a {.cls {class(sc_seurat)}}"
  }

  counts <- SeuratObject::LayerData(
    object = sc_seurat,
    layer = "counts",
    assay = assay
  )
  as.data.frame(as.matrix(counts))
}
