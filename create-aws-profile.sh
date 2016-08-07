#!/bin/bash

# Configurations
JSON_FILE=$HOME/.aws-profile.json

# Locate jq
JQ=`which jq 2>/dev/null`
if [ $? != 0 ]; then
    echo "ERROR: jq command not found"
    exit 1
fi

# Locate dialog
DIALOG=`which dialog 2>/dev/null`
if [ $? != 0 ]; then
    echo "ERROR: dialog command not found"
    exit 1
fi

# Check config file
if [ ! -f $JSON_FILE ]; then
    echo "ERROR: config file $JSON_FILE not found"
    exit 1
fi

# Clean old temp files
rm -f $HOME/.temp_aws_profile_*

function generate_export_file()
{

    # Random File used to return source file
    random_file=$HOME/.temp_aws_profile_`date +%Y%m%d%H%m%S`

    cat << EOF > $random_file
# Amazon Ec2 command lines tools
export AWS_ACCESS_KEY=$2
export AWS_SECRET_KEY=$3
export AWS_CREDENTIAL_FILE=$5

# Used in s4cmd
export S3_ACCESS_KEY=$2
export S3_SECRET_KEY=$3

# Used in aws cli
export AWS_ACCESS_KEY_ID=$2
export AWS_SECRET_ACCESS_KEY=$3
export AWS_SSH_KEY_ID=$6
export AWS_DEFAULT_REGION=$4
export EC2_REGION=$4
export AWS_REGION=$4
export AZ=${4}a

export AWS_PROFILE_IN_USE=$1
EOF

    >&2 echo $random_file

}

function enable_profile()
{
    _1=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .name'`
    _2=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .key'`
    _3=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .secret'`
    _4=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .region'`
    _5=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .credential_file'`
    _6=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .ssh_default_key'`

    if [ -z $_1 ]; then
        echo "Profile $1 not found in config file $JSON_FILE"
        exit 1
    fi

    generate_export_file $_1 $_2 $_3 $_4 $_5 $_6
}

function write_credentials()
{
    _1=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .name'`
    _2=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .key'`
    _3=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .secret'`
    _4=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .region'`
    _5=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .credential_file'`
    _6=`cat $JSON_FILE | jq -r --arg name "$1" '.profiles[] | select(.name == $name) | .ssh_default_key'`

cat << EOF > $_5
[default]
aws_access_key_id=$_2
aws_secret_access_key=$_3
region=$_4
EOF

}

# Variables
profiles=`cat $JSON_FILE | jq -r '.profiles[] | .name'`
default=`cat $JSON_FILE | jq -r .default`
in_use=$AWS_PROFILE_IN_USE

# Execute actions
if [ ! -z $1 ]; then

    if [ $1 == "show" ]; then
        echo $in_use
    elif [ $1 == "default" ]; then
        enable_profile $default
    else
        enable_profile $1
    fi

else
    option_string=""
    for p in $profiles; do
        k=`cat $JSON_FILE | jq -r --arg name "$p" '.profiles[] | select(.name == $name) | .key'`
        option_string="${option_string} ${p} ${k} "
    done
    dialog --menu "Select one profile: ( Loaded from: $JSON_FILE )" 20 80 20 ${option_string} 2> /tmp/aws-profile
    if [ $? != 0 ]; then
        # Only touch empty file to prevent source errors
        random_file=$HOME/.temp_aws_profile_`date +%Y%m%d%H%m%S`
        touch $random_file
        >&2 echo $random_file
        exit $?
    else
        selected=`cat /tmp/aws-profile`
        rm -f /tmp/aws-profile
        enable_profile $selected

        # Force Write all credential files after selected
        for p in $profiles; do
            write_credentials $p
        done

    fi
fi

exit 0
