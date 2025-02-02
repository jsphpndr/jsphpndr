#!/bin/bash

# Build the Hugo site to generate the content
hugo

# Extract dynamic content from the generated file
DYNAMIC_CONTENT=$(cat public/rss/index.xml)

# Replace the placeholder in README.md
sed -i.bak "/<!-- START_DYNAMIC_CONTENT -->/,/<!-- END_DYNAMIC_CONTENT -->/c\
<!-- START_DYNAMIC_CONTENT -->\n$DYNAMIC_CONTENT\n<!-- END_DYNAMIC_CONTENT -->
" README.md

# Commit the updated README.md to GitHub
git config --global user.email "you@example.com"
git config --global user.name "GitHub Action"
git add README.md
git commit -m "Update README with latest blog posts 🚀"
git push
