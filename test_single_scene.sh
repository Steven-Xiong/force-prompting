#!/bin/bash

# Test a single scene to verify the complete rendering pipeline
echo "Testing single scene rendering..."
echo "================================"

# Working directory is force-prompting
echo "Working directory: $(pwd)"

# Use GPT4Motion's Blender installation
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"

# Test output directory
TEST_OUTPUT_DIR="scratch/rolling_balls/single_scene_test"
mkdir -p $TEST_OUTPUT_DIR

echo ""
echo "Testing force-prompting style script with minimal settings..."

# Test with minimal settings for fast execution
$BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_force_prompting_style.py -- \
    --output_dir $TEST_OUTPUT_DIR \
    --num_balls 2 \
    --frames 5 \
    --resolution 128 \
    --seed 42

echo ""
echo "Test complete!"
echo "Check output in: $TEST_OUTPUT_DIR"

# List the generated output
echo ""
echo "Generated files:"
find $TEST_OUTPUT_DIR -type f -name "*.png" -o -name "*.json" | head -20

echo ""
echo "Directory structure:"
ls -la $TEST_OUTPUT_DIR/*/

echo ""
echo "If you see PNG files and directory structure above, the pipeline is working correctly!" 