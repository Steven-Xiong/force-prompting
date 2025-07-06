#!/bin/bash

# Enhanced data generation script using GPT4Motion's BlenderTool
echo "Starting enhanced rolling balls rendering with depth and sketch..."

# Working directory is force-prompting
echo "Working directory: $(pwd)"

# Use GPT4Motion's Blender installation
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"

# Output directory - INSIDE force-prompting project
OUTPUT_BASE_DIR="scratch/rolling_balls/enhanced_output"
mkdir -p $OUTPUT_BASE_DIR

# Number of scenes to generate
NUM_SCENES=10

# Ball types to use
BALL_TYPES=("basketball" "soccer" "tennis" "bowling")

# Generate multiple scenes with different ball types
for i in $(seq 1 $NUM_SCENES); do
    echo "==========================================="
    echo "Generating scene $i/$NUM_SCENES..."
    
    # Randomly select ball type
    BALL_TYPE=${BALL_TYPES[$((RANDOM % ${#BALL_TYPES[@]}))]}
    
    # Random number of balls (2-5)
    NUM_BALLS=$((RANDOM % 4 + 2))
    
    # Scene output directory
    SCENE_NAME="scene_$(printf "%04d" $i)_${BALL_TYPE}_${NUM_BALLS}balls"
    SCENE_OUTPUT_DIR="$OUTPUT_BASE_DIR/$SCENE_NAME"
    
    echo "Ball type: $BALL_TYPE, Number of balls: $NUM_BALLS"
    
    # Run Blender with enhanced script
    $BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_enhanced.py -- \
        --output_dir $SCENE_OUTPUT_DIR \
        --num_balls $NUM_BALLS \
        --ball_type $BALL_TYPE \
        --frames 120 \
        --seed $i
    
    echo "Scene $i complete!"
done

echo "==========================================="
echo "All scenes rendered! Converting to videos..."

# Convert PNGs to MP4s with proper naming
python3 << 'EOF'
import os
import cv2
import json
from pathlib import Path
import numpy as np

output_base_dir = "scratch/rolling_balls/enhanced_output"
video_output_dir = "scratch/rolling_balls/videos_enhanced"
os.makedirs(video_output_dir, exist_ok=True)

# Process each scene
for scene_dir in sorted(Path(output_base_dir).glob("scene_*")):
    scene_name = scene_dir.name
    print(f"\nProcessing {scene_name}...")
    
    # Create metadata
    metadata = {
        "scene_name": scene_name,
        "ball_type": scene_name.split("_")[2],
        "num_balls": int(scene_name.split("_")[3].replace("balls", "")),
        "frames": 120,
        "resolution": [512, 512]
    }
    
    # Save metadata
    with open(scene_dir / "metadata.json", "w") as f:
        json.dump(metadata, f, indent=2)
    
    # Define paths based on GPT4Motion's output structure
    rgb_dir = scene_dir / "freestyle"  # GPT4Motion saves RGB in freestyle dir
    depth_dir = scene_dir / "depth"
    sketch_dir = scene_dir / "freestyle"  # Same as RGB
    mask_dir = scene_dir / "mask"
    
    # Process RGB frames
    rgb_frames = sorted(rgb_dir.glob("*.png"))
    if rgb_frames:
        # Read first frame to get dimensions
        first_frame = cv2.imread(str(rgb_frames[0]))
        if first_frame is not None:
            height, width = first_frame.shape[:2]
            
            # Create video writer
            fourcc = cv2.VideoWriter_fourcc(*'mp4v')
            video_path = str(Path(video_output_dir) / f"{scene_name}.mp4")
            out = cv2.VideoWriter(video_path, fourcc, 24.0, (width, height))
            
            # Write frames
            for frame_path in rgb_frames:
                frame = cv2.imread(str(frame_path))
                if frame is not None:
                    out.write(frame)
            
            out.release()
            print(f"  Created RGB video: {video_path}")
    
    # Process depth frames
    depth_frames = sorted(depth_dir.glob("*.png"))
    if depth_frames:
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        depth_video_path = str(Path(video_output_dir) / f"{scene_name}_depth.mp4")
        
        # Get dimensions from first frame
        first_depth = cv2.imread(str(depth_frames[0]))
        if first_depth is not None:
            height, width = first_depth.shape[:2]
            depth_out = cv2.VideoWriter(depth_video_path, fourcc, 24.0, (width, height))
            
            for frame_path in depth_frames:
                frame = cv2.imread(str(frame_path))
                if frame is not None:
                    depth_out.write(frame)
            
            depth_out.release()
            print(f"  Created depth video: {depth_video_path}")
    
    # Process mask frames (if available)
    mask_frames = sorted(mask_dir.glob("*.png"))
    if mask_frames:
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        mask_video_path = str(Path(video_output_dir) / f"{scene_name}_mask.mp4")
        
        first_mask = cv2.imread(str(mask_frames[0]))
        if first_mask is not None:
            height, width = first_mask.shape[:2]
            mask_out = cv2.VideoWriter(mask_video_path, fourcc, 24.0, (width, height))
            
            for frame_path in mask_frames:
                frame = cv2.imread(str(frame_path))
                if frame is not None:
                    mask_out.write(frame)
            
            mask_out.release()
            print(f"  Created mask video: {mask_video_path}")

print("\nVideo conversion complete!")
print(f"Videos saved to: {video_output_dir}")

# Generate summary
total_videos = len(list(Path(video_output_dir).glob("*.mp4")))
print(f"\nTotal videos created: {total_videos}")
EOF

# Generate CSV for the dataset (compatible with original pipeline)
echo "==========================================="
echo "Generating dataset CSV..."

DIR_VIDEOS="scratch/rolling_balls/videos_enhanced"
OUTPUT_CSV="datasets/point-force/train/enhanced_rolling_balls_$(date +%Y%m%d).csv"

# Create CSV generation script
python3 << 'EOF'
import os
import csv
from pathlib import Path

video_dir = "scratch/rolling_balls/videos_enhanced"
output_csv = "datasets/point-force/train/enhanced_rolling_balls.csv"

# Create output directory
os.makedirs(os.path.dirname(output_csv), exist_ok=True)

# Collect all RGB videos (not depth/mask)
videos = []
for video_path in sorted(Path(video_dir).glob("scene_*.mp4")):
    if "_depth" not in str(video_path) and "_mask" not in str(video_path):
        videos.append({
            "video_path": str(video_path),
            "scene_name": video_path.stem,
            "ball_type": video_path.stem.split("_")[2],
            "num_balls": int(video_path.stem.split("_")[3].replace("balls", ""))
        })

# Write CSV
with open(output_csv, 'w', newline='') as f:
    if videos:
        writer = csv.DictWriter(f, fieldnames=videos[0].keys())
        writer.writeheader()
        writer.writerows(videos)

print(f"CSV created: {output_csv}")
print(f"Total entries: {len(videos)}")
EOF

echo "==========================================="
echo "Enhanced data generation complete!"
echo ""
echo "Output locations:"
echo "  - Raw frames: $OUTPUT_BASE_DIR/"
echo "  - Videos: scratch/rolling_balls/videos_enhanced/"
echo "  - CSV: datasets/point-force/train/enhanced_rolling_balls_$(date +%Y%m%d).csv"
echo ""
echo "Each scene includes:"
echo "  - RGB frames"
echo "  - Depth maps"
echo "  - Sketch/edge detection (Freestyle)"
echo "  - Binary masks" 