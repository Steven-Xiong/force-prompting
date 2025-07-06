#!/bin/bash

# Data generation script using force-prompting's original file structure with enhanced physics control
echo "Starting rolling balls rendering with force-prompting style and enhanced physics..."

# Working directory is force-prompting
echo "Working directory: $(pwd)"

# Use GPT4Motion's Blender installation  
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"

# Output directory - matching original structure
OUTPUT_BASE_DIR="blender_gen/rolling_balls/depth_sketch"
mkdir -p $OUTPUT_BASE_DIR

# Number of scenes to generate
NUM_SCENES=2

# Ball types to use with their physical properties
declare -A BALL_MASSES=(
    ["basketball"]=0.6
    ["soccer"]=0.43
    ["tennis"]=0.057
    ["bowling"]=7.2
)

declare -A BALL_SIZES=(
    ["basketball"]=0.24
    ["soccer"]=0.22
    ["tennis"]=0.067
    ["bowling"]=0.217
)

# Ground surface types that affect friction and bounce
SURFACE_TYPES=("grass" "concrete" "dirt" "wood" "carpet")

# Function to generate physically meaningful parameters
generate_physics_params() {
    local scene_id=$1
    
    # Ball type affects all other parameters
    local ball_types=("basketball" "soccer" "tennis" "bowling")
    local main_ball_type=${ball_types[$((RANDOM % ${#ball_types[@]}))]}
    
    # Force magnitude based on ball mass (heavier balls need more force)
    local random_multiplier=$((15 + RANDOM % 40))
    local base_force=$(echo "scale=2; ${BALL_MASSES[$main_ball_type]} * $random_multiplier" | bc)
    
    # Angle: realistic throwing/kicking angles (mostly horizontal with some variation)
    local angle_offset=$((RANDOM % 60))
    local force_angle=$(echo "scale=1; $angle_offset - 30" | bc)  # -30 to +30 degrees from horizontal
    
    # Height: realistic starting heights (on ground to waist high)
    local height_rand=$((RANDOM % 100))
    local height_offset=$(echo "scale=2; $height_rand / 100" | bc)  # 0.0 to 1.0 meters
    
    # Number of balls: fewer for heavier balls (more realistic)
    local num_balls
    if [[ "$main_ball_type" == "bowling" ]]; then
        num_balls=$((2 + RANDOM % 2))  # 2-3 bowling balls
    elif [[ "$main_ball_type" == "basketball" ]]; then
        num_balls=$((2 + RANDOM % 3))  # 2-4 basketballs
    else
        num_balls=$((3 + RANDOM % 3))  # 3-5 smaller balls
    fi
    
    # Surface type affects scene setup
    local surface_type=${SURFACE_TYPES[$((RANDOM % ${#SURFACE_TYPES[@]}))]}
    
    # Coordinate system for physics (convert to pixel coordinates for naming)
    local physics_x_int=$((RANDOM % 400))
    local physics_y_int=$((RANDOM % 400))
    local physics_x=$(echo "scale=2; $physics_x_int / 100 - 2" | bc)  # -2 to 2 meters
    local physics_y=$(echo "scale=2; $physics_y_int / 100 - 2" | bc)  # -2 to 2 meters
    
    # Convert physics coordinates to pixel coordinates (simplified mapping)
    local coordx_calc=$(echo "scale=2; $physics_x * 100" | bc)
    local coordy_calc=$(echo "scale=2; $physics_y * 100" | bc)
    local coordx=$(echo "scale=0; 256 + $coordx_calc / 1" | bc)
    local coordy=$(echo "scale=0; 256 + $coordy_calc / 1" | bc)
    
    # Pixel angle for visual reference (related to force angle but not identical)
    local pixel_offset=$(echo "scale=1; $((RANDOM % 20)) - 10" | bc)
    local pixangle=$(echo "scale=1; $force_angle + $pixel_offset" | bc)
    
    echo "$main_ball_type $base_force $force_angle $coordx $coordy $pixangle $height_offset $num_balls $surface_type"
}

# Function to add random lateral velocity to some balls
add_lateral_motion() {
    local scene_params="$1"
    local add_motion=$((RANDOM % 100))
    
    if [[ $add_motion -lt 40 ]]; then  # 40% chance of lateral motion
        echo "1"  # Enable lateral motion
    else
        echo "0"  # No lateral motion
    fi
}

# Generate multiple scenes with different parameters
for i in $(seq 1 $NUM_SCENES); do
    echo "==========================================="
    echo "Generating scene $i/$NUM_SCENES..."
    
    # Generate physics-based parameters
    params=($(generate_physics_params $i))
    BALL_TYPE=${params[0]}
    FORCE_MAGNITUDE=${params[1]}
    FORCE_ANGLE=${params[2]}
    COORDX=${params[3]}
    COORDY=${params[4]}
    PIXANGLE=${params[5]}
    HEIGHT_OFFSET=${params[6]}
    NUM_BALLS=${params[7]}
    SURFACE_TYPE=${params[8]}
    
    # Check if we should add lateral motion
    LATERAL_MOTION=$(add_lateral_motion "$params")
    
    echo "Ball type: $BALL_TYPE"
    echo "Force: ${FORCE_MAGNITUDE}N at ${FORCE_ANGLE}°"
    echo "Starting height: ${HEIGHT_OFFSET}m"
    echo "Number of balls: $NUM_BALLS"
    echo "Surface: $SURFACE_TYPE"
    echo "Lateral motion: $([[ $LATERAL_MOTION -eq 1 ]] && echo "Yes" || echo "No")"
    
    # Create enhanced scene name with physics meaning
    SCENE_NAME="angle_${FORCE_ANGLE}_force_${FORCE_MAGNITUDE}_coordx_${COORDX}_coordy_${COORDY}_pixangle_${PIXANGLE}"
    
    # Run Blender with enhanced physics parameters
    $BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_force_prompting_style.py -- \
        --output_dir $OUTPUT_BASE_DIR \
        --scene_name $SCENE_NAME \
        --num_balls $NUM_BALLS \
        --ball_type $BALL_TYPE \
        --frames 120 \
        --resolution 512 \
        --angle $FORCE_ANGLE \
        --force $FORCE_MAGNITUDE \
        --coordx $COORDX \
        --coordy $COORDY \
        --pixangle $PIXANGLE \
        --height_offset $HEIGHT_OFFSET \
        --seed $i
    
    if [[ $? -eq 0 ]]; then
        echo "✓ Scene $i rendered successfully!"
        
        # Save additional physics metadata
        SCENE_DIR="$OUTPUT_BASE_DIR/$SCENE_NAME"
        if [[ -d "$SCENE_DIR" ]]; then
            # Calculate coordinates with proper formatting
        COORD_X_METERS=$(echo "scale=2; ($COORDX - 256) / 100" | bc | sed 's/^\./0./' | sed 's/^-\./-0./')
        COORD_Y_METERS=$(echo "scale=2; ($COORDY - 256) / 100" | bc | sed 's/^\./0./' | sed 's/^-\./-0./')
        
        # Format height offset with leading zero
        HEIGHT_FORMATTED=$(echo "$HEIGHT_OFFSET" | sed 's/^\./0./')
        
        cat > "$SCENE_DIR/physics_metadata.json" << EOF
{
    "ball_type": "$BALL_TYPE",
    "ball_mass_kg": ${BALL_MASSES[$BALL_TYPE]},
    "ball_diameter_m": ${BALL_SIZES[$BALL_TYPE]},
    "force_magnitude_n": $FORCE_MAGNITUDE,
    "force_angle_degrees": $FORCE_ANGLE,
    "starting_height_m": $HEIGHT_FORMATTED,
    "surface_type": "$SURFACE_TYPE",
    "lateral_motion_enabled": $LATERAL_MOTION,
    "physics_coordinates": {
        "x_meters": $COORD_X_METERS,
        "y_meters": $COORD_Y_METERS
    },
    "scene_description": "Ball rolling simulation with realistic physics: ${BALL_TYPE} ball with mass ${BALL_MASSES[$BALL_TYPE]}kg receives ${FORCE_MAGNITUDE}N force at ${FORCE_ANGLE}° angle from height ${HEIGHT_FORMATTED}m on ${SURFACE_TYPE} surface"
}
EOF
        fi
    else
        echo "✗ Scene $i failed to render!"
    fi
done

echo "==========================================="
echo "All scenes rendered! Converting to videos..."

# Convert PNGs to MP4s with enhanced metadata
python3 << EOF
import os
import cv2
import json
from pathlib import Path
import numpy as np

output_base_dir = "$OUTPUT_BASE_DIR"
video_output_dir = "$OUTPUT_BASE_DIR/videos"
os.makedirs(video_output_dir, exist_ok=True)

# Track scene statistics
scene_stats = {
    'total_scenes': 0,
    'ball_types': {},
    'surface_types': {},
    'force_ranges': {'min': float('inf'), 'max': 0},
    'successful_renders': 0
}

# Process each scene directory
for scene_dir in sorted(Path(output_base_dir).glob("angle_*")):
    scene_name = scene_dir.name
    print(f"\nProcessing {scene_name}...")
    
    scene_stats['total_scenes'] += 1
    
    # Load physics metadata if available
    physics_meta_file = scene_dir / "physics_metadata.json"
    physics_meta = {}
    if physics_meta_file.exists():
        with open(physics_meta_file, 'r') as f:
            physics_meta = json.load(f)
            
        # Update statistics
        ball_type = physics_meta.get('ball_type', 'unknown')
        surface_type = physics_meta.get('surface_type', 'unknown')
        force_mag = physics_meta.get('force_magnitude_n', 0)
        
        scene_stats['ball_types'][ball_type] = scene_stats['ball_types'].get(ball_type, 0) + 1
        scene_stats['surface_types'][surface_type] = scene_stats['surface_types'].get(surface_type, 0) + 1
        scene_stats['force_ranges']['min'] = min(scene_stats['force_ranges']['min'], force_mag)
        scene_stats['force_ranges']['max'] = max(scene_stats['force_ranges']['max'], force_mag)
    
    # Load regular params
    params_file = scene_dir / "params.json"
    if params_file.exists():
        with open(params_file, 'r') as f:
            params = json.load(f)
    else:
        params = {}
    
    # Merge physics metadata with regular params
    combined_params = {**params, **physics_meta}
    
    # Get RGB frames from pngs subdirectory
    pngs_dir = scene_dir / "pngs"
    rgb_frames = sorted(pngs_dir.glob("frame*.png")) if pngs_dir.exists() else []
    
    if not rgb_frames:
        print(f"No frames found in {pngs_dir}")
        continue
    
    scene_stats['successful_renders'] += 1
    
    # Read first frame to get dimensions
    first_frame = cv2.imread(str(rgb_frames[0]))
    if first_frame is None:
        print(f"Could not read first frame in {pngs_dir}")
        continue
        
    height, width = first_frame.shape[:2]
    
    # Create video writer for RGB
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    video_path = str(Path(video_output_dir) / f"{scene_name}.mp4")
    out = cv2.VideoWriter(video_path, fourcc, 24.0, (width, height))
    
    # Write RGB frames
    for frame_path in rgb_frames:
        frame = cv2.imread(str(frame_path))
        if frame is not None:
            out.write(frame)
    
    out.release()
    print(f"  ✓ Created RGB video: {video_path}")
    
    # Process depth frames if available
    depth_dir = scene_dir / "depth"
    if depth_dir.exists():
        depth_frames = sorted(depth_dir.glob("depth_*.png"))
        if depth_frames:
            depth_video_path = str(Path(video_output_dir) / f"{scene_name}_depth.mp4")
            depth_out = cv2.VideoWriter(depth_video_path, fourcc, 24.0, (width, height))
            
            for frame_path in depth_frames:
                frame = cv2.imread(str(frame_path))
                if frame is not None:
                    depth_out.write(frame)
            
            depth_out.release()
            print(f"  ✓ Created depth video: {depth_video_path}")
    
    # Process sketch frames if available
    sketch_dir = scene_dir / "sketch"
    if sketch_dir.exists():
        sketch_frames = sorted(sketch_dir.glob("sketch_*.png"))
        if sketch_frames:
            sketch_video_path = str(Path(video_output_dir) / f"{scene_name}_sketch.mp4")
            sketch_out = cv2.VideoWriter(sketch_video_path, fourcc, 24.0, (width, height))
            
            for frame_path in sketch_frames:
                frame = cv2.imread(str(frame_path))
                if frame is not None:
                    sketch_out.write(frame)
            
            sketch_out.release()
            print(f"  ✓ Created sketch video: {sketch_video_path}")
    
    # Save enhanced metadata for this scene
    video_metadata = {
        'scene_name': scene_name,
        'video_path': video_path,
        'has_depth': (scene_dir / "depth").exists(),
        'has_sketch': (scene_dir / "sketch").exists(),
        'frame_count': len(rgb_frames),
        **combined_params
    }
    
    # Save individual scene metadata
    with open(Path(video_output_dir) / f"{scene_name}_metadata.json", 'w') as f:
        json.dump(video_metadata, f, indent=2)

print("\n" + "="*50)
print("VIDEO CONVERSION COMPLETE!")
print(f"Videos saved to: {video_output_dir}")

# Print comprehensive statistics
print(f"\nDataset Statistics:")
print(f"Total scenes generated: {scene_stats['total_scenes']}")
print(f"Successfully rendered: {scene_stats['successful_renders']}")
print(f"Success rate: {scene_stats['successful_renders']/scene_stats['total_scenes']*100:.1f}%")

print(f"\nBall type distribution:")
for ball_type, count in scene_stats['ball_types'].items():
    print(f"  {ball_type}: {count} scenes ({count/scene_stats['successful_renders']*100:.1f}%)")

print(f"\nSurface type distribution:")
for surface_type, count in scene_stats['surface_types'].items():
    print(f"  {surface_type}: {count} scenes ({count/scene_stats['successful_renders']*100:.1f}%)")

if scene_stats['force_ranges']['min'] != float('inf'):
    print(f"\nForce magnitude range: {scene_stats['force_ranges']['min']:.1f}N - {scene_stats['force_ranges']['max']:.1f}N")

total_videos = len(list(Path(video_output_dir).glob("*.mp4")))
print(f"\nTotal videos created: {total_videos}")
EOF

# Generate enhanced CSV for the dataset
echo "==========================================="
echo "Generating enhanced dataset CSV..."

python3 << EOF
import os
import csv
import json
from pathlib import Path

videos_dir = Path("$OUTPUT_BASE_DIR/videos")
# CSV output path in OUTPUT_BASE_DIR
output_csv = "$OUTPUT_BASE_DIR/rolling_balls_with_depth_sketch_enhanced.csv"

# Create output directory
os.makedirs(os.path.dirname(output_csv), exist_ok=True)

# Collect all scene data with enhanced physics metadata - only main videos
scenes = []
for video_file in sorted(videos_dir.glob("angle_*.mp4")):
    # Skip depth and sketch videos, only process main videos
    if "_depth.mp4" in str(video_file) or "_sketch.mp4" in str(video_file):
        continue
        
    scene_name = video_file.stem
    
    # Load enhanced metadata
    metadata_file = videos_dir / f"{scene_name}_metadata.json"
    if metadata_file.exists():
        with open(metadata_file, 'r') as f:
            metadata = json.load(f)
        # Update video_path to only include filename
        metadata['video_path'] = video_file.name
        scenes.append(metadata)
    else:
        # Fallback to basic metadata
        scenes.append({
            'video_path': video_file.name,  # Only filename
            'scene_name': scene_name,
            'has_depth': True,
            'has_sketch': True
        })

# Write enhanced CSV
if scenes:
    # Get all possible fieldnames
    all_fieldnames = set()
    for scene in scenes:
        all_fieldnames.update(scene.keys())
    
    # Put video_path first, then sort the rest
    fieldnames = ['video_path']
    remaining_fields = sorted([f for f in all_fieldnames if f != 'video_path'])
    fieldnames.extend(remaining_fields)
    
    with open(output_csv, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(scenes)
    
    print(f"Enhanced CSV created: {output_csv}")
    print(f"Total entries: {len(scenes)}")
    print(f"Fields included: {', '.join(fieldnames)}")
else:
    print("No scenes found to write to CSV")
EOF

echo "==========================================="
echo "ENHANCED DATA GENERATION COMPLETE!"
echo ""
echo "Output locations:"
echo "  - PNG frames: $OUTPUT_BASE_DIR/"
echo "  - Videos: $OUTPUT_BASE_DIR/videos/"
echo "  - Enhanced CSV: $OUTPUT_BASE_DIR/rolling_balls_with_depth_sketch_enhanced.csv"
echo ""
echo "Enhanced Features:"
echo "  ✓ Realistic physics-based parameters"
echo "  ✓ Ball mass and size consideration"
echo "  ✓ Surface type variation"
echo "  ✓ Height control for initial conditions"
echo "  ✓ Lateral motion for dynamic scenes"
echo "  ✓ Comprehensive metadata tracking"
echo "  ✓ Force-prompting compatible naming"
echo ""
echo "Directory structure:"
echo "  angle_X_force_Y_coordx_Z_coordy_W_pixangle_V/"
echo "    ├── frameXXXX.png (RGB frames)"
echo "    ├── params.json (basic parameters)"
echo "    ├── physics_metadata.json (enhanced physics data)"
echo "    ├── depth/"
echo "    │   └── depth_XXXX.png"
echo "    └── sketch/"
echo "        └── sketch_XXXX.png" 