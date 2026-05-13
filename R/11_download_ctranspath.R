#' Download ctranspath pretrained model weights
#'
#' Downloads the ctranspath model checkpoint file (\code{ctranspath.pth}) from Zenodo.
#' The downloaded weights are used by the pathology image feature extraction module.
#'
#' @param ... Additional arguments passed to \code{\link[base]{system2}}.
#'
#' @return Invisible \code{NULL}, called for the side effect of downloading the file.
download_ctranspath <- function(...) {
  # 下载ctranspath数据
  system2(
    "wget",
    "https://zenodo.org/records/18275554/files/ctranspath.pth",
    ...
  )
}
