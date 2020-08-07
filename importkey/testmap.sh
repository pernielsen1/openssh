#/bin/bash
declare -A curvemap
infile="map/curvemap.csv"
while IFS=, read -r key val
do
   curvemap["$key"]="$val" 
done < "$infile"
curve="secp112r2"
oid="${curvemap["$curve"]}"
echo "found oid:""$oid"
