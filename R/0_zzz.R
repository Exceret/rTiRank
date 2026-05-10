# ? Package startup messages
.onAttach <- function(libname, pkgname) {
  pkg_version <- utils::packageVersion(pkgname)

  msg <- cli::cli_fmt(cli::cli_alert_success(
    "{.pkg {pkgname}} v{pkg_version} loaded"
  ))
  packageStartupMessage(msg)
  invisible()
}

.onLoad <- function(libname, pkgname) {
  reticulate::py_require(c(
    "leidenalg",
    "igraph",
    "numpy",
    "pandas",
    "pytorch",
    "pickle"
  ))

  assign("model", reticulate::import("tirank.Model"), envir = topenv())

  assign(
    "scst_preprocess",
    reticulate::import("tirank.SCSTpreprocess"),
    envir = topenv()
  )

  invisible()
}

#' Add timestamp to cli functions
#' @keywords internal
ts_cli <- SigBridgeRUtils::CreateTimeStampCliEnv()

pickle <- reticulate::import("pickle")
