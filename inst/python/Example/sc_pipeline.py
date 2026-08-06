"""Example for integrate single-cell RNA-seq data of melanoma and response information"""

import os
import warnings
from tirank.Model import initial_model_para
from tirank.GPextractor import GenePairExtractor
from tirank.Dataloader import PackData
from tirank.TrainPre import tune_hyperparameters, Predict

warnings.filterwarnings("ignore")


# * from R session
savePath: str = globals().get("savePath")
device: str = globals().get("device")

gpextractor_params: dict = globals().get("gpextractor_params")
model_params: dict = globals().get("model_params")

mode: str = model_params.get("mode")  # * analysis_mode
infer_mode: str = model_params.get("infer_mode")
encoder_type: str = model_params.get("encoder_type")

# 2.5 Genepair Transformation
GPextractor = GenePairExtractor(
    savePath=savePath,
    analysis_mode=mode,
    top_var_genes=gpextractor_params.get("top_var_genes"),
    top_gene_pairs=gpextractor_params.get("top_gene_pairs"),
    p_value_threshold=gpextractor_params.get("p_value_threshold"),
    max_cutoff=gpextractor_params.get("max_cutoff"),
    min_cutoff=gpextractor_params.get("min_cutoff"),
)  ## optinal parameter: top_var_genes, top_gene_pairs, padj_value_threshold, padj_value_threshold

GPextractor.load_data()
GPextractor.run_extraction()
GPextractor.save_data()

## 3. Analysis
# 3.1 tirank
savePath_1 = os.path.join(savePath, "1_loaddata")
savePath_2 = os.path.join(savePath, "2_preprocessing")
savePath_3 = os.path.join(savePath, "3_Analysis")

if not os.path.exists(savePath_3):
    os.makedirs(savePath_3, exist_ok=True)


# 3.1.1 Dataloader

PackData(
    savePath,
    mode=mode,
    infer_mode=infer_mode,
    batch_size=model_params.get("batch_size"),
)

# 3.1.2 Training

# Model parameter
initial_model_para(
    savePath=savePath,
    nhead=model_params.get("nhead"),
    nhid1=model_params.get("nhid1"),
    nhid2=model_params.get("nhid2"),
    n_output=model_params.get("n_output"),
    nlayers=model_params.get("nlayers"),
    n_pred=model_params.get("n_pred"),
    dropout=model_params.get("dropout"),
    mode=mode,
    encoder_type=encoder_type,
    infer_mode=infer_mode,
)

tune_hyperparameters(
    ## Parameters Path
    savePath=savePath,
    device=device,
    n_trials=5,
)  ## optional parameters: n_trials

# 3.1.3 Inference
Predict(
    savePath=savePath,
    mode=mode,
    do_reject=model_params.get("do_reject"),
    tolerance=model_params.get("tolerance"),
    reject_mode=model_params.get("reject_mode"),
)
