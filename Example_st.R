# test_that("it works", {
usethis::proj_activate(".")
setwd("tests/testthat")
library(magrittr)

reticulate::use_condaenv("r-reticulate-tirank")
devtools::document("../..")

data_path <- "/data/resource/wanglab/SigBridgeR/benchmark_data/lung"

seurat <- qs::qread(
  file.path(data_path, "luad_GSE123902_seurat2.qs"),
  nthreads = 8L
)

bulk <- qs::qread(
  file.path(data_path, "TCGA_LUAD_bulkdata.qs"),
  nthreads = 2L
)

pheno <- qs::qread(
  file.path(
    data_path,
    "TCGA_LUAD_pheno.qs"
  )
)
sample_names <- pheno$sample %>% gsub(".*-", "", .)
sample_names_tumor_only <- sample_names[sample_names %in% c("01", "11")]
pheno_bi <- SigBridgeR::PhenoMap(sample_names, v == "01" ~ 1, v == "11" ~ 0)
names(pheno_bi) <- pheno$sample

bulk %>% head()

# -------------------------------------------------------------------------------------------------------
bulkExp <- normalize_data(bulk)
pheno_bi <- pheno_bi[!is.na(pheno_bi)]
bulkClinical <- as.data.frame(pheno_bi)
check_res <- check_bulk(bulkExp, bulkClinical, save_path = "./TiRank_res")
st_exp_df <- transfer_exp_profile(seurat)

get_patho_class(
  seurat = seurat,
  pretrain_path = "./ctranspath.pth",
  n_clusters = 7L,
  image_save_path = os.path.join(savePath_2, "patho_label.png")
  # Advanced parameters: n_components (PCA components), n_clusters
)

val_res <- generate_val(
  check_res$bulk_exp,
  check_res$bulk_clinical,
  validation_proportion = 0.15,
  mode = c("Classification"),
  seed = 123L,
)

sampling_res <- perform_sampling_on_RNAseq(
  val_res$bulk_exp_train,
  val_res$bulk_clinical_train,
  mode = c("SMOTE"),
  threshold = 0.5
)

cell_cell_distance <- compute_similarity(
  seurat = seurat,
  calculate_distance = FALSE,
  parallel = FALSE,
  save_path = "TiRank_res"
)

final_res <- run_st_tirank_model(
  seurat = seurat,
  bulk_exp_train = as.data.frame(sampling_res$bulk_exp_resampled),
  bulk_clinical_train = sampling_res$bulk_clinical_resampled,
  bulk_exp_val = val_res$bulk_exp_val,
  bulk_clinical_val = val_res$bulk_clinical_val,
  save_dir = "./TiRank_res",
  device = c(
    "cuda"
    # , "cpu"
  ),
  gpextractor_params = list(
    top_var_genes = 2000L,
    top_gene_pairs = 1000L,
    p_value_threshold = 0.05,
    max_cutoff = 0.8,
    min_cutoff = -0.8
  ),
  model_params = list(
    batch_size = 1024L,
    nhead = 2L,
    nhid1 = 96L,
    nhid2 = 8L,
    n_output = 32L,
    nlayers = 3L,
    n_pred = 2L,
    dropout = 0.5,
    mode = c(
      # "Cox",
      "Classification"
      # , "Regression"
    ),
    encoder_type = c(
      "MLP"
      # ,        "Transformer", "DenseNet"
    ),
    infer_mode = c(
      "SC"
      # , "ST"
    ),
    n_trials = 5L,
    do_reject = TRUE,
    tolerance = 0.05,
    reject_mode = c(
      "GMM"
      # ,         "Strict"
    )
  ),
  sc_response_file = system.file(
    "python/Example/st_pipeline.py",
    package = "rTiRank"
  )
)
# })
