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

  assign(
    "model",
    reticulate::py_run_file(
      system.file("python/tirank/Model.py", package = "rTiRank")
    ),
    envir = topenv()
  )
  assign(
    "scst_preprocess",
    reticulate::py_run_file(
      system.file("python/tirank/SCSTpreprocess.py", package = "rTiRank")
    ),
    envir = topenv()
  )
  assign(
    "scst_preprocess",
    reticulate::py_run_file(
      system.file("python/tirank/Imageprocessing.py", package = "rTiRank")
    ),
    envir = topenv()
  )

  invisible()
}

ts_cli <- SigBridgeRUtils::CreateTimeStampCliEnv()

pickle <- reticulate::import("pickle")
