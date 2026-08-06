#' Sets the random seed for reproducibility across all relevant libraries.
#'
#' @description Sets the random seed for Python (PyTorch) to ensure
#' reproducible results across different runs.
#'
#' @param seed An integer value to use as the random seed. Default is 123L.
#' @param ... Additional arguments (currently unused, reserved for future extension).
#'
#' @return Invisible NULL. The function is called for its side effect of setting the seed.
#'
#' @export
#'
#' @examples
#' \dontrun{
#' setup_seed(42L)
#' }
setup_seed <- function(seed = 123L, ...) {
  rlang::check_dots_empty0()
  if (!is.integer(seed)) {
    cli::cli_abort(c(
      "x" = "{.arg seed} is expected to be an {.cls integer}, \
    but got a {.cls {class(seed)}}"
    ))
  }
  tirank$setup_seed(seed)
}
