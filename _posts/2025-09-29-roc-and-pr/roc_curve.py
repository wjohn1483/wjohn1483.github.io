import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import roc_curve, auc

# 隨機產生資料
np.random.seed(42)  # 固定隨機種子，方便重現結果
y_true = np.random.randint(0, 2, 100)   # 100 個真實標籤 (0 or 1)
y_score = np.random.rand(100)            # 100 個隨機預測機率 (0 ~ 1)

# 計算 ROC curve
fpr, tpr, thresholds = roc_curve(y_true, y_score)
roc_auc = auc(fpr, tpr)

# 繪製 ROC curve
plt.figure(figsize=(6,6))
plt.plot(fpr, tpr, color="blue", lw=2, label=f"ROC curve (AUC = {roc_auc:.2f})")
plt.plot([0, 1], [0, 1], color="gray", lw=2, linestyle="--")  # 參考線
plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.05])
plt.xlabel("False Positive Rate")
plt.ylabel("True Positive Rate")
plt.title("ROC Curve with Random Predictions")
plt.legend(loc="lower right")
plt.grid(True)
plt.savefig("roc_curve.png")
