#!/usr/bin/bash

while [[ "$#" != "" ]]; do
    case $1 in
    --home_dir) HOME="$2"; shift ;;
	--image) image="$2"; shift ;;
    esac
    shift
done

IMAGE_NAME=${image#*:}
GIT_REPO=${HOME}/slurm_testing
DATA=${HOME}/DATA/reg_5mm_pack
OUT=${HOME}/${IMAGE_NAME}
IMAGE=${IMAGE_NAME}.sif
PIPELINE_CONFIGS=${DATA}/configs
PRECONFIGS="default"
DATA_SOURCE="Site-CBIC Site-SI HNU_1"


echo "Running lite regression test ..."
for pipeline in ${PRECONFIGS}; do
    for data in ${DATA_SOURCE}; do
        if [ ${data} == 'HNU_1' ]; then
            subject="sub-0025428"
            datapath=${DATA}/data/HNU_1
        elif [ ${data} == 'Site-CBIC' ]; then
            subject="sub-NDARAA947ZG5"
            datapath=${DATA}/data/Site-CBIC
        elif [ ${data} == 'Site-SI' ]; then
            subject="sub-NDARAD481FXF"
            datapath=${DATA}/data/Site-SI
        fi

        OUTPUT=${OUT}/${pipeline}/${data}
        [ ! -d  ${OUTPUT} ] && mkdir -p ${OUTPUT}

        cat << TMP > reglite_${IMAGE_NAME}.sh
#!/usr/bin/bash
#SBATCH -N 1
#SBATCH -p RM-shared
#SBATCH -t 10:00:00
#SBATCH --ntasks-per-node=11

singularity run --rm \
    -B ${REG_DATA}:/reg-data \
    -B ${datapath}:/data \
    -B ${OUTPUT}:/outputs \
    -B ${PIPELINE_CONFIGS}:/pipeline_configs \
    ${IMAGE} /data /outputs participant \
    --save_working_dir --skip_bids_validator \
    --pipeline_file /pipeline_configs/${pipeline}_lite.yml \
    --participant_label ${subject} \
    --n_cpus 10 --mem_gb 40
TMP
        chmod +x reglite_${IMAGE_NAME}.sh
        sbatch reglite_${IMAGE_NAME}.sh
        echo "Finished reglite_${IMAGE_NAME}.sh.sh
    done
done