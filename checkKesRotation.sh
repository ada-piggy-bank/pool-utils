#!/bin/bash
CERTIFICATE_FILE="../node.cert"
KES_FILE="../kes.skey"
EXISTING_ENTRIES="rotation-history.json"
SUCCESS="TRUE"

function updateJson() {
 echo "updating json"
 jq ".[.| length] |= . + {\"iteration\": \"$rotationCount\", \"certHash\": \"$certSum\", \"kesHash\": \"$kesSum\"}" "$EXISTING_ENTRIES" | jq . > tmp.json
 mv tmp.json $EXISTING_ENTRIES

}

function addNewEntry() {
  echo "New cert identified, checking kes has been rotated correctly."
  certSum=$(md5sum $CERTIFICATE_FILE | awk '{ print $1 }' )
  kesSum=$(md5sum $KES_FILE | awk '{ print $1 }')
  checkEntryExists
  if [ "$SUCCESS" = "TRUE" ] 
  then
    updateJson
  fi
}

function checkEntryExists() {
 kesEntry=$(jq ".[] | select(.kesHash==\"$kesSum\")" "$EXISTING_ENTRIES")
 certEntry=$(jq ".[] | select(.certHash==\"$certSum\")" "$EXISTING_ENTRIES")
 if [ "$kesEntry" != "" ] 
 then
  echo "Warning!!! $KES_FILE file with md5sum $kesSum has already been used in a previous rotation."
  SUCCESS="FALSE"
 fi

 if [ "$certEntry" != "" ]
 then
  echo "Warning!!! $CERTIFICATE_FILE file with md5sum $certSum has already been used in a previous rotation."
  SUCCESS="FALSE"
 fi
 
}

function validateFiles() {
  certSum=$(md5sum $CERTIFICATE_FILE | awk '{ print $1 }' )
  kesSum=$(md5sum $KES_FILE | awk '{ print $1 }')

  maxRotation=$(jq '[.[].iteration] | max' "$EXISTING_ENTRIES" )
  latestEntry=$(jq ".[] | select(.iteration==$maxRotation)" "$EXISTING_ENTRIES")

  if [ $(jq -r '.kesHash' <<< "$latestEntry") != "$kesSum" ]
  then
     echo "Warning!!! $KES_FILE has changed but counter in $CERTIFICATE_FILE has not been incremented. Check that you have regenerated your $CERTIFICATE_FILE correctly."
     SUCCESS="FALSE"
  fi

  if [ $(jq -r '.certHash' <<< "$latestEntry") != "$certSum" ]
  then
     echo "Warning!!! $CERTIFICATE_FILE has changed but counter has not been incremented. Check that you have regenerated your $CERTIFICATE_FILE correctly."
     SUCCESS="FALSE"
  fi
 
}

function checkRotation() {
  #get kes rotation increment from node certificate
  rotation=$(cardano-cli text-view decode-cbor --in-file $CERTIFICATE_FILE | grep int | head -1)
  IFS="#" read -a array <<< $rotation
  trimmedValue="$(echo -e "${array[0]}" | tr -d '[:space:]')"
  baseTenValue=$((10#${trimmedValue})) 
  rotationCount=$((baseTenValue+0))

  #check last valid rotation increment
  maxRotation=$( jq -r '[.[].iteration] | max' $EXISTING_ENTRIES ) 

  if (("$maxRotation" < "$rotationCount")) 
  then
     #new certificate with valid rotation increment identified
     addNewEntry
  elif (("$maxRotation" == "$rotationCount")) 
  then
   #validate existing certificate and kes
     validateFiles
  else
     echo "Warning!!! $CERTIFICATE_FILE contains a lower iteration value than previously recorded. Check that you have regenerated your $CERTIFICATE_FILE correctly."
     SUCCESS="FALSE"
  fi

  if [ "$SUCCESS" = "TRUE" ] 
  then
    echo "$CERTIFICATE_FILE and $KES_FILE appear to be valid for this rotation."
  fi

}

checkRotation
