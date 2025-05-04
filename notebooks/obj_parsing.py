#!/usr/bin/env python3
import sys
import re
from collections import defaultdict
import math

def parse_obj_file(filename):
    """Parse an OBJ file and extract vertices and faces."""
    vertices = []
    faces = []
    
    with open(filename, 'r') as file:
        for line in file:
            line = line.strip()
            
            # Parse vertices
            if line.startswith('v '):
                parts = line.split()
                if len(parts) >= 4:
                    vertices.append([float(parts[1]), float(parts[2]), float(parts[3])])
            
            # Parse faces
            elif line.startswith('f '):
                parts = line.split()
                face = []
                for part in parts[1:]:
                    # Handle both 'v' and 'v//vn' formats
                    vertex_idx = part.split('//')[0]
                    face.append(int(vertex_idx) - 1)  # OBJ indices start at 1
                faces.append(face)
    
    return vertices, faces

def extract_histogram_data(vertices):
    """Extract histogram data by grouping vertices by their X-Z position."""
    histogram_data = defaultdict(lambda: {'min_y': float('inf'), 'max_y': float('-inf'), 'base_vertices': []})
    
    # Group vertices by their X-Z position (rounded to handle floating point imprecision)
    for i, vertex in enumerate(vertices):
        # Round to handle floating point comparisons
        x_z_key = (round(vertex[0], 6), round(vertex[2], 6))
        
        histogram_data[x_z_key]['min_y'] = min(histogram_data[x_z_key]['min_y'], vertex[1])
        histogram_data[x_z_key]['max_y'] = max(histogram_data[x_z_key]['max_y'], vertex[1])
        histogram_data[x_z_key]['base_vertices'].append(vertex)
    
    return histogram_data

def estimate_column_width(base_vertices):
    """Estimate the width of a column based on its base vertices."""
    x_coords = [v[0] for v in base_vertices]
    z_coords = [v[2] for v in base_vertices]
    
    if not x_coords or not z_coords:
        return 0.01  # Default small width
    
    x_width = max(x_coords) - min(x_coords)
    z_width = max(z_coords) - min(z_coords)
    
    # Use the maximum dimension as width, with some padding
    return max(x_width, z_width) * 0.9 if max(x_width, z_width) > 0 else 0.01

def create_box_vertices(center_x, center_z, base_y, height, width):
    """Create vertices for a rectangular box."""
    half_width = width / 2
    
    # Define the 8 vertices of a box
    vertices = [
        # Bottom face
        [center_x - half_width, base_y, center_z - half_width],
        [center_x + half_width, base_y, center_z - half_width],
        [center_x + half_width, base_y, center_z + half_width],
        [center_x - half_width, base_y, center_z + half_width],
        # Top face
        [center_x - half_width, base_y + height, center_z - half_width],
        [center_x + half_width, base_y + height, center_z - half_width],
        [center_x + half_width, base_y + height, center_z + half_width],
        [center_x - half_width, base_y + height, center_z + half_width],
    ]
    
    # Define faces (as triangles)
    faces = [
        # Bottom face
        [0, 1, 2], [0, 2, 3],
        # Top face
        [4, 5, 6], [4, 6, 7],
        # Front face
        [0, 1, 5], [0, 5, 4],
        # Back face
        [2, 3, 7], [2, 7, 6],
        # Left face
        [0, 3, 7], [0, 7, 4],
        # Right face
        [1, 2, 6], [1, 6, 5],
    ]
    
    return vertices, faces

def write_obj_file(filename, vertices, faces):
    """Write vertices and faces to an OBJ file."""
    with open(filename, 'w') as file:
        # Write header
        file.write("# Converted histogram OBJ file\n")
        file.write("# Generated with OBJ to Histogram Converter\n")
        file.write("o Histogram_Columns\n\n")
        
        # Write vertices
        for vertex in vertices:
            file.write(f"v {vertex[0]} {vertex[1]} {vertex[2]}\n")
        file.write("\n")
        
        # Write normals for better lighting
        normals = [
            [0, -1, 0],  # Bottom
            [0, 1, 0],   # Top
            [-1, 0, 0],  # Left
            [1, 0, 0],   # Right
            [0, 0, -1],  # Front
            [0, 0, 1],   # Back
        ]
        
        for normal in normals:
            file.write(f"vn {normal[0]} {normal[1]} {normal[2]}\n")
        file.write("\n")
        
        # Write faces with normals
        for i, face in enumerate(faces):
            # Determine which normal to use based on face index
            normal_idx = (i // 2) + 1  # Each pair of triangles shares a normal
            # OBJ indices start at 1
            face_str = " ".join([f"{v+1}//{normal_idx}" for v in face])
            file.write(f"f {face_str}\n")

def convert_obj_to_histogram(input_file, output_file):
    """Convert an OBJ file to a proper histogram."""
    print(f"Loading {input_file}...")
    vertices, faces = parse_obj_file(input_file)
    print(f"Found {len(vertices)} vertices and {len(faces)} faces")
    
    print("Extracting histogram data...")
    histogram_data = extract_histogram_data(vertices)
    print(f"Found {len(histogram_data)} histogram columns")
    
    print("Creating rectangular columns...")
    new_vertices = []
    new_faces = []
    vertex_offset = 0
    
    for (x, z), data in histogram_data.items():
        if data['max_y'] == float('-inf'):  # Skip empty columns
            continue
            
        height = data['max_y'] - data['min_y']
        width = estimate_column_width(data['base_vertices'])
        
        # Create a box for this column
        box_vertices, box_faces = create_box_vertices(x, z, data['min_y'], height, width)
        
        # Add box vertices to the main list
        new_vertices.extend(box_vertices)
        
        # Adjust face indices and add to the main list
        for face in box_faces:
            new_faces.append([v + vertex_offset for v in face])
        
        vertex_offset += 8  # 8 vertices per box
    
    print(f"Writing to {output_file}...")
    write_obj_file(output_file, new_vertices, new_faces)
    print("Conversion complete!")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python convert_obj_to_histogram.py input.obj [output.obj]")
        print("If output file is not specified, it will use input filename with '_histogram' suffix")
        sys.exit(1)
    
    input_file = sys.argv[1]
    
    if len(sys.argv) > 2:
        output_file = sys.argv[2]
    else:
        # Create output filename by adding '_histogram' before the extension
        base, ext = input_file.rsplit('.', 1)
        output_file = f"{base}_histogram.{ext}"
    
    convert_obj_to_histogram(input_file, output_file)