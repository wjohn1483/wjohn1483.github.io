#!/bin/bash

setup_git_folder() {
    git init
    git config --global user.email "wjohn1483@yahoo.com.tw"
    git config --global user.name "wjohn1483"
    git remote add origin https://${GITHUB_TOKEN}@github.com/wjohn1483/wjohn1483.github.io.git > /dev/null 2>&1
    git pull origin master
}

commit_website_files() {
    git checkout master
    cp -r ../_site/* ./
    git add .
    git commit -m "Travis build: $TRAVIS_BUILD_NUMBER"
}

upload_files() {
    git status
    #git push --quiet --set-upstream origin master
}

mkdir folder_to_push
cd folder_to_push
setup_git_folder
commit_website_files
upload_files

