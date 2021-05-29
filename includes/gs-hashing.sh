# GRAVITY SYNC BY VMSTAN #####################
# gs-hasing.sh ###############################

# For documentation or downloading updates visit https://github.com/vmstan/gravity-sync
# This code is called from the main gravity-sync.sh file and should not execute directly!

declare -gA PRIMARY_LOG_ROW
declare -gA SECONDARY_LOG_ROW
PRIMARY_LOG_ROW["DB"]=1
SECONDARY_LOG_ROW["DB"]=2
PRIMARY_LOG_ROW["CL"]=3
SECONDARY_LOG_ROW["CL"]=4
PRIMARY_LOG_ROW["CNAME"]=5
SECONDARY_LOG_ROW["CNAME"]=6
PRIMARY_LOG_ROW["GSLAN"]=7
SECONDARY_LOG_ROW["GSLAN"]=8

## Validate Sync Required
function md5_compare {
    HASHMARK='0'
    
    MESSAGE="${UI_HASHING_HASHING} ${UI_GRAVITY_NAME}"
    echo_stat
    primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//')
    error_validate
    
    MESSAGE="${UI_HASHING_COMPARING} ${UI_GRAVITY_NAME}"
    echo_stat
    secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
    error_validate
    
    if [ "$primaryDBMD5" == "${LAST_PRIMARY_MD5["DB"]}" ] && [ "$secondDBMD5" == "${LAST_SECONDARY_MD5["DB"]}" ]
    then
        HASHMARK=$((HASHMARK+0))
    else
        MESSAGE="${UI_HASHING_DIFFERNCE} ${UI_GRAVITY_NAME}"
        echo_warn
        HASHMARK=$((HASHMARK+1))
    fi
    
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${UI_HASHING_HASHING} ${UI_CUSTOM_NAME}"
                echo_stat
                
                primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'")
                error_validate
                
                MESSAGE="${UI_HASHING_COMPARING} ${UI_CUSTOM_NAME}"
                echo_stat
                secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
                error_validate
                
                if [ "$primaryCLMD5" == "${LAST_PRIMARY_MD5["CL"]}" ] && [ "$secondCLMD5" == "${LAST_SECONDARY_MD5["CL"]}" ]
                then
                    HASHMARK=$((HASHMARK+0))
                else
                    MESSAGE="${UI_HASHING_DIFFERNCE} ${UI_CUSTOM_NAME}"
                    echo_warn
                    HASHMARK=$((HASHMARK+1))
                fi
            else
                MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                echo_info
            fi
        else
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_DETECTED} ${UI_HASHING_PRIMARY}"
                HASHMARK=$((HASHMARK+1))
                echo_info
            fi
            MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_SECONDARY}"
            echo_info
        fi
    fi
    
    if [ "${SKIP_CUSTOM}" != '1' ]
    then
        declare -gA REMOTE_DNS
        declare -gA PRIMARY_MD5
        declare -gA SECONDARY_MD5
        for ENTRY_NAME in "${!DNSMAQ_FILES[@]}"
        do
            # UI_NAME="UI_${ENTRY_NAME}_NAME"

            if [ -f ${DNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]} ]
            then
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]}
                then
                    REMOTE_DNS+=( ["${ENTRY_NAME}"]="1" )
                    MESSAGE="${UI_HASHING_HASHING} ${UI_NAME[$ENTRY_NAME]}"
                    echo_stat

                    PRIMARY_MD5[$ENTRY_NAME]=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]} | sed 's/\s.*$//'")
                    error_validate

                    MESSAGE="${UI_HASHING_COMPARING} ${UI_NAME[$ENTRY_NAME]}"
                    echo_stat
                    SECONDARY_MD5[$ENTRY_NAME]=$(md5sum ${DNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]} | sed 's/\s.*$//')
                    error_validate

                    if [ "${PRIMARY_MD5[$ENTRY_NAME]}" == "${LAST_PRIMARY_MD5[$ENTRY_NAME]}" ] && [ "${SECONDARY_MD5[$ENTRY_NAME]}" == "${LAST_SECONDARY_MD5[$ENTRY_NAME]}" ]
                    then
                        HASHMARK=$((HASHMARK+0))
                    else
                        MESSAGE="${UI_HASHING_DIFFERNCE} ${UI_NAME[$ENTRY_NAME]}"
                        echo_warn
                        HASHMARK=$((HASHMARK+1))
                    fi
                else
                    MESSAGE="${UI_NAME[$ENTRY_NAME]} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                    echo_info
                fi
            else
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]}
                then
                    REMOTE_DNS+=( ["${ENTRY_NAME}"]="1" )
                    MESSAGE="${UI_NAME[$ENTRY_NAME]} ${UI_HASHING_DETECTED} ${UI_HASHING_PRIMARY}"
                    HASHMARK=$((HASHMARK+1))
                    echo_info
                fi

                MESSAGE="${UI_NAME[$ENTRY_NAME]} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_SECONDARY}"
                echo_info
            fi
        done
    fi
    
    if [ "$HASHMARK" != "0" ]
    then
        MESSAGE="${UI_HASHING_REQUIRED}"
        echo_warn
        HASHMARK=$((HASHMARK+0))
    else
        MESSAGE="${UI_HASHING_NOREP}"
        echo_info
        backup_cleanup
        exit_nochange
    fi
}

function get_last_primary_md5 {
    echo $(sed "${PRIMARY_LOG_ROW[$1]}q;d" ${LOG_PATH}/${HISTORY_MD5})
}

function get_last_secondary_md5 {
    echo $(sed "${SECONDARY_LOG_ROW[$1]}q;d" ${LOG_PATH}/${HISTORY_MD5})
}

function previous_md5 {
    declare -gA LAST_PRIMARY_MD5
    declare -gA LAST_SECONDARY_MD5
    if [ -f "${LOG_PATH}/${HISTORY_MD5}" ]
    then
        LAST_PRIMARY_MD5["DB"]=$(get_last_primary_md5 "DB")
        LAST_PRIMARY_MD5["CL"]=$(get_last_primary_md5 "CL")
        LAST_PRIMARY_MD5["CNAME"]=$(get_last_primary_md5 "CNAME")
        LAST_PRIMARY_MD5["GSLAN"]=$(get_last_primary_md5 "GSLAN")

        LAST_SECONDARY_MD5["DB"]=$(get_last_secondary_md5 "DB")
        LAST_SECONDARY_MD5["CL"]=$(get_last_secondary_md5 "CL")
        LAST_SECONDARY_MD5["CNAME"]=$(get_last_secondary_md5 "CNAME")
        LAST_SECONDARY_MD5["GSLAN"]=$(get_last_secondary_md5 "GSLAN")
    else
        LAST_PRIMARY_MD5["DB"]="0"
        LAST_PRIMARY_MD5["CL"]="0"
        LAST_PRIMARY_MD5["CNAME"]="0"
        LAST_PRIMARY_MD5["GSLAN"]="0"

        LAST_SECONDARY_MD5["DB"]="0"
        LAST_SECONDARY_MD5["CL"]="0"
        LAST_SECONDARY_MD5["CNAME"]="0"
        LAST_SECONDARY_MD5["GSLAN"]="0"
    fi
}

function md5_recheck {
    MESSAGE="${UI_HASHING_DIAGNOSTICS}"
    echo_info
    
    HASHMARK='0'
    
    MESSAGE="${UI_HASHING_REHASHING} ${UI_GRAVITY_NAME}"
    echo_stat
    primaryDBMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${GRAVITY_FI}" | sed 's/\s.*$//')
    silent_error_validate
    
    MESSAGE="${UI_HASHING_RECOMPARING} ${UI_GRAVITY_NAME}"
    echo_stat
    secondDBMD5=$(md5sum ${PIHOLE_DIR}/${GRAVITY_FI} | sed 's/\s.*$//')
    silent_error_validate
    
    if [ "$SKIP_CUSTOM" != '1' ]
    then
        if [ -f ${PIHOLE_DIR}/${CUSTOM_DNS} ]
        then
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${UI_HASHING_REHASHING} ${UI_CUSTOM_NAME}"
                echo_stat
                
                primaryCLMD5=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//'")
                silent_error_validate
                
                MESSAGE="${UI_HASHING_RECOMPARING} ${UI_CUSTOM_NAME}"
                echo_stat
                secondCLMD5=$(md5sum ${PIHOLE_DIR}/${CUSTOM_DNS} | sed 's/\s.*$//')
                silent_error_validate
            else
                MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                echo_info
            fi
        else
            if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RIHOLE_DIR}/${CUSTOM_DNS}
            then
                REMOTE_CUSTOM_DNS="1"
                MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_DETECTED} ${UI_HASHING_PRIMARY}"
                echo_info
            fi
            MESSAGE="${UI_CUSTOM_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_SECONDARY}"
            echo_info
        fi
    fi
    
    if [ "${SKIP_CUSTOM}" != '1' ]
    then
        declare -gA REMOTE_DNS
        declare -gA PRIMARY_MD5
        declare -gA SECONDARY_MD5
        for ENTRY_NAME in "${!DNSMAQ_FILES[@]}"
        do
            # echo $ENTRY_NAME --- ${DNSMAQ_FILES[$ENTRY_NAME]};
            UI_NAME="UI_${ENTRY_NAME}_NAME"

            if [ -f ${DNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]} ]
            then
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]}
                then
                    REMOTE_DNS+=( ["${ENTRY_NAME}"]="1" )
                    MESSAGE="${UI_HASHING_REHASHING} ${!UI_NAME}"
                    echo_stat
                    
                    PRIMARY_MD5[$ENTRY_NAME]=$(${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} "md5sum ${RNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]} | sed 's/\s.*$//'")
                    silent_error_validate
                    
                    MESSAGE="${UI_HASHING_RECOMPARING} ${!UI_NAME}"
                    echo_stat
                    SECONDARY_MD5[$ENTRY_NAME]=$(md5sum ${DNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]} | sed 's/\s.*$//')
                    silent_error_validate
                else
                    MESSAGE="${!UI_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                    echo_info
                fi
            else
                if ${SSHPASSWORD} ${SSH_CMD} -p ${SSH_PORT} -i "$HOME/${SSH_PKIF}" ${REMOTE_USER}@${REMOTE_HOST} test -e ${RNSMAQ_DIR}/${DNSMAQ_FILES[$ENTRY_NAME]}
                then
                    REMOTE_DNS+=( ["${ENTRY_NAME}"]="1" )
                    MESSAGE="${!UI_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_PRIMARY}"
                    echo_info
                fi
                
                MESSAGE="${!UI_NAME} ${UI_HASHING_NOTDETECTED} ${UI_HASHING_SECONDARY}"
                echo_info
            fi
        done
    fi
}