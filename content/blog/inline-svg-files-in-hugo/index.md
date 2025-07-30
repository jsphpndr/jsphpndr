+++
date = '2025-02-01T00:40:07-05:00'
draft = false
title = 'Inline SVG Files in HUGO'
description = "Learn how to inline SVG files in HUGO with simple solutions ranging from static files to dynamic shortcodes. This guide covers everything you need to style and manage SVGs efficiently in your HUGO projects."

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
  categories = ['HUGO', 'Web Development']
  tags = ['hugo', 'svg', 'web development']
+++

This site is [built with HUGO](https://gohugo.io/). 

Wait. 

That's not why you're here.

The thing is, I've been picking up a few things along the way while building and tweaking this thing. I've run into a few issues here and there, gotten some answers and thought they might be worth sharing. 

Which is great, because I have something to write about, you get some help and it's an easy reference for the both of us. It's a win-win!

That being said let's get back to the reason you're here: inlining SVGs in HUGO.

## As a Static File

If you're just looking to inject inline SVGs into your HTML, then you can place your SVG file in your project's `static/` directory.

```
📂 static/
 ├── 📂 icons/          # ✅ Store SVG files here
 │    ├── logo.svg

```

Then to include it in your template, you can use the `readFile` and `safeHTML` functions.

```html

  {{ readFile "static/icons/logo.svg" | safeHTML }}

```

This works, but it could be better. Suppose you wanted wanted to use the same file in multiple places, but for accessibility and/or other reasons, you might want to change the `<title>` or some other content?

Well, that's where our next approach comes in...

## As a Partial

HUGO allows us to utilize SVGs as partials. So, the next approach involves putting your SVG in the `layouts/partials/` directory.

```
📂 layouts/
 ├── 📂 partials/         # ✅ Store SVG files here
 │    ├── 📂 icons/  
 │         ├── logo.svg
```

With this, we can pass variables to SVG partial and use them dynamically in our file.

In your template:

```html

{{- partial "icons/logo.svg" "Joe" -}}

```

In your partial:

```html

<svg  xmlns="http://www.w3.org/2000/svg" width="200" height="50" 
  role="img" aria-label="{{ . }}">
  <title>{{ . }}</title>
  <rect width="200" height="50" fill="blue" />
</svg>

```

Or if you want to pass more variables, you can use a map:

```html

{{ partial "icons/logo.svg" (dict "name" "Joe" "color" "red") }}

```

And in the partial:

```html

  <svg xmlns="http://www.w3.org/2000/svg" width="200" height="50" 
    role="img" aria-label="{{ .name }}">
    <title>{{ .name }}</title>
    <rect width="200" height="50" fill="{{ .color }}" />
  </svg>


```

## As a Resource

As of right now, I don't have a CMS for this site. But let's say, that you do, because why would anyone sane do this without a CMS? Right?

Well, we can create a shortcode for this. We'll have the same limitations as we did earlier with a static file in not being able to pass any variables to the file, but meh...

The first thing we'll have to do is create a shortcode in `layouts/shortcodes/`. For the sake of simplicity, let's say `svg.html`.

In your shortcode, you'd do something like this;

```html
  <!-- We'll first use printf to format a string value. -->
  {{ $resourcePath := printf "uploads/%s.svg" (.Get "name") }}
  <!-- Then try to load the SVG from the provided path. -->
  {{ with resources.Get $resourcePath }}
    {{ .Content | safeHTML }}
  {{ else }}
  <!-- And if it fails, return this. -->
    <span>Icon not found: {{ .Get "name" }}</span>
  {{ end }}

```

And call it in your markdown like you would any other shortcode.

```

{{</* svg name="logo" */>}}

  
```

There's a more dynamic option if you're up for doing a bit more work, but honestly, I think this solution will cover most use cases.

If you've made it to the end, I hope you found this helpful! 

Happy coding!