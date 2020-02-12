#!/bin/bash
#
# SCRIPT: autoclean.sh
# AUTHOR: Ketan Pitroda
# DATE:   06/29/2015
# REV:    1.1.A (Valid are A, B, D, T and P)
#               (For Alpha, Beta, Dev, Test and Production)
#
# PLATFORM: (AIX, HP-UX, Linux, Solaris)
#
# PURPOSE: autoclean.sh script clears the logs as per autoclean.cfg file. 
#          The script searches autoclean.cfg file in search_base directory.
#          The script deletes log files as per log path (rm_path), search pattern(rm_log) and retention period (rm_retention)
#
#
# REV LIST:
#        DATE: DATE_of_REVISION
#        BY:   AUTHOR_of_MODIFICATION
#        MODIFICATION: Describe what was modified, new features, etc--
#
#
# set -n   # Uncomment to check script syntax, without execution.
#          # NOTE: Do not forget to put the comment back in or
#          #       the shell script will not execute!
# set -x   # Uncomment to debug this shell script
#
##########################################################
#         DEFINE FILES AND VARIABLES HERE
##########################################################
search_base=$HOME
rm_log="Not Defined"
rm_retention=99999
rm_path="Not_Defined"

##########################################################
#              DEFINE FUNCTIONS HERE
##########################################################
get_rm_path()
{
        rm_path=`grep "rm_path" $cfg_file | awk ' BEGIN { FS = "=" };  $1 ~ /rm_path/ { print $2 } '`
        if [ $rm_path"/autoclean.cfg" != $cfg_file ]
        then
                echo "Please define correct rm_path in $cfg_file."
                continue
        fi
}
get_rm_log()
{
        rm_log=`grep "rm_log" $cfg_file | awk ' BEGIN { FS = "=" } $1 ~ /rm_log/ { print $2 } '`
        if [ -z "$rm_log" ]
                then
                        echo "Please define search pattern for logs to be deleted in autoclean.cfg"
                        continue
                fi
        y=0
        for element in $rm_log
        do
                criteria[$y]=$element
                ((y = y + 1))
        done
}
get_rm_retention()
{
        rm_retention=`grep "rm_retention" $cfg_file | awk ' BEGIN { FS = "=" }  $1 ~ /rm_retention/ { print $2 } '`
        if [ -z "$rm_retention" ]
        then
                echo "Please define retention days for files to be deleted in autoclean.cfg"
                continue
        fi
        rm_retention="+"$rm_retention
}
list_clean_config()
{
        echo "-----------------------------------------------------------------------------------------------------------------------------"
        echo "Validated autoclean.cfg configuration"
        echo "autoclean.cfg file : "$cfg_file
        echo "rm_path            : "$rm_path
        echo "rm_log             : "$rm_log
        echo "rm_retention       : "$rm_retention
        echo "Search Pattern     : "${criteria[*]}
}
list_files_for_delete()
{
        echo "List of Files to be Deleted"
        x=0
        while [ $x -lt ${#criteria[@]} ]
        do
        find $rm_path/ -maxdepth 1 -name ${criteria[$x]} -mtime $rm_retention -exec ls -ltr {} \;
        ((x = x + 1))
        done
}
delete_files()
{
        echo "Deleting the files now"
        y=0
        while [ $y -lt ${#criteria[@]} ]
        do
                for delete_file_name in `find $rm_path/ -maxdepth 1 -name ${criteria[$y]} -mtime $rm_retention -exec ls {} \;`
                do
                        echo "rm "$delete_file_name >> autoclean_delete.log
                        rm $delete_file_name    >> autoclean_delete.log
                done
        ((y = y + 1))
        done
}
##########################################################
#               BEGINNING OF MAIN
##########################################################
date >> autoclean_delete.log
echo "------------------------------------------------------------------------------------------------------" >> autoclean_delete.log
for cfg_file in `find $search_base -name autoclean.cfg -print`
do
        get_rm_path
        get_rm_log
        get_rm_retention
        list_clean_config
        list_files_for_delete
        delete_files
done
