# aws-profile-sh
A very simple script to manage multiple aws access keys

# Install

- Copy create-aws-profile.sh to your $PATH
- Install command line utilities dialog and jq
- Copy aws-profile.json.example to $HOME/.aws-profile.json and put your profiles here
- Create this alias in your .bashrc or .zshrc file

````
# aws-profile
aws-profile(){
    create-aws-profile.sh 2> /tmp/create-aws-profile.sh.txt
    source `cat /tmp/create-aws-profile.sh.txt`
    clear
}
aws-profile-default(){
    create-aws-profile.sh default 2> /tmp/create-aws-profile.sh.txt
    source `cat /tmp/create-aws-profile.sh.txt`
}
alias aws-profile-show="create-aws-profile.sh show"
```

- Load default profile if you want to, in your  .bashrc or .zshrc file
```
# Load default aws profile using aws-profile script
aws-profile-default
```

- Then simple use one of this commands in command line:
```
aws-profile
aws-profile-show
```


