file=$1
TMP=/tmp/tmp.$$
UTILS="/var/www/ood/apps/sys/ondemand_fugaku/misc/utils.rb"
echo require \"${UTILS}\" > $TMP
sed -n '/<%-/,/-\%>/p' $file | grep -v \% | grep -v require >> $TMP
grep "<%=" $file | sed 's/<%=//g' | sed 's/%>//g' | grep -v form_attr >> $TMP
echo "puts form_attr()" >> $TMP
ruby $TMP
rm $TMP
