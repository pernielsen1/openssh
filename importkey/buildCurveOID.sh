#/bin/bash
# build a list of curves + extract their object IDs using dumpecdh.sh
function jsonval2() {
   temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2`
   echo ${temp##*|}
}

function strindex() { 
  x="${1%%$2*}"
  [[ "$x" = "$1" ]] && echo -1 || echo "${#x}"
}
temp=`openssl ecparam -list_curves`
echo "curveName, curveOID">map/curvemap.csv
i=0
while read -r line
do 
 # echo "A line of input: $line"
   # ignore the Oakley curves  
   pos=`strindex "$line" "Oakley"`
   if [[ pos -lt 0 ]]; then
       pos=`strindex "$line" ":"`
       if [[ pos -gt 0 ]]; then
         echo "$pos" "here we are " ":" "$line"                                    3
         curve=${line:0:pos}
         curve=`echo "$curve"|tr -d "[:blank:]"`
         echo ${curve}
         # OK we have a line create a key, dump it, read JSON result and write out the map

         openssl ecparam -name "$curve" -genkey -noout -out curves/"$curve".pem
         openssl ec -in curves/"$curve".pem -outform der -out curves/"$curve".der
         ./dumpecdh.sh curves/"$curve".pem curves/"$curve".json
         json=`cat curves/"$curve".json`
         curveName=`jsonval2 "$json" curve`
         curveOID=`jsonval2 "$json" curveOID`
         echo "curveName:" "$curveName" " curveOID:" "$curveOID"
	 echo "$curveName"",""$curveOID">>map/curvemap.csv 
         ./importkey.sh curves/"$curve".json curves/"$curve".copy.pem
         diff curves/"$curve".copy.pem curves/"$curve".pem
         error=$?
         if [ $error -eq 0 ]; then
   	    echo curves/"$curve".copy.pem " and " curves/"$curve".pem " are the same file"
         else
   	    echo curves/"$curve".copy.pem " and " curves/"$curve".pem " are not identical exiting"
            exit 1
         fi
        ((i=i+1))
     fi
  fi

  if [ $i -gt 250 ]; then
	exit 
  fi
   
done <<<"$temp"
cat map/curvemap.csv
exit 0

