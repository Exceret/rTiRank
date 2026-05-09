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

  invisible()
}

#' Add timestamp to cli functions
#' @keywords internal
ts_cli <- SigBridgeRUtils::CreateTimeStampCliEnv()

model <- reticulate::import("tirank.Model")

pickle <- reticulate::import("pickle")

scst_preprocess <- reticulate::import("tirank.SCSTpreprocess")
