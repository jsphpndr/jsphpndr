+++
date = '2025-07-30T08:30:59-04:00'
draft = false
title = "Google Analytics Is Slowing Down Your Website (HUGO + Netlify + GitHub Actions)"
description = "Google Analytics can slow down your website with unnecessary JavaScript bloat. Learn how to proxy and defer GA4 using Hugo, Netlify, and GitHub Actions for faster, privacy-friendly performance."

[feature]
  image = "pagespeed-insights-report-joseph-pinder.jpg"
  alt= "Google Pagespeed Insights report for josephpinder.com"
  figcaption = "Google Pagespeed Insights report for josephpinder.com"

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

Google Analytics (GA4) is an essential tool for website owners. It’s how we keep track of who’s visiting, where they’re coming from, what pages they’re reading, and whether they’re taking the actions we want — from filling out a form to making a purchase.

All of that is great, but it does come with a cost: slower load times and unnecessary bloat — especially when loaded directly from Google’s servers. Over time, those extra milliseconds add up, impacting both user experience and your site’s performance scores.

Obviously, that won’t work if you’re serious about performance, privacy, and future-proofing your site. The good news? There’s a fix.

In this article, I’ll show you how I optimized Google Analytics on my own site by:
- **Proxying the `gtag.js` script** through Netlify Functions  
- **Delaying its load** using `requestIdleCallback()`  
- And **keeping everything environment-aware** 

<!-- {{< advisory >}}
This article focuses on a **Hugo, Netlify, and GitHub Actions** setup.  
If your site runs on PHP, I’ve written a separate guide you can follow [here](/blog/google-analytics-php-performance-fix).
{{< /advisory >}} -->

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
- Adds unnecessary JavaScript bloat most sites don’t even use

## How Do I Stop Google Analytics Slowing Down My Website?

The solution isn’t to give up analytics — it’s to load it smarter.

Here’s the approach I use on my own site:

- **Proxy `gtag.js`** through a Netlify Function, so it loads from your domain instead of Google’s  
- **Delay loading** with `requestIdleCallback()` (or a `setTimeout()` fallback), so it never blocks your content  
- **Keep the tracking ID secure** using a Netlify environment variable  
- **Add cachebusting** to make sure you always serve a fresh copy, even if Google updates the script  

## Step 1: The Environment Variable

Before we get started with our code, one small but important piece of this setup is the tracking ID.

Instead of hardcoding it in multiple places, we’ll keep things **DRY** by storing it in a single environment variable.  

This way:
- You only update the ID in one place if it changes  
- You avoid sprinkling the value across multiple templates  
- Your Hugo templates and Netlify Functions both read from the same source  

To add your GA tracking ID as an environment variable in Netlify, follow [this guide](https://docs.netlify.com/build/configure-builds/environment-variables/).

For this tutorial, the variable should be named: `GA_TRACKING_ID = G-XXXXXXXXXX`.

Once added, you can access it using:

```js
// In your Netlify Function
const GA_ID = process.env.GA_TRACKING_ID;
```

```html
<!-- In HUGO Templates -->
{{ getenv "GA_TRACKING_ID" }}
```

With the environment variable in place, we’re ready to build the Netlify Function that will proxy the `gtag.js` script from Google and serve it from your own domain.

## Step 2: The Netlify Function

Now that your environment variable is set, the next step is to proxy Google’s gtag.js script through a Netlify Function.

Why do this? Because by default, the script is served from Google’s domain (`googletagmanager.com`). That creates a few problems:

- **Extra DNS lookups:** Every new third‑party domain adds a delay.  
- **Less control:** You can’t set your own cache rules or headers on a third‑party script.  
- **Privacy concerns:** Loading from a third‑party domain makes it easier for browsers to flag or block it.  

By serving `gtag.js` from *your own domain*, you still gain important advantages:  
- Faster DNS resolution (no extra lookup)  
- Full cache control (so you can decide how long browsers should store it)  
- The script itself loads in a first‑party context, which plays nicer with evolving privacy rules  
- A consistent way to inject updates without touching Google’s snippet directly  

Now, let’s create the function that handles this proxying.

Create a file at netlify/functions/gtag.js:

```js
// Netlify Function: Proxy Google Analytics gtag.js
// This fetches the GA script from Google's servers and serves it from your own domain,
// giving you cache control, a first-party context, and better performance.

export const handler = async () => {
  // Get the GA Tracking ID from Netlify environment variables
  const GA_ID = process.env.GA_TRACKING_ID;

  // Fetch the latest gtag.js script from Google with your tracking ID
  const res = await fetch(`https://www.googletagmanager.com/gtag/js?id=${GA_ID}`);

  // If the request fails, return a 500 error with a simple comment
  if (!res.ok) {
    return {
      statusCode: 500,
      body: '// Failed to fetch gtag.js',
    };
  }

  // Read the script contents as text
  const js = await res.text();

  // Return the script with proper headers
  return {
    statusCode: 200,
    headers: {
      // Ensure the browser treats this as JavaScript
      'Content-Type': 'text/javascript; charset=UTF-8',
      // Cache aggressively for a year; updates are forced by a cachebusting query string
      'Cache-Control': 'public, max-age=31536000, immutable',
    },
    // Send the script content as the response body
    body: js,
  };
};

```

This fetches the latest Google tag script and serves it from your domain with a proper MIME type and long cache life.

## Step 3: Hugo Template for Conditional GA Loading

The final piece is adding the script to your site — but only when it makes sense.

We don’t want Google Analytics loading in every environment.  
For example:
- **In development:** It clutters your reports with test data.  
- **In staging:** It may give a false picture of real users.  
- **In production:** Yes, this is where we want it.

To handle this, Hugo allows us to check both the current environment and whether our GA tracking ID is set. 

This ensures the script only loads when we’re in production and the environment variable exists.

In your `<head>` element (wherever it may be located), add:

```html
{{/* Pull the GA tracking ID from the Netlify environment variable */}}
{{ $gaID := getenv "GA_TRACKING_ID" }}
{{/* Only run the following block if:
      1. The site is being built in the "production" environment
      2. The GA tracking ID is actually set */}}
{{ if and (eq hugo.Environment "production") $gaID }}
<script>
  // Define a function to load the GA script from our Netlify proxy
  function loadGA() {
    // Create a new <script> element
    const script = document.createElement('script');
    // Point it to our Netlify Function with a cachebusting query string
    script.src = '/.netlify/functions/gtag?v={{ now.Unix }}';
    script.async = true; // Load asynchronously so it doesn’t block rendering
    // Append the script to the <head>
    document.head.appendChild(script);

    // Initialize the GA data layer
    window.dataLayer = window.dataLayer || [];
    function gtag(){ dataLayer.push(arguments); }
    gtag('js', new Date()); // Mark script start time
    gtag('config', '{{ $gaID }}', {
      cookie_domain: 'yourdomain.com',
      cookie_flags: 'SameSite=None;Secure' // Future‑proof cookies
    });
  }

  // Defer loading:
  // - Prefer requestIdleCallback (if supported)
  // - Otherwise, fall back to a 3‑second timeout
  'requestIdleCallback' in window
    ? requestIdleCallback(loadGA, { timeout: 5000 })
    : setTimeout(loadGA, 3000);
</script>
{{ end }}

```

## Step 4: GitHub Action for Weekly Updates

The current setup will update your Google Analytics code on each deploy — which works fine as long as you’re actively updating your site.  

The problem is, most of us don’t push changes every day (or even every week).  
That means your `gtag.js` could go stale if Google makes updates and you haven’t deployed recently.  

To solve this, we schedule a GitHub Action that **triggers a Netlify deploy once a week** — even if nothing has changed in your repo. This guarantees your proxied GA script is always up to date.  

I run mine every Tuesday at **8 AM EST (12 PM UTC)**. Why Tuesday?  
- Early in the week, but not Monday (which often gets busy).  
- Ensures the script is refreshed after the weekend, before the heaviest mid‑week traffic.  
- Running it in the morning means the site is updated and cached for the rest of the day.  

Here’s the workflow file:

```yml
# This is the name that will show up for the workflow in GitHub Actions
name: Update GA Script

on:
  # Schedule this workflow to run automatically
  schedule:
    - cron: '0 2 * * *'  # Every day at 2am UTC
  # Allow manual runs from the GitHub Actions dashboard
  workflow_dispatch:

jobs:
  # Define the job that updates the GA script
  update-ga:
    # Use the latest Ubuntu runner for this job
    runs-on: ubuntu-latest
    steps:
      # Step 1: Check out the repository so we can modify files
      - uses: actions/checkout@v3

      # Step 2: Download the latest gtag.js from Google
      - name: Download gtag.js
        run: curl -s https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX > static/js/gtag.js

      # Step 3: Commit and push the updated gtag.js back to the repo
      - name: Commit and push
        run: |
          # Configure git with a bot user identity
          git config user.name "github-actions"
          git config user.email "github-actions@github.com"

          # Stage the downloaded gtag.js file
          git add static/js/gtag.js

          # Commit the change with a clear message
          git commit -m "Update GA script"

          # Push the commit to the repository, triggering a new Netlify deploy
          git push

```
This ensures that:

- Your GA script is refreshed once a week, automatically
- You don’t have to remember to push a commit just to keep Analytics up to date
- Your site is always serving the latest Google Analytics code, even if your content hasn’t changed

## Why Lighthouse Still Flags “Unused JavaScript”

You might see a message like this:

![Reduce unused JavaScript (Est. savings: 51 KB)
…functions/gtag?v=xxxxxxx (125.7 KB total)](unused-javascript.jpg "Pagespeed Insights warning")

That’s because `gtag.js` loads everything GA might ever need — not just the parts you use. Even though it’s deferred, Lighthouse still includes its full size in the audit.

- This isn’t hurting your user experience.
- You’re already deferring it.
- Real-world performance is fine.

Unless you're building your own stripped-down GA proxy (or switching to server-side tracking), this is as optimized as it gets.

## Bonus: Is Facebook Pixel Slowing Down Your Website?

Google Analytics isn’t the only script that can hurt your site’s performance.  
If you’re using the Facebook (now Meta) Pixel, you can face many of the same challenges.

Learn how to [stop Facebook Pixel slowing down your website](/blog/facebook-pixel-is-slowing-down-your-website-and-how-to-fix-it-securely/).


## Final Thoughts

This approach isn’t just about speed. It’s about control.

By hosting GA yourself and delaying its execution, you gain:

- Better performance scores
- Less browser tracking noise
- And a smoother, more privacy-conscious foundation for the future web

If you're running Hugo on Netlify (or any static framework), this takes just minutes to implement — and your Core Web Vitals will thank you.