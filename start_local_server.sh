#!/bin/bash

set -x

JEKYLL_ENV=production bundle exec jekyll serve --trace --future --host 0.0.0.0
