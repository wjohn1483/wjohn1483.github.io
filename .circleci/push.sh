#!/bin/bash

setup_git_folder() {
    git init
    git config --global user.email "${USER_EMAIL}"
    git config --global user.name "${USER_NAME}"
    git remote add origin git@github.com:wjohn1483/wjohn1483.github.io.git
    git pull origin master
}

commit_website_files() {
    git checkout master
    rsync -a --delete-after ../_site/* ./
    git status
    git add .
    git commit -m "Circle build: ${CIRCLE_BUILD_NUM}"
}

upload_files() {
    git push origin master
}

mkdir folder_to_push
cd folder_to_push

setup_git_folder
commit_website_files
upload_files

