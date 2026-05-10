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
  env_name <- "r-reticulate-tirank"

  # ---- 1. 确保 Conda 环境存在 ----
  if (!env_name %in% reticulate::conda_list()$name) {
    cli::cli_alert_info("Creating conda environment: ", env_name)
    reticulate::conda_create(envname = env_name, python_version = "3.9")
  }

  # ---- 2. 激活该环境 ----
  reticulate::use_condaenv(condaenv = env_name, required = TRUE)

  # ---- 3. 检查并安装 tirank（以及所有其他依赖） ----
  # 只需检查 tirank 是否存在；如果不存在，则一次性安装全部依赖
  tirank_available <- tryCatch(
    {
      reticulate::import("tirank") # 仅测试导入
      TRUE
    },
    error = function(e) FALSE
  )

  if (!tirank_available) {
    cli::cli_alert_warning("TiRank not found, installing from bioconda...")

    reticulate::conda_install(
      envname = env_name,
      packages = c(
        "tirank",
        "leidenalg",
        "igraph",
        "numpy",
        "pandas",
        "pytorch"
      ),
      channel = c("conda-forge", "bioconda", "pytorch") # pytorch 有自己的频道
    )

    cli::cli_alert_success("All Python dependencies installed.")
  }

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
