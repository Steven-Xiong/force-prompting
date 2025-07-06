#!/bin/bash

# Test script for depth and sketch generation
echo "Testing rolling balls rendering with depth and sketch..."
echo "This will generate ONE test scene to verify the setup"

# Change to the video_gen directory (parent of force-prompting)
cd "$(dirname "$0")/.."
echo "Working directory: $(pwd)"

# Use GPT4Motion's Blender
BLENDER_PATH="/u/zhexiao/video_gen/GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"

# Test output directory - INSIDE force-prompting project
TEST_OUTPUT_DIR="force-prompting/scratch/rolling_balls/test_output"
mkdir -p $TEST_OUTPUT_DIR

echo "==========================================="
echo "Running test render..."

# Test with enhanced script
$BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_enhanced.py -- \
    --output_dir $TEST_OUTPUT_DIR/test_scene \
    --num_balls 3 \
    --ball_type basketball \
    --frames 10 \
    --seed 42

echo "==========================================="
echo "Checking output files..."

# Check if files were created
if [ -d "$TEST_OUTPUT_DIR/test_scene/freestyle" ]; then
    echo "✓ RGB frames directory found"
    RGB_COUNT=$(ls -1 $TEST_OUTPUT_DIR/test_scene/freestyle/*.png 2>/dev/null | wc -l)
    echo "  Found $RGB_COUNT RGB frames"
else
    echo "✗ RGB frames directory not found"
fi

if [ -d "$TEST_OUTPUT_DIR/test_scene/depth" ]; then
    echo "✓ Depth maps directory found"
    DEPTH_COUNT=$(ls -1 $TEST_OUTPUT_DIR/test_scene/depth/*.png 2>/dev/null | wc -l)
    echo "  Found $DEPTH_COUNT depth maps"
else
    echo "✗ Depth maps directory not found"
fi

if [ -d "$TEST_OUTPUT_DIR/test_scene/mask" ]; then
    echo "✓ Mask directory found"
    MASK_COUNT=$(ls -1 $TEST_OUTPUT_DIR/test_scene/mask/*.png 2>/dev/null | wc -l)
    echo "  Found $MASK_COUNT masks"
else
    echo "✗ Mask directory not found"
fi

echo "==========================================="
echo "Creating test video..."

# Convert to video
python3 << 'EOF'
import cv2
from pathlib import Path

test_dir = Path("force-prompting/scratch/rolling_balls/test_output/test_scene")
if not test_dir.exists():
    print("Test directory not found!")
    exit(1)

# Try to create a test video from RGB frames
rgb_dir = test_dir / "freestyle"
rgb_frames = sorted(rgb_dir.glob("*.png"))

if rgb_frames:
    first_frame = cv2.imread(str(rgb_frames[0]))
    if first_frame is not None:
        height, width = first_frame.shape[:2]
        
        fourcc = cv2.VideoWriter_fourcc(*'mp4v')
        out = cv2.VideoWriter("force-prompting/scratch/rolling_balls/test_output/test_video.mp4", fourcc, 24.0, (width, height))
        
        for frame_path in rgb_frames:
            frame = cv2.imread(str(frame_path))
            if frame is not None:
                out.write(frame)
        
        out.release()
        print("✓ Test video created: force-prompting/scratch/rolling_balls/test_output/test_video.mp4")
    else:
        print("✗ Could not read frames")
else:
    print("✗ No RGB frames found")

# Display summary
print("\nTest Summary:")
print(f"RGB frames: {len(list((test_dir / 'freestyle').glob('*.png')))}")
print(f"Depth maps: {len(list((test_dir / 'depth').glob('*.png')))}")
print(f"Masks: {len(list((test_dir / 'mask').glob('*.png')))}")
EOF

echo "==========================================="
echo "Test complete!"
echo ""
echo "Output location: $TEST_OUTPUT_DIR"
echo ""
echo "To view results:"
echo "  - RGB frames: $TEST_OUTPUT_DIR/test_scene/freestyle/"
echo "  - Depth maps: $TEST_OUTPUT_DIR/test_scene/depth/"
echo "  - Test video: $TEST_OUTPUT_DIR/test_video.mp4"
echo ""
echo "If everything looks good, run the full generation with:"
echo "  ./force-prompting/data_gen_enhanced.sh" 