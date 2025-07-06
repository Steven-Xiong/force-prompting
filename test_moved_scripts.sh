#!/bin/bash

# Test script to verify that moved scripts work correctly
echo "Testing moved scripts in force-prompting..."

# Working directory is force-prompting
echo "Working directory: $(pwd)"

# Use GPT4Motion's Blender installation
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"

# Test output directory
TEST_OUTPUT_DIR="scratch/rolling_balls/test_moved_scripts"
mkdir -p $TEST_OUTPUT_DIR

echo "==========================================="
echo "Testing force-prompting style script..."

# Test force-prompting style script
$BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_force_prompting_style.py -- \
    --output_dir $TEST_OUTPUT_DIR \
    --num_balls 2 \
    --frames 10 \
    --resolution 256 \
    --seed 42

echo "==========================================="
echo "Testing enhanced script..."

# Test enhanced script
$BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_enhanced.py -- \
    --output_dir $TEST_OUTPUT_DIR/enhanced_test \
    --num_balls 2 \
    --ball_type basketball \
    --frames 10 \
    --seed 42

echo "==========================================="
echo "Testing basic depth/sketch script..."

# Test basic depth/sketch script
$BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_with_depth_sketch.py -- \
    --output_dir $TEST_OUTPUT_DIR/basic_test \
    --num_balls 2 \
    --frames 10 \
    --resolution 256

echo "==========================================="
echo "Test complete! Check output in: $TEST_OUTPUT_DIR"
echo "You should see:"
echo "  - angle_* directories (force-prompting style)"
echo "  - enhanced_test/ directory (enhanced style)"
echo "  - basic_test/ directory (basic style)"
echo ""
echo "Full paths:"
echo "  - $(pwd)/$TEST_OUTPUT_DIR/angle_*"
echo "  - $(pwd)/$TEST_OUTPUT_DIR/enhanced_test/"
echo "  - $(pwd)/$TEST_OUTPUT_DIR/basic_test/" 