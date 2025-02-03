#!/bin/bash

# ✅ Build the Hugo site
echo "🚀 Building the Hugo site..."
hugo --minify || { echo "❌ Hugo build failed"; exit 1; }

# ✅ List the contents of the public folder for debugging
echo "📂 Listing Generated Files:"
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

# ✅ Fallback if dynamic content is empty
if [ -z "$DYNAMIC_CONTENT" ]; then
  echo "⚠️ Dynamic content is empty. Adding placeholder."
  DYNAMIC_CONTENT="No recent posts available."
fi

# ✅ Debug: Display dynamic content
echo "🔍 Dynamic Content Extracted:"
echo "-----------------------------"
echo "$DYNAMIC_CONTENT"
echo "-----------------------------"

# ✅ Explicit path to the root README.md
ROOT_README="./README.md"

# ✅ Ensure the README.md has dynamic content markers
if ! grep -q "<!-- START_DYNAMIC_CONTENT -->" "$ROOT_README"; then
  echo "❌ START_DYNAMIC_CONTENT marker not found in README.md!"
  exit 1
fi

if ! grep -q "<!-- END_DYNAMIC_CONTENT -->" "$ROOT_README"; then
  echo "❌ END_DYNAMIC_CONTENT marker not found in README.md!"
  exit 1
fi

# ✅ Replace content between markers in README.md
sed -i.bak '/<!-- START_DYNAMIC_CONTENT -->/,/<!-- END_DYNAMIC_CONTENT -->/c\
<!-- START_DYNAMIC_CONTENT -->\
'"$DYNAMIC_CONTENT"'\
<!-- END_DYNAMIC_CONTENT -->
' "$ROOT_README"

# ✅ Debug: Show the content before and after the update
echo "📋 Updated Content:"
grep -A5 "<!-- START_DYNAMIC_CONTENT -->" "$ROOT_README"

# ✅ Show Git diff to confirm changes
echo "🔍 Git Diff:"
git diff "$ROOT_README"

# ✅ Clean up the backup file
rm -f README.md.bak

# ✅ Configure Git for GitHub Actions
echo "⚙️ Configuring Git..."
git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
git config --global user.name "github-actions[bot]"

# ✅ Stage changes
git add "$ROOT_README"

# ✅ Commit changes if detected
echo "📦 Committing changes..."
git commit -m "Update README with latest posts" || echo "⚠️ No changes detected to commit."

# ✅ Push changes to GitHub
echo "🚀 Pushing changes to GitHub..."
git push origin main || echo "⚠️ No changes to push."
