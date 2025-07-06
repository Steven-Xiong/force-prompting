#!/bin/bash

# Quick test to verify paths are correctly set
echo "Quick path verification test"
echo "============================="

# Show current working directory
echo "Current working directory: $(pwd)"

# Check if we're in force-prompting directory
if [[ $(basename $(pwd)) == "force-prompting" ]]; then
    echo "✓ Correct working directory: force-prompting"
else
    echo "✗ Wrong working directory. Please run from force-prompting directory:"
    echo "  cd force-prompting"
    exit 1
fi

# Check if Python scripts exist
echo ""
echo "Checking Python scripts:"
for script in "rolling_balls_render_with_depth_sketch.py" "rolling_balls_render_enhanced.py" "rolling_balls_render_force_prompting_style.py"; do
    if [[ -f "scripts/build_synthetic_datasets/poke_model_rolling_balls/$script" ]]; then
        echo "✓ $script exists"
    else
        echo "✗ $script missing"
    fi
done

# Check if Blender path is accessible
echo ""
echo "Checking Blender path:"
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"
if [[ -f "$BLENDER_PATH" ]]; then
    echo "✓ Blender found at: $BLENDER_PATH"
else
    echo "✗ Blender not found at: $BLENDER_PATH"
    echo "  Please verify GPT4Motion installation"
fi

# Check if GPT4Motion Python path exists
echo ""
echo "Checking GPT4Motion Python path:"
GPT4MOTION_PATH="GPT4Motion/PhysicsGeneration"
if [[ -d "$GPT4MOTION_PATH" ]]; then
    echo "✓ GPT4Motion path found: $GPT4MOTION_PATH"
else
    echo "✗ GPT4Motion path not found: $GPT4MOTION_PATH"
fi

# Check if output directories can be created
echo ""
echo "Checking output directory creation:"
TEST_DIR="scratch/rolling_balls/path_test"
mkdir -p "$TEST_DIR"
if [[ -d "$TEST_DIR" ]]; then
    echo "✓ Can create output directories: $TEST_DIR"
    rmdir "$TEST_DIR"
    rmdir "scratch/rolling_balls" 2>/dev/null || true
    rmdir "scratch" 2>/dev/null || true
else
    echo "✗ Cannot create output directories"
fi

echo ""
echo "Path verification complete!"
echo "If all checks pass, you can run the main scripts:"
echo "  ./data_gen_force_prompting_style.sh"
echo "  ./data_gen_enhanced.sh"
echo "  ./data_gen_with_depth_sketch.sh" 