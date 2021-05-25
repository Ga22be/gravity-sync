# GRAVITY SYNC BY VMSTAN #####################
# gs-compare.sh ##############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

## Compare Task
function task_compare {
    TASKTYPE='COMPARE'
    MESSAGE="${MESSAGE}: ${TASKTYPE}"
    echo_good
    
    show_target
    validate_gs_folders
    validate_ph_folders
    validate_dns_folders
    validate_os_sshpass
    
    previous_md5
    md5_compare
    for K in "${!REMOTE_DNS[@]}"; do echo $K --- ${REMOTE_DNS[$K]}; done
    echo "${REMOTE_DNS[GSLAN]}"
    backup_cleanup


    exit_withchange
}
