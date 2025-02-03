#!/bin/bash

# ✅ Build the Hugo site
echo "🚀 Building the Hugo site..."
hugo --minify || { echo "❌ Hugo build failed"; exit 1; }

ls -R public/

# ✅ Check if RSS file exists
RSS_FILE="public/rss/index.xml"
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

# ✅ Replace placeholder content in README.md
echo "🔄 Updating README.md..."
sed -i.bak "/<!-- START_DYNAMIC_CONTENT -->/,/<!-- END_DYNAMIC_CONTENT -->/c\
<!-- START_DYNAMIC_CONTENT -->\n$DYNAMIC_CONTENT\n<!-- END_DYNAMIC_CONTENT -->
" README.md

# ✅ Debug: Show diff to confirm changes
echo "🔍 Git Diff:"
git diff README.md

# ✅ Clean up the backup file
rm -f README.md.bak

# ✅ Commit the changes
echo "📦 Committing changes..."
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global user.name "github-actions[bot]"
git add README.md

# ✅ Check if there's anything to commit
if git diff --cached --quiet; then
  echo "⚠️ No changes detected to commit."
else
  git commit -m "Automated update of README 🚀"
  git push
fi
