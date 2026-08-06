#' Compute cell-cell similarity and optionally spatial distance matrices
#'
#' Extracts and saves the cell/spot similarity matrix.
#' Optionally, it can also calculate a spatial distance-based adjacency matrix
#' (6 nearest neighbors) for spatial transcriptomics data.
#'
#' @param seurat A Seurat object containing single-cell data with RNA nearest neighbor graph
#' @param calculate_distance Logical. If TRUE, compute spatial distances from tissue coordinates
#' @param parallel Logical. If TRUE, use parallel computation (requires Rfast package)
#' @param save_path Character. Path to directory for saving computed matrices as pickle files
#' @param ... Additional arguments (currently unused, will raise error if provided)
#'
#' @return A list containing:
#'   \item{similarity}{A data frame of cell-cell similarity from RNA nearest neighbor graph}
#'   \item{distance}{A data frame adjacency matrix of spatial neighbors (NULL if calculate_distance is FALSE)}
#'
#' @details
#' The function extracts the RNA nearest neighbor graph from the Seurat object.
#' When \code{calculate_distance = TRUE}, it computes Euclidean distances between cells
#' based on tissue coordinates and identifies the 6 nearest spatial neighbors.
#' Results can be optionally saved as pickle files.
#'
#' @export
compute_similarity <- function(
  seurat,
  calculate_distance = FALSE,
  parallel = FALSE,
  save_path = NULL,
  ...
) {
  rlang::check_dots_empty0()
  # Matrix
  cell_cell_similarity <- SeuratObject::Graphs(seurat, slot = "RNA_nn")
  cell_cell_similarity <- as.data.frame(cell_cell_similarity)

  if (calculate_distance) {
    spatial_positions <- as.matrix(SeuratObject::GetTissueCoordinates(seurat))

    coord_cols <- grep(
      "x|y|row|col",
      colnames(spatial_positions),
      value = TRUE,
      ignore.case = TRUE
    )[1:2]
    spatial_positions <- spatial_positions[, coord_cols]

    euclidean_distances <- if (rlang::is_installed("Rfast")) {
      Rfast::Dist(x = spatial_positions, parallel = parallel)
    } else {
      stats::dist(x = spatial_positions)
    }

    n <- nrow(euclidean_distances)
    cell_names <- colnames(seurat)

    adjacency_matrix <- matrix(
      0L,
      nrow = n,
      ncol = n,
      dimnames = list(cell_names, cell_names)
    )

    # a list
    nn_order <- if (rlang::is_installed("Rfast")) {
      Rfast::rowOrder(euclidean_distances)
    } else {
      t(apply(euclidean_distances, 1, order))
    }
    closest_idx <- nn_order[2:7, ]
    adjacency_matrix[cbind(
      rep(seq_len(n), each = 6),
      as.vector(closest_idx)
    )] <- 1L

    adjacency_matrix <- as.data.frame(adjacency_matrix)

    if (!is.null(save_path)) {
      pickle_dump(
        reticulate::r_to_py(adjacency_matrix),
        save_path = file.path(save_path, "distance_df.pkl")
      )
    }
  } else {
    adjacency_matrix <- NULL
  }

  if (!is.null(save_path)) {
    pickle_dump(
      reticulate::r_to_py(cell_cell_similarity),
      save_path = file.path(save_path, "2_preprocessing", "similarity_df.pkl")
    )
  }

  list(similarity = cell_cell_similarity, distance = adjacency_matrix)
}
