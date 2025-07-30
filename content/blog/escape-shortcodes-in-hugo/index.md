+++
date = '2025-02-03T09:13:15-05:00'
draft = false
title = 'Escape Shortcodes in HUGO'
description = "Learn how to escape shortcodes in HUGO and display them as raw text in your markdown files. This quick and easy workaround ensures your shortcodes don't accidentally execute when you don't want them to."

[feature]
  image = ""
  alt= ""
  figcaption = ""

#Footnotes will be added based on this front matter. Shortcode for footnote reference in text: {{< footnote id="1" >}}.

# [[footnotes]]
#   id = 1
#   content = ""

[params]
  hasTwic = true
  post = true
  categories = ['HUGO']
  tags = ['hugo', 'shortcodes']
+++

If you're here, you probably just found out that HUGO shortcodes need to be escaped. 

I wrote an [article on how to inline SVGs in HUGO](/blog/inline-svg-files-in-hugo) the other day and ran into the same little snag when trying to place a shortcode in a `<code>` block. It executed. Not only that, but I didn't know why. 

So, after a quick, not-so-quick Google search, I came upon [Chris Liatas' article on escaping HUGO shortcodes](https://liatas.com/posts/escaping-hugo-shortcodes/). That being said, first article done and I thought this would be something great to share and keep on the books.

So, here we go.


## The Problem

Occasionally, you might need to display a shortcode in your HUGO markdown file without triggering it. 

For example, you might want to show `{{</* myshortcode */>}}` as raw text in your content, but when you try to escape it with a backslash (`\`), it doesn't work. Instead, you might see ```\{{</* myshortcode */>}}\``` or `\{\{</* myshortcode */>\}\}`—or worse, the shortcode still executes.

[Bjørn Erik Pedersen](https://bep.is/en/), HUGO's creator, {{< quote cite="https://discourse.gohugo.io/t/how-is-the-hugo-doc-site-showing-shortcodes-in-code-blocks/9074" >}}assumed that it was just needed for the shortcode documentation, so I never documented that feature itself{{< /quote >}}.

To escape a HUGO shortcode, you can add a `/*` after the opening double curly braces and the angle bracket or percent sign (i.e., `{{</* `or `{{%/*`) and adding `*/` after the closing angle bracket or percent sign and double curly braces (i.e., `*/>}}` or `*/%}}`). 

That being said, if you wanted to render the shortcode `myshortcode`, include it in your markdown file as:

```md

{{&lt/* myshortcode */&gt}}

```

And the above will render the following:

```html

{{</* myshortcode */>}}

```

Happy coding!