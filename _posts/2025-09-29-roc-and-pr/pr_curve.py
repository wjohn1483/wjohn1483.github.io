import numpy as np
import matplotlib.pyplot as plt
from sklearn.metrics import precision_recall_curve, average_precision_score

# 隨機產生資料
np.random.seed(42)
y_true = np.random.randint(0, 2, 100)   # 100 個真實標籤 (0 or 1)
y_score = np.random.rand(100)           # 100 個隨機預測機率 (0 ~ 1)

# 計算 Precision-Recall curve
precision, recall, thresholds = precision_recall_curve(y_true, y_score)
ap = average_precision_score(y_true, y_score)

# 繪製 PR curve
plt.figure(figsize=(6,6))
plt.plot(recall, precision, color="green", lw=2, label=f"PR curve (AP = {ap:.2f})")
plt.xlim([0.0, 1.05])
plt.ylim([0.0, 1.05])
plt.xlabel("Recall")
plt.ylabel("Precision")
plt.title("Precision-Recall Curve with Random Predictions")
plt.legend(loc="lower left")
plt.grid(True)

# 儲存圖片
plt.savefig("pr_curve.png")
