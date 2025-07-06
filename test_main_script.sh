#!/bin/bash

# 简化版本的主脚本 - 用于调试参数生成问题
echo "Testing main script with simplified parameters..."

# 基本设置
BLENDER_PATH="GPT4Motion/PhysicsGeneration/blender-4.4.3-linux-x64/blender"
OUTPUT_BASE_DIR="scratch/rolling_balls/test_main"
mkdir -p $OUTPUT_BASE_DIR

# 简化的参数生成，使用固定值避免bc计算问题
generate_simple_params() {
    local scene_id=$1
    
    # 使用简单的参数，类似测试脚本
    local ball_types=("basketball" "soccer" "tennis" "bowling")
    local ball_type=${ball_types[$((scene_id % 4))]}
    
    # 简单的数值计算，避免bc
    local force_magnitude="25.5"
    local force_angle="15.0"
    local coordx="300"
    local coordy="250"
    local pixangle="18.3"
    local height_offset="0.5"
    local num_balls="3"
    
    echo "$ball_type $force_magnitude $force_angle $coordx $coordy $pixangle $height_offset $num_balls"
}

# 测试3个场景
for i in {1..3}; do
    echo "==========================================="
    echo "Generating test scene $i/3..."
    
    # 生成参数
    params=($(generate_simple_params $i))
    BALL_TYPE=${params[0]}
    FORCE_MAGNITUDE=${params[1]}
    FORCE_ANGLE=${params[2]}
    COORDX=${params[3]}
    COORDY=${params[4]}
    PIXANGLE=${params[5]}
    HEIGHT_OFFSET=${params[6]}
    NUM_BALLS=${params[7]}
    
    echo "Ball type: $BALL_TYPE"
    echo "Force: ${FORCE_MAGNITUDE}N at ${FORCE_ANGLE}°"
    echo "Height offset: ${HEIGHT_OFFSET}m"
    echo "Number of balls: $NUM_BALLS"
    
    # 创建场景名称
    SCENE_NAME="test_${i}_${BALL_TYPE}_angle_${FORCE_ANGLE}_force_${FORCE_MAGNITUDE}"
    
    echo "Scene name: $SCENE_NAME"
    
    # 运行Blender (使用和测试脚本相同的参数)
    echo "Running Blender..."
    $BLENDER_PATH -b -P scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render_force_prompting_style.py -- \
        --output_dir $OUTPUT_BASE_DIR \
        --scene_name $SCENE_NAME \
        --num_balls $NUM_BALLS \
        --ball_type $BALL_TYPE \
        --frames 10 \
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
        
        # 检查输出文件
        SCENE_DIR="$OUTPUT_BASE_DIR/$SCENE_NAME"
        if [[ -d "$SCENE_DIR" ]]; then
            echo "  Output directory created: $SCENE_DIR"
            
            # 检查各个子目录
            RGB_COUNT=$(ls -1 "$SCENE_DIR/pngs"/*.png 2>/dev/null | wc -l)
            DEPTH_COUNT=$(ls -1 "$SCENE_DIR/depth"/*.png 2>/dev/null | wc -l)
            SKETCH_COUNT=$(ls -1 "$SCENE_DIR/sketch"/*.png 2>/dev/null | wc -l)
            
            echo "  RGB frames: $RGB_COUNT"
            echo "  Depth maps: $DEPTH_COUNT"
            echo "  Sketch files: $SKETCH_COUNT"
        else
            echo "  ✗ Output directory not created"
        fi
    else
        echo "✗ Scene $i failed to render!"
    fi
    
    echo ""
done

echo "==========================================="
echo "Test completed! Check results:"
echo "ls -la $OUTPUT_BASE_DIR/" 