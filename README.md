# Auto Backup

Simple bash script to encrypt and zip a directory and upload it to Google Drive. The idea behind this is to backup some directory where all personal info are stored. Hence, every time the script is called, it deletes the previously uploaded file and uploads a new one. This project is similar to [that one](https://github.com/labbots/google-drive-upload), however I add the delete functionality.

## How to Use

Inspired by [this Stack Overflow answer](https://stackoverflow.com/questions/28593022/list-google-drive-files-with-curl) and [Google Drive Upload repo](https://github.com/labbots/google-drive-upload).

1. Go to `console.drive.google.com` > APIs & Services > OAuth consent screen and set that up.
2. Go to Credentials (in APIs & Services) and make a new OAuth client ID. Select "other" in the application type.
3. Allow your new client to get full permission to read/write on google drive. To do so, visit the following URL in the browser: `https://accounts.google.com/o/oauth2/auth?scope=https://www.googleapis.com/auth/drive&redirect_uri=urn:ietf:wg:oauth:2.0:oob&response_type=code&client_id=$CLIENT_ID`
4. Call `./backup.sh createNewToken [code obtained from the website]`
5. Edit the `password` variable to your password in the batch file.
6. Call `./backup.sh [backup_dir_path]`
