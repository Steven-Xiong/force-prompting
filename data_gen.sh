sh scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_render.sh

RENDER_DIR=scratch/rolling_balls/pngs
python scripts/build_synthetic_datasets/poke_model_rolling_balls/rolling_balls_png_to_mp4.py $RENDER_DIR


# this dir is already filled with mp4s
DIR_BALLS="scratch/rolling_balls/videos"
# this dir is already filled with mp4s and jsons
DIR_PLANTS="/oscar/data/superlab/users/nates_stuff/cogvideox-controlnet/data/2025-04-07-point-force-unified-model/videos-05-11-ablation-no-bowling-balls-temp-justflowers"
# we eventually want to create this
DIR_COMBINED="datasets/point-force/train/point_force_23000_07-01"


# make balls csv
python scripts/build_synthetic_datasets/poke_model_rolling_balls/generate_csv_for_plants_and_balls_from_dir.py \
    --file_dir ${DIR_BALLS} \
    --file_type video \
    --output_path ${DIR_COMBINED}_balls.csv \
    --backgrounds_json_path_soccer scripts/build_synthetic_datasets/poke_model_rolling_balls/backgrounds_soccer.json \
    --backgrounds_json_path_bowling scripts/build_synthetic_datasets/poke_model_rolling_balls/backgrounds_bowling.json \
    --take_subset_size 100
    # 12000

# make plants csv
# python scripts/build_synthetic_datasets/poke_model_rolling_balls/generate_csv_for_plants_and_balls_from_dir.py \
#     --file_dir ${DIR_PLANTS} \
#     --file_type video \
#     --output_path ${DIR_COMBINED}_plants.csv \
#     --take_subset_size 11000