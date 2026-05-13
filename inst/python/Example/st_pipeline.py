# tirank Analysis Pipeline Example
# This script demonstrates how to use the tirank library to integrate spatial transcriptomics (ST)
# and bulk transcriptomics data to identify phenotype-associated spots and determine significant clusters.

# Import necessary libraries and modules
import warnings
import os
from anndata import AnnData
from tirank.Model import initial_model_para
from tirank.LoadData import *
from tirank.SCSTpreprocess import *
from tirank.GPextractor import GenePairExtractor
from tirank.Dataloader import PackData
from tirank.TrainPre import tune_hyperparameters, Predict, Pcluster, IdenHub

warnings.filterwarnings("ignore")


# * get from R session
# Path to the pre-trained image processing model (ensure this file is in the package)
# Note: Ensure you have downloaded ctranspath.pth into data/pretrainModel/
scAnndata: AnnData = globals().get("anndata")
# Number of pathological clusters to identify
savePath: str = globals().get("savePath")
device: str = globals().get("device")
model_params: dict = globals().get("model_params")
# Define the analysis mode (e.g., "Cox" for survival analysis)
mode: str = model_params.get("mode")  # * analysis_mode
infer_mode: str = model_params.get("infer_mode")
# Set the encoder type for the model (e.g., "MLP" for multi-layer perceptron)
encoder_type: str = model_params.get("encoder_type")
gpextractor_params: dict = globals().get("gpextractor_params")

n_trials: int = globals().get("n_trials")

hub_params: dict = globals().get("hub_params")
perm_n: int = hub_params.get("perm_n")

## 2.5 Gene pair transformation
# Initialize the GenePairExtractor with parameters
GPextractor = GenePairExtractor(
    savePath=savePath,
    analysis_mode=mode,
    # Optional: number of top variable genes to select
    top_var_genes=gpextractor_params.get("top_var_genes"),
    # Optional: number of top gene pairs to select
    top_gene_pairs=gpextractor_params.get("top_gene_pairs"),
    # Optional: p-value threshold for gene pair selection
    p_value_threshold=gpextractor_params.get("p_value_threshold"),
    # Optional: upper cutoff for correlation coefficient
    max_cutoff=gpextractor_params.get("max_cutoff"),
    # Optional: lower cutoff for correlation coefficient
    min_cutoff=gpextractor_params.get("min_cutoff"),
)

# Load data for gene pair extraction
GPextractor.load_data()

# Run the gene pair extraction process
GPextractor.run_extraction()

# Save the extracted gene pairs
GPextractor.save_data()

# --------------------------------------------
# 3. Analysis
# --------------------------------------------

## 3.1 tirank Analysis
# Define paths for saving analysis results
savePath_3 = os.path.join(savePath, "3_Analysis")
if not os.path.exists(savePath_3):
    os.makedirs(savePath_3, exist_ok=True)

# Pack the data into DataLoader objects for training and validation
PackData(
    savePath=savePath,
    mode=mode,
    infer_mode=infer_mode,
    batch_size=model_params.get(
        "batch_size"
    ),  # Optional parameter: batch size for DataLoader
)

### 3.1.2 Model Training

# Initialize model parameters
initial_model_para(
    savePath=savePath,
    # Optional: number of heads in multi-head attention (if using Transformer)
    nhead=model_params.get("nhead"),
    # Optional: hidden layer size 1
    nhid1=model_params.get("nhid1"),
    # Optional: hidden layer size 2
    nhid2=model_params.get("nhid2"),
    # Optional: output size
    n_output=model_params.get("n_output"),
    # Optional: number of layers
    nlayers=model_params.get("nlayers"),
    # Optional: number of predictions (e.g., 1 for regression)
    n_pred=model_params.get("n_pred"),
    # Optional: dropout rate
    dropout=model_params.get("dropout"),
    mode=mode,
    encoder_type=encoder_type,
    infer_mode=infer_mode,
)

# Tune hyperparameters using Optuna or other optimization libraries
tune_hyperparameters(
    savePath=savePath,
    device=device,
    n_trials=n_trials,  # Optional parameter: number of hyperparameter tuning trials
)

### 3.1.3 Model Inference
# Predict phenotype-associated spots and perform rejection (uncertainty estimation)
Predict(
    savePath=savePath,
    mode=mode,
    # Optional: whether to perform rejection
    do_reject=model_params.get("do_reject"),
    # Optional: tolerance level for rejection
    tolerance=model_params.get("tolerance"),
    # Optional: rejection mode (e.g., "GMM" for Gaussian Mixture Model)
    reject_mode=model_params.get("reject_mode"),
)

### 3.1.4 Identify Hubs and Significant Clusters
# Identify hub spots based on categorical columns
IdenHub(
    savePath=savePath,
    cateCol1=hub_params.get("cateCol1"),  # First categorical column (e.g., pathological class)
    cateCol2=hub_params.get("cateCol2"),  # Second categorical column (e.g., clustering result)
    min_spots=hub_params.get("min_spots"),  # Optional: minimum number of spots to consider a hub
)

# Perform permutation tests to identify significant clusters
Pcluster(savePath=savePath, clusterColName="patho_class", perm_n=perm_n)
Pcluster(savePath=savePath, clusterColName="leiden_clusters", perm_n=perm_n)
Pcluster(savePath=savePath, clusterColName="combine_cluster", perm_n=perm_n)
