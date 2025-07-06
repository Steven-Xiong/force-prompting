#!/bin/bash

# Render rolling balls with RGB, depth, and sketch outputs
echo "Starting rolling balls rendering with depth and sketch..."

# Working directory is force-prompting
echo "Working directory: $(pwd)"

# Set Blender path (adjust if needed)
# BLENDER_PATH="/usr/bin/blender"  # Default system blender
# If using a specific Blender version like in GPT4Motion:
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"

# Output directory - INSIDE force-prompting project
OUTPUT_DIR="scratch/rolling_balls/pngs_with_depth_sketch"

# Number of scenes to generate
NUM_SCENES=10

# Create output directory
mkdir -p $OUTPUT_DIR

# Generate multiple scenes
for i in $(seq 1 $NUM_SCENES); do
    echo "Generating scene $i/$NUM_SCENES..."
    
    SCENE_OUTPUT_DIR="$OUTPUT_DIR/scene_$(printf "%04d" $i)"
    
    # Run Blender in background mode with our Python script
    $BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_with_depth_sketch.py -- \
        --output_dir $SCENE_OUTPUT_DIR \
        --num_balls $(shuf -i 2-5 -n 1) \
        --frames 120 \
        --resolution 512
done

echo "Rendering complete!"

# Convert PNGs to MP4 (keeping the original logic)
RENDER_DIR=$OUTPUT_DIR
echo "Converting PNGs to MP4..."

# Create a Python script to handle conversion with depth and sketch
python3 << EOF
import os
import cv2
import numpy as np
from pathlib import Path

render_dir = "$RENDER_DIR"
output_video_dir = "scratch/rolling_balls/videos_with_depth_sketch"
os.makedirs(output_video_dir, exist_ok=True)

# Process each scene
for scene_dir in sorted(Path(render_dir).glob("scene_*")):
    scene_name = scene_dir.name
    print(f"Processing {scene_name}...")
    
    # Define paths
    rgb_dir = scene_dir / "rgb"
    depth_dir = scene_dir / "depth"
    sketch_dir = scene_dir / "sketch"
    
    # Get frame files
    rgb_frames = sorted(rgb_dir.glob("*.png"))
    
    if not rgb_frames:
        print(f"No frames found in {rgb_dir}")
        continue
    
    # Read first frame to get dimensions
    first_frame = cv2.imread(str(rgb_frames[0]))
    height, width = first_frame.shape[:2]
    
    # Create video writers
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    
    rgb_out = cv2.VideoWriter(
        str(Path(output_video_dir) / f"{scene_name}_rgb.mp4"),
        fourcc, 24.0, (width, height)
    )
    
    depth_out = cv2.VideoWriter(
        str(Path(output_video_dir) / f"{scene_name}_depth.mp4"),
        fourcc, 24.0, (width, height)
    )
    
    sketch_out = cv2.VideoWriter(
        str(Path(output_video_dir) / f"{scene_name}_sketch.mp4"),
        fourcc, 24.0, (width, height)
    )
    
    # Process frames
    for i, rgb_frame_path in enumerate(rgb_frames):
        # Read RGB frame
        rgb_frame = cv2.imread(str(rgb_frame_path))
        rgb_out.write(rgb_frame)
        
        # Read corresponding depth frame
        depth_frame_path = depth_dir / f"depth_{i:04d}.png"
        if depth_frame_path.exists():
            depth_frame = cv2.imread(str(depth_frame_path))
            depth_out.write(depth_frame)
        
        # Read corresponding sketch frame
        sketch_frame_path = sketch_dir / f"sketch_{i:04d}.png"
        if sketch_frame_path.exists():
            sketch_frame = cv2.imread(str(sketch_frame_path))
            sketch_out.write(sketch_frame)
    
    # Release video writers
    rgb_out.release()
    depth_out.release()
    sketch_out.release()
    
    print(f"Created videos for {scene_name}")

print("Video conversion complete!")
EOF

# Rest of the original data_gen.sh logic for CSV generation
echo "Preparing data for training..."

# Directory setup
DIR_BALLS="scratch/rolling_balls/videos_with_depth_sketch"
DIR_PLANTS="/oscar/data/superlab/users/nates_stuff/cogvideox-controlnet/data/2025-04-07-point-force-unified-model/videos-05-11-ablation-no-bowling-balls-temp-justflowers"
DIR_COMBINED="datasets/point-force/train/point_force_with_depth_sketch_$(date +%Y%m%d)"

# Generate CSV for balls (if the script exists)
if [ -f "scripts/build_synthetic_datasets/poke_model_rolling_balls/generate_csv_for_plants_and_balls_from_dir.py" ]; then
    echo "Generating CSV for balls dataset..."
    python scripts/build_synthetic_datasets/poke_model_rolling_balls/generate_csv_for_plants_and_balls_from_dir.py \
        --file_dir ${DIR_BALLS} \
        --file_type video \
        --output_path ${DIR_COMBINED}_balls.csv \
        --backgrounds_json_path_soccer scripts/build_synthetic_datasets/poke_model_rolling_balls/backgrounds_soccer.json \
        --backgrounds_json_path_bowling scripts/build_synthetic_datasets/poke_model_rolling_balls/backgrounds_bowling.json \
        --take_subset_size 100
fi

echo "Data generation with depth and sketch complete!" 