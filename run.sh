#!/bin/bash
#SBATCH --job-name=blender
#SBATCH --output=./bjob_logs/ball_7.5.log
#SBATCH --error=./bjob_logs/ball_7.5.log
#SBATCH --time=7-00:00:00
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=200G
#SBATCH --account bemk-tgirails
#SBATCH --gpu-bind=closest


source activate diffusion-pipe
cd /u/zhexiao/video_gen/force-prompting
bash data_gen_force_prompting_style.sh

