"""Internal Processing of get_patho_class.R


"""

import os
import pickle
from anndata import AnnData
from tirank.Imageprocessing import crop_images, infer_by_pretrain,process_embeddings,plot_patho_class_heatmap

adata : AnnData = globals().get("anndata")
pretrain_path: str = globals().get("pretrain_path")
n_components: int = globals().get("n_components")
n_clusters: int = globals().get("n_clusters")
plot_classes: bool = globals().get("plot_classes")
image_save_path: str = globals().get("image_save_path")
savePath :str = globals().get("savePath")

images = crop_images(adata)
features = infer_by_pretrain(images, pretrain_path)

# Example values for PCA and clustering
pca_embeddings, cluster_labels = process_embeddings(
    features, n_components, n_clusters
)
adata.obs["patho_class"] = cluster_labels
adata.obsm["patho_emd"] = pca_embeddings

if plot_classes:
    if image_save_path is None:
        raise ValueError(
            "'image_save_path' must be provided if 'plot_classes' is True."
        )
    plot_patho_class_heatmap(adata, image_save_path)

savePath_2: str = os.path.join(savePath, "2_preprocessing")
if not os.path.exists(savePath_2):
    os.makedirs(savePath_2, exist_ok=True)


with open(os.path.join(savePath_2, "scAnndata.pkl"), "wb") as f:
    pickle.dump(adata, f)
