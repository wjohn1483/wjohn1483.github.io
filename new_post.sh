#!/bin/bash

if [ -z "$1" ]; then
    echo "usage: bash $0 [new post name]"
    echo "e.g. bash $0 2020-02-28-create-website-by-Jekyll"
    exit 1
fi

post_name=$1

mkdir -p ./_posts/$post_name
cat << EOF >> ./_posts/$post_name/${post_name}.md
---
title:
tags:
layout: article
footer: false
aside:
  toc: true
mathjax_autoNumber: true
published: true
---
EOF

vim ./_posts/$post_name/${post_name}.md
