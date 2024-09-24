node="<YOUR-NODE-NAME>"
user="YOUR-USER"
home_directory="/home/$user"
minsize=500

#Retrieve network IP addresses

curl http://127.0.0.1:9934 -H "Content-Type:application/json;charset=utf-8" -d   '{
    "jsonrpc":"2.0",
        "id":1,
        "method":"system_unstable_networkState",
        "params": []
}'  | jq '.result.connectedPeers' >> $home_directory/system_unstable_networkState.txt

echo "Retrieved IP and Validator Addresses"

#Extract relevant data
grep -Eo 'send_back_addr|[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|12D.{0,49}' $home_directory/system_unstable_networkState.txt | grep -B 2 -A 1 'send' |grep -wv -e '135.148.42.62\|send_back_addr\|--' >> $home_directory/peers_with_ips.txt

echo "Cleaned networkState data"

#Retrieve peers and roles
curl http://127.0.0.1:9934 -H "Content-Type:application/json;charset=utf-8" -d   '{
    "jsonrpc":"2.0",
        "id":1,
        "method":"system_peers",
        "params": []
 }' | jq '.result' >> $home_directory/peers.txt

echo "Retrieved peers and roles"

grep -Eo 'AUTHORITY|12D.{0,49}' $home_directory/peers.txt | grep -B 1 'AUTHORITY' | grep -wv -e '--' >> $home_directory/peers_role.txt

echo "Clened peers data"

grep -Ff $home_directory/peers_role.txt peers_with_ips.txt -A 2 | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' >> $home_directory/matched_ips.txt

echo "Joined data for acvtive validators"

cat $home_directory/matched_ips.txt | ipinfo -c >> $home_directory/$node-geolocations.csv

echo "Created target geolocations file"
echo "uploading to GCP"


filesize=$(stat -c%s $node-geolocations.csv)

if (( filesize > minsize)); then
gsutil cp $home_directory/$node-geolocations.csv gs://ip-geolocation-data-full/polkadot
echo "Uploaded geo-file to GCP cloud storage"
else
echo "filesize too small to upload"
fi

echo "Uploaded geo-file to GCP cloud storage"

rm $home_directory/system_unstable_networkState.txt
rm $home_directory/peers_with_ips.txt
rm $home_directory/peers_role.txt
rm $home_directory/peers.txt
rm $home_directory/matched_ips.txt
rm $home_directory/$node-geolocations.csv

echo "Deleted files"
echo "END"
