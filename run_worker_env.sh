#!/usr/bin/env bash
source /home/cpriesne/miniconda3/etc/profile.d/conda.sh
conda activate rb
cd /mnt/vg01/lv01/home/cpriesne/reprobench/
python $@
