#!/bin/sh
#
# This shell script creates a shell file with lines of the form
# nvram set x="y"
# for every nvram variable found from
# nvram show
#
DATE=`date +%m%d%Y`
MAC=`nvram get lan_hwaddr | tr -d ":"`
FILE=${MAC}.${DATE}
CUR_DIR=`dirname $0`
FOLDER=/mmc/jffs
TO_ALL=${FOLDER}/${MAC}.${DATE}.all.sh
TO_INCLUDE=${FOLDER}/${MAC}.${DATE}.essential.sh
TO_EXCLUDE=${FOLDER}/${MAC}.${DATE}.dangerous.sh
TO_PREFERRED=${FOLDER}/${MAC}.${DATE}.preferred.sh
#FTPS=ftp://192.168.10.210/backups
#vUSERPASS=user:pass

nvram show 2>/dev/null | egrep '^[a-zA-Z].*=' | awk -F= '{print $1}' | grep -v "[ /+<>,:;]" | sort -u >/mmc/jffs/all_vars

#
echo -e "#!/bin/sh\n#\necho \"Write variables\"\n" | tee -i ${TO_EXCLUDE} | tee -i ${TO_ALL} > ${TO_INCLUDE}

cat /mmc/jffs/all_vars | while read var
do
if echo ${var} | grep -q -f "${CUR_DIR}/vars_to_skip" ; then
  bfile=$TO_EXCLUDE
 else
 if echo ${var} | grep -q -f "${CUR_DIR}/vars_preferred" ; then
  bfile=$TO_PREFERRED
 else
  bfile=$TO_INCLUDE
 fi
 fi

# get the data out of the variable
data=`nvram get ${var}`
if [ "${data}" == "" ] ; then
  echo -e "nvram set ${var}=" | tee -ia ${TO_ALL} >> ${bfile}
 else
  # write the var to the file and use \ for special chars: (\$`")
  echo -en "nvram set ${var}=\"" | tee -ia ${TO_ALL} >> ${bfile}
  echo -n "${data}" | sed 's/\\/\\\\/g' | sed 's/`/\\`/g' | sed 's/\$/\\\$/g' | sed 's/\"/\\"/g' | tee -ia ${TO_ALL} >>${bfile}
  echo -e "\"" | tee -ia ${TO_ALL} >> ${bfile}
 fi

done

rm /mnt/all_vars

echo -e "\n# Commit variables\necho \"Save variables to nvram\"\nnvram commit" | tee -ia ${TO_ALL} | tee -ia ${TO_EXCLUDE} >> ${TO_INCLUDE}
chmod +x ${TO_ALL}
chmod +x ${TO_INCLUDE}
chmod +x ${TO_EXCLUDE}
chmod +x ${TO_PREFERRED}
