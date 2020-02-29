#!/usr/bin/env bash

export CLIENT_ID=839316296692-8dp4jgea3ipsd3k9583msttnbqvt5beg.apps.googleusercontent.com
export CLIENT_SECRET=nXYN1Y8AQwHi8X0KwxEGj74K

# Obtained from https://github.com/labbots/google-drive-upload/blob/c94572f575f565d986c29ec3118c1677808b35a7/upload.sh#L100L105
function jsonValue() {
KEY=$1
num=$2
awk -F"[,:}][^://]" '{for(i=1;i<=NF;i++){if($i~/\042'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p | sed -e 's/[}]*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/[,]*$//' 
}

# Creates a new access/refresh token pair. Needs a fresh APP_CODE (check README to see how to get that) passed as param
function createNewToken() {
    if [ "$1" == "" ]; then
        echo "The refresh token is either non-existent or expired. You need to get a new refresh token."
        echo "Please visit the following URL using your browser and give this app the right access:"
        echo ""
        echo "https://accounts.google.com/o/oauth2/auth?scope=https://www.googleapis.com/auth/drive&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&client_id=$CLIENT_ID"
        echo ""
        echo "After giving the access, the above website will return a code to you."
        echo "Call \"./backup.sh createNewToken [code given to you]\" before starting to use backup.sh normally."
    else
        JSON=$(curl -H "Content-Type: application/x-www-form-urlencoded" -d "code=$1&client_id=$CLIENT_ID&client_secret=$CLIENT_SECRET&redirect_uri=urn:ietf:wg:oauth:2.0:oob&grant_type=authorization_code" https://accounts.google.com/o/oauth2/token)
        REFRESH_TOKEN=$(echo $JSON | jsonValue refresh_token)
        echo $REFRESH_TOKEN > refresh_token.config
    fi
}

# Fetches refresh token from configuration
function getREFRESH_TOKEN() {
    export REFRESH_TOKEN=$(cat refresh_token.config 2> /dev/null)
    if [ "$REFRESH_TOKEN" == "" ]; then
        createNewToken
        exit
    fi
}

# Gets a new ACCESS_TOKEN
function getAccessToken() {
    JSON=$(curl -X POST "https://www.googleapis.com/oauth2/v4/token" \
    -d client_id=$CLIENT_ID \
    -d client_secret=$CLIENT_SECRET \
    -d refresh_token=$REFRESH_TOKEN \
    -d grant_type=refresh_token 2> /dev/null)
    export ACCESS_TOKEN=$(echo $JSON | jsonValue access_token)
}

# Takes name of zip file as param
function uploadZip() {
    getAccessToken # get the access token since its needed in the below function
    JSON=$(curl -X POST -L \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -F "metadata={name : 'backup.zip'};type=application/json;charset=UTF-8" \
    -F "file=@$1.zip;type=application/zip" \
    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart")
    export FILE_ID=$(echo $JSON | jsonValue id)
    echo $FILE_ID > file_id.config
}

# Deletes the file from google drive
# Takes the File ID as param
function deleteFile() {
    curl -X DELETE -L -H "Authorization: Bearer  $ACCESS_TOKEN" "https://www.googleapis.com/drive/v3/files/$1 2> /dev/null"
}

if [ "$1" == "createNewToken" ]; then
    createNewToken $2
    exit
fi

if [ "$1" == "" ]; then
    echo "Please pass the absolute directory path for the backup directory as an argument."
    exit
fi
if [ ! -d "$1" ]; then
    echo "$1 does not exist"
    exit
fi

cd $(dirname ${BASH_SOURCE[0]}) # Go to dir of file

echo "Zipping..."
cd $1 && zip -P mypassword -r backup.zip * > /dev/null && cd - > /dev/null
mv $1/backup.zip ./
if [ ! $? -eq 0 ]; then # Make sure zip/mv happened successfully
    echo "Mission failed..."
    echo "Please check the source code for details :)"
    exit
fi
echo "Getting refresh token..."
getREFRESH_TOKEN
echo "Getting access token..."
getAccessToken
FILE_ID=$(cat file_id.config 2> /dev/null)
if [[ $FILE_ID != "" ]]; then
    echo "Deleting older backup..."
    deleteFile $FILE_ID
fi
echo "Uploading new backup..."
uploadZip backup
echo "Done :)"