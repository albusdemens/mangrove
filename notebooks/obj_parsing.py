#!/usr/bin/env python3
"""
Godot-Friendly Histogram Generator

Creates a histogram OBJ file with connected columns (no gaps).
"""

def fix_histogram_for_godot(input_file="Histogram_Columns_quadrant_neg_X_neg_Y.obj", output_file="Mountain_godot_4.obj"):
    # Read the file
    vertices = []
    faces = []
    
    with open(input_file, 'r') as f:
        for line in f:
            if line.startswith('v '):
                parts = line.split()
                x, y, z = float(parts[1]), float(parts[2]), float(parts[3])
                vertices.append([x, y, z])
            elif line.startswith('f '):
                parts = line.split()
                face = [int(p.split('/')[0]) for p in parts[1:]]
                faces.append(face)
    
    # Group vertices by their X,Z positions
    columns = {}
    grid_size = 0.033  # Column spacing
    
    for i, v in enumerate(vertices):
        x_grid = round(v[0] / grid_size) * grid_size
        z_grid = round(v[2] / grid_size) * grid_size
        key = (x_grid, z_grid)
        
        if key not in columns:
            columns[key] = {'vertices': [], 'heights': []}
        
        columns[key]['vertices'].append(i)
        columns[key]['heights'].append(v[1])
    
    # Create new OBJ with combined geometry
    # Group columns to stay within surface limits (max ~100 surfaces)
    
    with open(output_file, 'w') as f:
        f.write("# Histogram for Godot (combined geometry)\n\n")
        
        # Write all vertices
        vertex_count = 0
        for pos, data in columns.items():
            if not data['heights']:
                continue
                
            x, z = pos
            max_height = max(data['heights'])
            
            if max_height <= 0:
                continue
            
            # Column dimensions - make columns touch
            w = grid_size  # Width = grid size (no gap)
            d = grid_size  # Depth = grid size (no gap)
            
            # Define 8 vertices for a box
            verts = [
                [x-w/2, 0, z-d/2],      # Bottom 4 vertices
                [x+w/2, 0, z-d/2],
                [x+w/2, 0, z+d/2],
                [x-w/2, 0, z+d/2],
                [x-w/2, max_height, z-d/2],  # Top 4 vertices
                [x+w/2, max_height, z-d/2],
                [x+w/2, max_height, z+d/2],
                [x-w/2, max_height, z+d/2]
            ]
            
            # Write vertices
            for v in verts:
                f.write(f"v {v[0]} {v[1]} {v[2]}\n")
            
        f.write("\n")
        
        # Write faces as a single object
        f.write("o Histogram_Combined\n\n")
        
        col_idx = 0
        for pos, data in columns.items():
            if not data['heights']:
                continue
                
            x, z = pos
            max_height = max(data['heights'])
            
            if max_height <= 0:
                continue
            
            # Calculate vertex indices for this column
            base = col_idx * 8 + 1
            
            # Write faces
            # Bottom
            f.write(f"f {base} {base+1} {base+2} {base+3}\n")
            # Top
            f.write(f"f {base+4} {base+7} {base+6} {base+5}\n")
            # Sides
            f.write(f"f {base} {base+4} {base+5} {base+1}\n")  # Front
            f.write(f"f {base+1} {base+5} {base+6} {base+2}\n")  # Right
            f.write(f"f {base+2} {base+6} {base+7} {base+3}\n")  # Back
            f.write(f"f {base+3} {base+7} {base+4} {base}\n")  # Left
            
            col_idx += 1
    
    print(f"Fixed {col_idx} columns combined into single mesh")
    print(f"Output saved to: {output_file}")

# Alternative approach: Create multiple OBJ files to handle the limitation
def create_multiple_obj_files(input_file="Histogram_Columns_quadrant_neg_X_neg_Y.obj", output_prefix="histogram_part"):
    # Read the file
    vertices = []
    faces = []
    
    with open(input_file, 'r') as f:
        for line in f:
            if line.startswith('v '):
                parts = line.split()
                x, y, z = float(parts[1]), float(parts[2]), float(parts[3])
                vertices.append([x, y, z])
            elif line.startswith('f '):
                parts = line.split()
                face = [int(p.split('/')[0]) for p in parts[1:]]
                faces.append(face)
    
    # Group vertices by their X,Z positions
    columns = {}
    grid_size = 0.033
    
    for i, v in enumerate(vertices):
        x_grid = round(v[0] / grid_size) * grid_size
        z_grid = round(v[2] / grid_size) * grid_size
        key = (x_grid, z_grid)
        
        if key not in columns:
            columns[key] = {'vertices': [], 'heights': []}
        
        columns[key]['vertices'].append(i)
        columns[key]['heights'].append(v[1])
    
    # Create multiple OBJ files, each with a subset of columns
    MAX_COLUMNS_PER_FILE = 50  # Adjust this to stay within Godot's limits
    
    column_list = [pos for pos, data in columns.items() if data['heights'] and max(data['heights']) > 0]
    
    for file_idx in range(0, len(column_list), MAX_COLUMNS_PER_FILE):
        output_file = f"{output_prefix}_{file_idx // MAX_COLUMNS_PER_FILE}.obj"
        
        with open(output_file, 'w') as f:
            f.write(f"# Histogram Part {file_idx // MAX_COLUMNS_PER_FILE}\n\n")
            
            # Write vertices for this subset
            for i in range(file_idx, min(file_idx + MAX_COLUMNS_PER_FILE, len(column_list))):
                pos = column_list[i]
                x, z = pos
                max_height = max(columns[pos]['heights'])
                
                # Column dimensions - make columns touch
                w = grid_size  # Width = grid size (no gap)
                d = grid_size  # Depth = grid size (no gap)
                
                # Define vertices
                verts = [
                    [x-w/2, 0, z-d/2],
                    [x+w/2, 0, z-d/2],
                    [x+w/2, 0, z+d/2],
                    [x-w/2, 0, z+d/2],
                    [x-w/2, max_height, z-d/2],
                    [x+w/2, max_height, z-d/2],
                    [x+w/2, max_height, z+d/2],
                    [x-w/2, max_height, z+d/2]
                ]
                
                for v in verts:
                    f.write(f"v {v[0]} {v[1]} {v[2]}\n")
            
            f.write("\n")
            
            # Write faces for this subset
            for col_idx in range(file_idx, min(file_idx + MAX_COLUMNS_PER_FILE, len(column_list))):
                local_idx = col_idx - file_idx
                base = local_idx * 8 + 1
                
                # All faces for this column
                f.write(f"f {base} {base+1} {base+2} {base+3}\n")  # Bottom
                f.write(f"f {base+4} {base+7} {base+6} {base+5}\n")  # Top
                f.write(f"f {base} {base+4} {base+5} {base+1}\n")  # Front
                f.write(f"f {base+1} {base+5} {base+6} {base+2}\n")  # Right
                f.write(f"f {base+2} {base+6} {base+7} {base+3}\n")  # Back
                f.write(f"f {base+3} {base+7} {base+4} {base}\n")  # Left
    
    print(f"Created {(len(column_list) + MAX_COLUMNS_PER_FILE - 1) // MAX_COLUMNS_PER_FILE} OBJ files")

# Run the single approach
if __name__ == "__main__":
    # Create single combined file
    fix_histogram_for_godot()
    
    print("\nImport Instructions for Godot:")
    print("1. Import 'histogram_godot.obj'")
    print("2. Use default material for best results")