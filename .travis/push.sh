#!/bin/bash

setup_git() {
    git init
    git config --global user.email "wjohn1483@yahoo.com.tw"
    git config --global user.name "wjohn1483"
}

commit_website_files() {
    git checkout master
    git add .
    git commit -m "Travis build: $TRAVIS_BUILD_NUMBER"
}

upload_files() {
    git remote add origin https://${GITHUB_TOKEN}@github.com/wjohn1483/wjohn1483.github.io.git > /dev/null 2>&1
    git status
    #git push --quiet --set-upstream origin master
}

cd ./_site
setup_git
commit_website_files
upload_files

