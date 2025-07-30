+++
date = '2025-07-30T12:33:03-04:00'
draft = false
title = 'Google Analytics Is Slowing Down Your Website (PHP + Apache)'
description = "Google Analytics can slow down PHP websites with extra JavaScript and render‑blocking code. Learn how to speed up GA4 by caching it locally with PHP, using deferred loading, and adding cachebusting for better performance and SEO."
# categories = []
# tags = []

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

+++

I recently wrote about [Google Analytics slowing down static websites](/blog/google-analytics-slowing-down-website-hugo-netlify-github-actions/).   
However, since PHP still powers the vast majority of websites — including many of the projects I work on — I wanted to share a PHP solution as well.

I often build with Kirby CMS, but this approach works just as well for WordPress or really any PHP application.

Google Analytics (GA4) gives you valuable insights into how people use your site — where they come from, what they read, and whether they convert.

That's great, but it does come with a cost: slower load times and unnecessary bloat — especially when loaded directly from Google's servers.

If you're serious about your website's page performance, this hit to your Core Web Vitals is not acceptable.

Don't worry.

There's a fix.

## The Problem with the Default GA4 Snippet

Here's what Google gives you by default:

```html
<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>
<script>
  window.dataLayer = window.dataLayer || [];
  function gtag(){ dataLayer.push(arguments); }
  gtag('js', new Date());
  gtag('config', 'G-XXXXXXXXXX');
</script>
```
It works — but not without trade‑offs:

- **Extra DNS lookup**: Because it loads from Google's domain, every visit adds another request.
- **Competes with your content**: The script fires right away, slowing your render time.
- **Heavy bundle**: You get the full GA4 payload, even if you use only a fraction of its features.

## How Do I Stop Google Analytics Slowing Down My Website?

The solution isn't to give up analytics — it's to load it smarter.

Here's the approach that I use in my own PHP workflow:

- Cache gtag.js locally with a daily cron job
- Load it after your content using requestIdleCallback() (with a safe fallback)
- Keep your GA ID in one place with an environment variable
- Cachebust daily so visitors always get the latest version

For context: I use a VPS environment with full server access — but most people are on shared hosting. That usually means you're limited to your `public_html/` folder and cPanel cron jobs.  

No problem. In this article, we'll use the most common shared hosting approach, and if you have more advanced server access, you can easily make adjustments.

## Step 1: Set Your GA Tracking ID

First, let's make the tracking ID easy to manage.
Instead of hardcoding it in multiple templates, we'll define it once as a server environment variable.

Because Apache is still the most common setup for PHP websites on shared hosting, we'll use an Apache environment variable.

In your `.htaccess`, add:

```
SetEnv GA_TRACKING_ID G-XXXXXXXXXX
```

Then in PHP you can access it from anywhere:

```php
<?php
  $gaId = getenv('GA_TRACKING_ID');
```

### Why not store this in your CMS config?

Because our update script runs independently of your CMS. Using a server‑level environment variable keeps things lean and avoids bootstrapping the CMS just to grab a string.

## Step 2: Create the Update Script

Instead of pulling gtag.js from Google every page load, we'll fetch it once a day and serve a local copy.

Create a file in your `public_html/` folder called `update-gtag.php`:

```php
<?php
  $gaId = getenv('GA_TRACKING_ID');
  if (!$gaId) exit;

  $target = __DIR__ . '/js/gtag.js';
  $url = "https://www.googletagmanager.com/gtag/js?id={$gaId}";

  $js = file_get_contents($url);
  if ($js) {
      if (!is_dir(__DIR__ . '/js')) {
          mkdir(__DIR__ . '/js', 0755, true);
      }
      file_put_contents($target, $js);
  }
```

This script downloads the latest version of Google's gtag.js and saves it into `/public_html/js/`.

## Step 3: Schedule a Cron Job

Now we'll make sure that script runs automatically once a day.

In cPanel (or your host's cron settings), schedule it like this:

```
0 2 * * * php /home/username/public_html/update-gtag.php
```

*(Replace username with your hosting account username.)*

This job runs daily at 2 AM, updating your local `gtag.js`.

## Step 4: Load Analytics Conditionally (and Deferred)

With a fresh local copy of gtag.js in place, we can load it in the browser without slowing down page rendering.

In your site's `<head>` template, add:

```php
<?php
  $gaId = getenv('GA_TRACKING_ID');
  if ($gaId && $_SERVER['HTTP_HOST'] === 'yourdomain.com'): ?>
  <script>
    function loadGA() {
      const script = document.createElement('script');
      script.src = '/js/gtag.js?v=<?php echo date('Ymd'); ?>'; // daily cachebuster
      script.async = true;
      document.head.appendChild(script);

      window.dataLayer = window.dataLayer || [];
      function gtag(){ dataLayer.push(arguments); }
      gtag('js', new Date());
      gtag('config', '<?php echo $gaId; ?>', {
        cookie_domain: 'yourdomain.com',
        cookie_flags: 'SameSite=None;Secure'
      });
    }

    if ('requestIdleCallback' in window) {
      requestIdleCallback(loadGA, { timeout: 5000 });
    } else {
      setTimeout(loadGA, 3000);
    }
  </script>
<?php endif; ?>
```

Why this works:

- The script loads from your own domain, not Google's.
- The cron job keeps it updated daily.
- The cachebuster ensures browsers refresh once a day.
- Loading is deferred so it never blocks your content

## Why Lighthouse Still Flags “Unused JavaScript”

Even with this optimized setup, you might see a Pagespeed Insights warning like:

![Reduce unused JavaScript (Est. savings: 51 KB)
…functions/gtag?v=xxxxxxx (125.7 KB total)](unused-javascript.jpg "Pagespeed Insights warning")

Don't panic — this doesn't mean your optimization failed.

Here's why:

- **GA4 is a bundle:** Google ships one script that includes every possible feature, even if your site only uses a fraction of them.  
- **Deferred load:** Because we load it with `requestIdleCallback()` or a delayed timeout, it doesn't block your content.  
- **User experience is safe:** In the real world, your visitors won't notice any slowdown from this script.

If you wanted to go further, the next level is a **custom stripped‑down GA implementation** or even **server‑side analytics**, but for most sites this daily‑cached approach is more than enough.

## Bonus: Is Facebook Pixel Slowing Down Your Website?

Google Analytics isn't the only script that can hurt your site's performance.

If you're using the Facebook (now Meta) Pixel, you can face many of the same challenges.

Learn how to [stop Facebook Pixel slowing down your website](/blog/facebook-pixel-is-slowing-down-your-website-and-how-to-fix-it-securely/).

## Final Thoughts

By hosting Google Analytics locally and refreshing it daily with a cron job, you get the best of both worlds: fast load times and up‑to‑date analytics.

This approach works seamlessly on shared hosting, but scales up easily for VPS or dedicated servers.