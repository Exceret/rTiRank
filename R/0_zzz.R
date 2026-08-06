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
  # `py_require()` can only configure the Python runtime before it has been
  # initialized, so skip it when the user already has a Python session running.
  if (!reticulate::py_available(initialize = FALSE)) {
    reticulate::py_require(
      packages = c(
        "torch",
        "torchvision",
        "timm",
        "numpy",
        "pandas",
        "scanpy",
        "scipy",
        "scikit-learn",
        "imbalanced-learn",
        "matplotlib",
        "seaborn",
        "lifelines",
        "gseapy",
        "optuna",
        "Pillow",
        "igraph",
        "leidenalg"
      ),
      python_version = "3.9"
    )
  }

  # Skip re-importing a module that has already been imported into this
  # session (e.g. when the package is reloaded), so that the existing module
  # object is kept and `sys.path` is not polluted with duplicate entries.
  if (is.null(tirank)) {
    tirank <<- reticulate::import_from_path(
      "tirank",
      path = system.file("python", package = "rTiRank"),
      delay_load = TRUE
    )
  }
  if (is.null(pickle)) {
    pickle <<- reticulate::import("pickle", delay_load = TRUE)
  }
  if (is.null(builtins)) {
    builtins <<- reticulate::import("builtins", delay_load = TRUE)
  }

  invisible()
}

ts_cli <- SigBridgeRUtils::CreateTimeStampCliEnv()

pickle <- NULL
tirank <- NULL
builtins <- NULL
