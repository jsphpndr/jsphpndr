#!/bin/bash

# ✅ Build the Hugo site
echo "🚀 Building the Hugo site..."
hugo --minify || { echo "❌ Hugo build failed"; exit 1; }

ls -R public/

# ✅ Check if RSS file exists
RSS_FILE="public/index.xml"
if [ -f "$RSS_FILE" ]; then
  echo "✅ RSS file found."
  DYNAMIC_CONTENT=$(cat "$RSS_FILE")
else
  echo "❌ RSS file not found!"
  exit 1
fi

# ✅ Debug: Display dynamic content
echo "🔍 Dynamic Content Extracted:"
echo "-----------------------------"
echo "$DYNAMIC_CONTENT"
echo "-----------------------------"

# ✅ Explicit path to the root README.md
ROOT_README="./README.md"

# Replace content in the root README.md
sed -i.bak '/<!-- START_DYNAMIC_CONTENT -->/,/<!-- END_DYNAMIC_CONTENT -->/c\
<!-- START_DYNAMIC_CONTENT -->\
'"$DYNAMIC_CONTENT"'\
<!-- END_DYNAMIC_CONTENT -->
' $ROOT_README


# ✅ Debug: Show diff to confirm changes
echo "🔍 Git Diff:"
git diff $ROOT_README

# ✅ Clean up the backup file
rm -f README.md.bak

# ✅ Commit the changes
echo "📦 Committing changes..."
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global user.name "github-actions[bot]"
git add README.md

# ✅ Stage changes
git add $ROOT_README

# ✅ Commit if there are changes
git commit -m "Update README with latest posts" || echo "⚠️ No changes detected to commit."

