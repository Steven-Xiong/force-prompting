#!/bin/bash

# Test script for force-prompting style rendering
echo "Testing force-prompting style rendering..."
echo "This will generate ONE test scene to verify the setup"

# Change to the video_gen directory
cd "$(dirname "$0")/.."
echo "Working directory: $(pwd)"

# Use GPT4Motion's Blender
BLENDER_PATH="/u/zhexiao/video_gen/GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"

# Test output directory
TEST_OUTPUT_DIR="force-prompting/scratch/rolling_balls/test_pngs"
mkdir -p $TEST_OUTPUT_DIR

echo "==========================================="
echo "Running test render with force-prompting style..."

# Test with specific parameters
$BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_force_prompting_style.py -- \
    --output_dir $TEST_OUTPUT_DIR \
    --num_balls 3 \
    --ball_type basketball \
    --frames 10 \
    --resolution 512 \
    --angle 45.0 \
    --force 30.0 \
    --coordx 256 \
    --coordy 256 \
    --pixangle 45.0 \
    --seed 42

echo "==========================================="
echo "Checking output files..."

# Find the generated scene directory
SCENE_DIR=$(find $TEST_OUTPUT_DIR -name "angle_*" -type d | head -1)

if [ -n "$SCENE_DIR" ]; then
    echo "✓ Scene directory found: $SCENE_DIR"
    
    # Check RGB frames in pngs directory
    if [ -d "$SCENE_DIR/pngs" ]; then
        RGB_COUNT=$(ls -1 $SCENE_DIR/pngs/frame*.png 2>/dev/null | wc -l)
        echo "✓ RGB pngs directory found, frames: $RGB_COUNT"
    else
        echo "✗ RGB pngs directory not found"
    fi
    
    # Check params.json
    if [ -f "$SCENE_DIR/params.json" ]; then
        echo "✓ params.json found"
        cat "$SCENE_DIR/params.json"
    else
        echo "✗ params.json not found"
    fi
    
    # Check depth directory
    if [ -d "$SCENE_DIR/depth" ]; then
        DEPTH_COUNT=$(ls -1 $SCENE_DIR/depth/depth_*.png 2>/dev/null | wc -l)
        echo "✓ Depth directory found, frames: $DEPTH_COUNT"
    else
        echo "✗ Depth directory not found"
    fi
    
    # Check sketch directory
    if [ -d "$SCENE_DIR/sketch" ]; then
        SKETCH_COUNT=$(ls -1 $SCENE_DIR/sketch/sketch_*.png 2>/dev/null | wc -l)
        echo "✓ Sketch directory found, frames: $SKETCH_COUNT"
    else
        echo "✗ Sketch directory not found"
    fi
else
    echo "✗ No scene directory found"
fi

echo "==========================================="
echo "Test complete!"
echo ""
echo "Output location: $TEST_OUTPUT_DIR"
echo ""
echo "Directory structure:"
echo "  $SCENE_DIR/"
echo "    ├── params.json"
echo "    ├── pngs/          (RGB frames)"
echo "    ├── depth/         (Depth maps)"  
echo "    └── sketch/        (Edge detection)"
echo ""
echo "If everything looks good, run the full generation with:"
echo "  ./force-prompting/data_gen_force_prompting_style.sh" 