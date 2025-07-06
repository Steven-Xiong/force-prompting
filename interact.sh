# srun --account=zhexiao --partition=gpu \
#   --nodes=1 --gpus-per-node=1 --tasks=1 \
#   --tasks-per-node=16 --cpus-per-task=1 --mem=20g \
#   --pty bash

srun --partition=gpu --gres=gpu:1 --ntasks=1 \
  --cpus-per-task=16 --mem=40G \
  --account=bemk-tgirails \
  --gpu-bind=closest --pty bash

# 查看job状态
# srun --jobid=31369 --overlap gpustat -cp --watch --interval 2