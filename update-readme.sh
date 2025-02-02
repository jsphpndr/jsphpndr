#!/bin/bash

# Build the Hugo site to generate content
hugo --minify || { echo "❌ Hugo build failed"; exit 1; }

# Extract dynamic content
if [ -f public/rss/index.xml ]; then
  DYNAMIC_CONTENT=$(cat public/rss/index.xml)
else
  echo "❌ RSS file not found!"
  exit 1
fi


# Replace content in README.md
sed -i.bak "/<!-- START_DYNAMIC_CONTENT -->/,/<!-- END_DYNAMIC_CONTENT -->/c\
<!-- START_DYNAMIC_CONTENT -->\n$DYNAMIC_CONTENT\n<!-- END_DYNAMIC_CONTENT -->
" README.md

# Remove the backup file
rm -f README.md.bak


# Commit the updated README.md to GitHub
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global user.name "github-actions[bot]"
git add README.md
git commit -m "Update README with latest blog posts 🚀"
git push
