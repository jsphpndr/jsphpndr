+++
date = '2025-07-23T08:30:59-04:00'
lastMod = '2025-07-23T08:30:59-04:00'
draft = true
title = "Google Analytics Is Slowing Down Your Website (Here's How to Fix It Securely)"
description = "GA4 is powerful, but it can slow down your site and trigger third-party cookie warnings. Here's how to proxy and defer it using Netlify Functions and Hugo — for faster loads, better privacy, and future-proof analytics."

[feature]
  image = ""
  alt= ""
  figcaption = ""

#Footnotes will be added based on this front matter. Shortcode for footnote reference in text: {{< footnote id="1" >}}.

# [[footnotes]]
#   id = 1
#   content = ""

[params]
  code = true
  post = true
  categories = []
  tags = []
+++

Google Analytics (GA4) is an essential tool for website owners. But it comes with a cost: slower load times, third-party cookie warnings, and unnecessary bloat — especially when loaded directly from Google’s servers.

If you’re serious about performance, privacy, and future-proofing your site, here’s a better way.

In this article, I’ll show you how I optimized Google Analytics on my own site by:
- **Proxying the `gtag.js` script** through Netlify Functions  
- **Delaying its load** using `requestIdleCallback()`  
- **Avoiding third-party cookie issues**  
- And **keeping everything environment-aware** with Hugo and GitHub Actions  

## The Problem with the Default GA4 Snippet

Here’s what Google gives you by default:

```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){ dataLayer.push(arguments); }
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```

That works — but:

- It loads from Google’s domain, not yours
- It fires immediately, delaying your site's render
- And it triggers warnings in Chrome about third-party cookie deprecation

In fact, Chrome now logs:

Third-party cookie will be blocked in future Chrome versions as part of Privacy Sandbox.

## The Better Way: Proxy, Defer, and Cache It Yourself

Here’s the strategy I used:

- Proxy gtag.js with a Netlify Function
- Delay loading using requestIdleCallback() or a setTimeout()
- Use an environment variable for the tracking ID

Add cachebusting, so you can update it without stale CDN issues

## Step 1: The Netlify Function

Create a file at netlify/functions/gtag.js:

```js
export const handler = async () => {
  const GA_ID = process.env.GA_TRACKING_ID;
  const res = await fetch(`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`);

  if (!res.ok) {
    return {
      statusCode: 500,
      body: '// Failed to fetch gtag.js',
    };
  }

  const js = await res.text();

  return {
    statusCode: 200,
    headers: {
      'Content-Type': 'text/javascript; charset=UTF-8',
      'Cache-Control': 'public, max-age=31536000, immutable',
    },
    body: js,
  };
};

```
This fetches the latest Google tag script and serves it from your domain with a proper MIME type and long cache life.

Step 2: Hugo Template for Conditional GA Loading
In your `head.html`` partial, add:

```js
{{ $gaID := getenv "GA_TRACKING_ID" }}
{{ if and (eq hugo.Environment "production") $gaID }}
<script>
  function loadGA() {
    const script = document.createElement('script');
    script.src = '/.netlify/functions/gtag?v={{ now.Unix }}'; // cachebusting
    script.async = true;
    document.head.appendChild(script);

    window.dataLayer = window.dataLayer || [];
    function gtag(){ dataLayer.push(arguments); }
    gtag('js', new Date());
    gtag('config', '{{ $gaID }}', {
      cookie_domain: 'josephpinder.com',
      cookie_flags: 'SameSite=None;Secure'
    });
  }

  'requestIdleCallback' in window
    ? requestIdleCallback(loadGA, { timeout: 5000 })
    : setTimeout(loadGA, 3000);
</script>
{{ end }}
```

## Step 3: Set the Environment Variable

In Netlify:

Go to Site Settings → Environment Variables

Add:
GA_TRACKING_ID = G-XXXXXXXXXX

This keeps your tracking ID out of source control.

## Step 4: Optional GitHub Action (for Static Sites)

If you prefer serving a static JS file (or want a scheduled redeploy), add a GitHub Action like this:

```yml
name: Update GA Script

on:
  schedule:
    - cron: '0 2 * * *'  # Every day at 2am
  workflow_dispatch:

jobs:
  update-ga:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Download gtag.js
        run: curl -s https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX > static/js/gtag.js
      - name: Commit and push
        run: |
          git config user.name "github-actions"
          git config user.email "github-actions@github.com"
          git add static/js/gtag.js
          git commit -m "Update GA script"
          git push

```

## Why Lighthouse Still Flags “Unused JavaScript”

You might see a message like this:

Reduce unused JavaScript (Est. savings: 51 KB)
…functions/gtag?v=xxxxxxx (125.7 KB total)

That’s because gtag.js loads everything GA might ever need — not just the parts you use. Even though it’s deferred, Lighthouse still includes its full size in the audit.

✅ This isn’t hurting your user experience.
✅ You’re already deferring it.
✅ Real-world performance is fine.

Unless you're building your own stripped-down GA proxy (or switching to server-side tracking), this is as optimized as it gets.

## Bonus: Works for Facebook Pixel Too

I used the same approach to speed up Facebook Pixel, with great results.
Here’s how I did that →

## Final Thoughts

This approach isn’t just about speed. It’s about control.

By hosting GA yourself and delaying its execution, you gain:

Better performance scores

Less browser tracking noise

And a smoother, more privacy-conscious foundation for the future web

If you're running Hugo on Netlify (or any static framework), this takes just minutes to implement — and your Core Web Vitals will thank you.