import json
import numpy as np
import math

# --- 1. Load training data ---
inputs = []
outputs = []

with open("train.save", "r") as f:
    for line in f:
        data = json.loads(line)
        
        distance = float(data["distance"])
        dot = float(data["dot_product"])
        cross = float(data["cross_product"])
        
        fx = float(data["fx"])
        fy = float(data["fy"])
        
        # input vector (now richer)
        inputs.append([distance, dot, cross, fx, fy])
        
        dx = float(data["dx"])
        dy = float(data["dy"])
        outputs.append([dx, dy])

X = np.array(inputs)   # (n, 5)
Y = np.array(outputs)  # (n, 2)

print(f"Loaded {X.shape[0]} samples.")

# --- 2. Normalize inputs (VERY IMPORTANT) ---
X_mean = X.mean(axis=0)
X_std = X.std(axis=0) + 1e-8  # avoid divide by zero
X_norm = (X - X_mean) / X_std

# --- 3. Train least squares ---
A, residuals, rank, s = np.linalg.lstsq(X_norm, Y, rcond=None)

print("Learned parameter matrix A:")
print(A)

# --- 4. Predict function ---
def predict_bot_move(distance, dot, cross, fx, fy, snap_8_directions=False):
    input_vec = np.array([[distance, dot, cross, fx, fy]])
    
    # normalize using SAME stats
    input_vec = (input_vec - X_mean) / X_std
    
    dx, dy = (input_vec @ A)[0]
    
    if snap_8_directions:
        angle = math.atan2(dy, dx)
        direction_index = round(angle / (math.pi / 4)) % 8
        dirs = [
            (0, 1),     # N
            (math.sqrt(2)/2, math.sqrt(2)/2),  # NE
            (1, 0),     # E
            (math.sqrt(2)/2, -math.sqrt(2)/2), # SE
            (0, -1),    # S
            (-math.sqrt(2)/2, -math.sqrt(2)/2),# SW
            (-1, 0),    # W
            (-math.sqrt(2)/2, math.sqrt(2)/2)  # NW
        ]
        return dirs[direction_index]
    else:
        return dx, dy

# --- 5. Example prediction ---
example_distance = 0.5
example_dot = -0.9
example_cross = -20
example_fx = 0.36
example_fy = 0.45

predicted_move = predict_bot_move(
    example_distance,
    example_dot,
    example_cross,
    example_fx,
    example_fy,
    snap_8_directions=True
)

print("Predicted bot move (8-direction):", predicted_move)

# --- 6. Save model ---
with open("bot_model.json", "w") as f:
    json.dump({
        "A": A.tolist(),
        "mean": X_mean.tolist(),
        "std": X_std.tolist()
    }, f)