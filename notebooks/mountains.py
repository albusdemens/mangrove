import numpy as np
import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

# --- Define the Grid and the Underlying "Mountain" Shape (2D Gaussian) ---
grid_size = 25
x = np.linspace(-3, 3, grid_size)
y = np.linspace(-3, 3, grid_size)
X, Y = np.meshgrid(x, y)

def gaussian_2d(x, y, center_x, center_y, sigma_x, sigma_y):
    return np.exp(-((x - center_x)**2 / (2 * sigma_x**2) + (y - center_y)**2 / (2 * sigma_y**2)))

mountain_base = gaussian_2d(X, Y, 0, 0, 1.5, 1.5)  # Adjust sigma for broader/narrower shape

# --- Generate Noise ---
noise_level = 0.35  # Adjust for the intensity of the noise
noise = np.random.randn(grid_size, grid_size) * noise_level

# --- Combine the Mountain Shape and the Noise ---
Z = mountain_base + noise

# Ensure heights are non-negative (important for visualization)
Z[Z < 0] = 0

# --- Create the 3D Bar Plot ---
fig = plt.figure(figsize=(10, 8))
ax = fig.add_subplot(111, projection='3d')

xpos, ypos = np.meshgrid(np.arange(grid_size), np.arange(grid_size))
xpos = xpos.flatten() - 0.5
ypos = ypos.flatten() - 0.5
zpos = np.zeros_like(xpos)

dx = dy = 1
dz = Z.flatten()

ax.bar3d(xpos, ypos, zpos, dx, dy, dz, shade=True, alpha=0.8) # Added alpha for better visual clarity

# --- Customize the Plot ---
ax.set_xlabel('X')
ax.set_ylabel('Y')
ax.set_zlabel('Z')
ax.set_title('Noisy 3D Bar Plot with Mountain Shape')

plt.show()