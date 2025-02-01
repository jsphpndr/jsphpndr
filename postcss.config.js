module.exports = {
  plugins: {
    "postcss-import": {},
    "autoprefixer": {},
    "@fullhuman/postcss-purgecss": {
      content: ["./layouts/**/*.html", "./content/**/*.md", "./assets/js/**/*.js"],
      safelist: ["keep-me"], // Add CSS classes you don't want to remove
      defaultExtractor: (content) => content.match(/[\w-/:]+(?<!:)/g) || [],
    },
  },
};
