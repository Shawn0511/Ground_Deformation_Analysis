import seaborn as sns
import matplotlib.pyplot as plt
import pandas as pd
import os

# Define the common folder path
folder_path = 'D:/OneDrive - Imperial College London/2022-09-04 back up folder/Crossrail data/new statistic analysis/surface/surface correlation_heat_map/'

# Change the current working directory to the folder path
os.chdir(folder_path)

# Load the csv files
data_HP_WB = pd.read_csv('HP_WB.csv')
data_SJP_WB = pd.read_csv('SJP_WB.csv')
data_SP_WB = pd.read_csv('SP_WB.csv')
data_HP_EB = pd.read_csv('HP_EB.csv')
data_SJP_EB = pd.read_csv('SJP_EB.csv')
data_SP_EB = pd.read_csv('SP_EB.csv')

# Adjusting the dataset to include the specified range: first 32 columns (up to 20 in offset) and first 20 rows of actual data
data_SP_EB = data_SP_EB.iloc[:20, :32]

# Compute the correlation matrices for all datasets
correlation_matrix_HP_WB = data_HP_WB.corr()
correlation_matrix_SJP_WB = data_SJP_WB.corr()
correlation_matrix_SP_WB = data_SP_WB.corr()
correlation_matrix_HP_EB = data_HP_EB.corr()
correlation_matrix_SJP_EB = data_SJP_EB.corr()
correlation_matrix_SP_EB = data_SP_EB.corr()

# Creating a 2x3 subplot layout for the heatmaps
fig, axs = plt.subplots(nrows=2, ncols=3, figsize=(32, 18), dpi=500)

# Plotting the heatmaps
sns.heatmap(correlation_matrix_HP_WB, annot=True, fmt=".2f", cmap='coolwarm', vmin=-0.2, vmax=1, ax=axs[0, 0], annot_kws={"size": 8})
axs[0, 0].set_title("HP_WB Correlation", fontweight='bold')

sns.heatmap(correlation_matrix_SJP_WB, annot=True, fmt=".2f", cmap='coolwarm', vmin=-0.2, vmax=1, ax=axs[0, 1], annot_kws={"size": 8})
axs[0, 1].set_title("SJP_WB Correlation", fontweight='bold')

sns.heatmap(correlation_matrix_SP_WB, annot=True, fmt=".2f", cmap='coolwarm', vmin=-0.2, vmax=1, ax=axs[0, 2], annot_kws={"size": 8})
axs[0, 2].set_title("SP_WB Correlation", fontweight='bold')

sns.heatmap(correlation_matrix_HP_EB, annot=True, fmt=".2f", cmap='coolwarm', vmin=-0.2, vmax=1, ax=axs[1, 0], annot_kws={"size": 8})
axs[1, 0].set_title("HP_EB Correlation", fontweight='bold')

sns.heatmap(correlation_matrix_SJP_EB, annot=True, fmt=".2f", cmap='coolwarm', vmin=-0.2, vmax=1, ax=axs[1, 1], annot_kws={"size": 8})
axs[1, 1].set_title("SJP_EB Correlation", fontweight='bold')

sns.heatmap(correlation_matrix_SP_EB, annot=True, fmt=".2f", cmap='coolwarm', vmin=-0.2, vmax=1, ax=axs[1, 2], annot_kws={"size": 8})
axs[1, 2].set_title("SP_EB Correlation", fontweight='bold')

plt.tight_layout()
plt.show()

# Save the figure as a TIFF file
plt.savefig('correlation_heatmaps.tiff', format='tiff', dpi=500)