+++
date = '2020-07-19T00:00:00-04:00'
draft = false
title = 'Facebook Pixel Is Slowing Down Your Website (And How To Fix It, Securely)'
description = ''
lastMod = '2025-01-29T06:43:45-05:00'

[feature]
  image = "uploads/gt-metrix-score.jpg"
  alt= "GT Metrix Page Speed results for josephpinder.com"
  figcaption = ""

#Footnotes will be added based on this front matter. Shortcode for footnote reference in text: {{< footnote id="1" >}}.

# [[footnotes]]
#   id = 1
#   content = ""

[params]
  hasTwic = true
  hasObscure = false

+++


Analytical tools are ubiquitous with the modern web. Even the most basic website has at least one of these analytical tools (most, likely Google Analytics) running in the background. Why not Facebook?

In this article, we will find out how Facebook Pixel slows down your website and how to resolve this problem securely.

## What is Facebook Pixel?

Facebook Pixel is an analytics tool that helps you:

- track conversions from Facebook ads,
- optimize Facebook Ads,
- build targeted audiences for future ads,
- and remarket to people who have taken some kind of action on your website.

It’s a great tool, but it’s a tool that might be slowing your website down, costing you leads and money.

## What’s the problem?

If you’re following [Facebook’s instructions on installing Facebook Pixel](https://web.archive.org/web/20240103080305/https://www.facebook.com/business/help/952192354843755?id=1205376682832142) or getting some, umm… expert advice, you’ll most likely be advised to place the Facebook Pixel code in your site’s head element.

Don’t do this!

![Facebook Pixel GT Metrix Before Results](/uploads/joseph-pinder-gt-metrix-facebook-pixel-before-results.jpeg "Fig.1.1 Facebook Pixel GT Metrix Before Results")

Unedited, Facebook’s little code snippet can add anywhere from 1.3–1.5 seconds to your page’s load time. To make matters worse, the script is loaded, four HTTP requests made and 170KB added to your [page weight](https://web.archive.org/web/20240103080305/https://whatdoesmysitecost.com/) (or page size) all before your page’s First Paint—that’s before the first pixel is even visible on the screen.

The entire point of page speed optimization is to reduce page weight and the number of HTTP requests, allowing the most important aspects of your page to load first. [According to Google](https://web.archive.org/web/20240103080305/https://webmasters.googleblog.com/2010/05/you-and-site-performance-sitting-in.html), “2 seconds is the threshold for… site acceptability… at Google… under half a second”. Considering a truly performant website loads in a second or less, do you really want to add Facebook’s 1.5s to your site’s page load time?

If you’re like me and using [GT Metrix](https://web.archive.org/web/20240103080305/https://gtmetrix.com/) to test your page’s performance, you will also be presented with some other warnings like **Leverage browser caching**, **Specify a cache validator** and **Add Expires headers**.

So, how can we resolve these issues?

## Google Tag Manager

Over at [8WebDesign](https://web.archive.org/web/20240103080305/https://www.8webdesign.com.au/), a recommended solution was [to use Google Tag Manager](https://web.archive.org/web/20240103080305/https://www.8webdesign.com.au/website-speed/facebook-pixel-making-website-slower/).

This wasn’t a bad attempt. It works in part and with some exceptions.

The first issue is that while Google Tag Manager does indeed reduce page load time, it has no way of dealing with the cache issues listed earlier. You will still see warnings for  **Leverage browser caching**, **Specify a cache validator** and **Add Expires headers**.

The second problem and more importantly, unlike Google Analytics which is native to Google Tag Manager, the Facebook Pixel has to be added manually.

The [Google Tag Manager snippet can be enabled with a nonce](https://web.archive.org/web/20240103080305/https://developers.google.com/tag-manager/web/csp) along with its native tags, but custom Javascript variables cannot. Adding the Facebook Pixel snippet to Google Tag Manager manually will get you a nasty error and worst of all, the script won’t run. This creates a problem.

This site uses a strong Content Security Policy and internal styles and scripts require either a hash or nonce to be loaded and executed.

For those who are keeping up with the latest in website security and best practices, this solution won’t work.

## Enter The Fix

To fix our problem, we need to first place the Facebook Pixel snippet at the end of our document, just before the closing `<body>` tag.

Next, we need to delay the snippet’s execution until after the page has loaded by wrapping our script with the following code:

```js
  setTimeout(function(){
    /* Facebook Pixel Code */
    }, 3000);
```

Thanks, [Shay Toder](https://web.archive.org/web/20240103080305/https://www.shaytoder.com/improving-page-speed-when-using-facebook-pixel/).

## Security — Client Side

We’re going to add a nonce to our opening script tag.

Note: If you’re not generating nonces dynamically, for the purposes of this article, you can head over to random.org and generate a random string.

```html
<script nonce="4yZwhMbBbX"></script>
```
    
The Facebook Pixel image uses an inline style. Unfortunately, nonces don’t work for inline styles. So, how do we get around this?

First let’s add a class to our `<img>` tag like “pixel”.

```html
<noscript><img height="1" width="1" class="pixel" src="https://www.facebook.com/tr?id=YOUR_FACEBOOK_APP_ID&ev=PageView&noscript=1"/></noscript>
```

To apply our styles, we can either place the inline CSS in a `<style>` tag or use an external stylesheet. For the purposes of this article, we will use an internal style.

```html
<style nonce="4yZwhMbBbX">.pixel{display:none}</style>
```

If we put it all together, you should have something that looks like this:

```html
</footer>
	<!-- End Footer -->

	<!-- Facebook Pixel Code -->
	<script nonce="4yZwhMbBbX">
		setTimeout(function() {
			! function(f, b, e, v, n, t, s) {
				if (f.fbq) return;
				n = f.fbq = function() {
						n.callMethod ? n.callMethod.apply(n, arguments) : n.queue.push(arguments)
				};
				if (!f._fbq) f._fbq = n;
				n.push = n;
				n.loaded = !0;
				n.version = '2.0';
				n.queue = [];
				t = b.createElement(e);
				t.async = !0;
				t.src = v;
				s = b.getElementsByTagName(e)[0];
				s.parentNode.insertBefore(t, s)
			}(window, document, 'script', 'https://connect.facebook.net/en_US/fbevents.js');
			fbq('init', 'XXXXXXXXXX');
			fbq('track', 'PageView');
		}, 3000);
	</script>
	<noscript><img height="1" width="1" class="pixel" src="https://www.facebook.com/tr?id=XXXXXXXXXX&ev=PageView&noscript=1"/></noscript>
	<style nonce="4yZwhMbBbX">.pixel{display:none}</style>
	<!-- End Facebook Pixel Code -->

</body>
<!-- Closing Body Tag -->

</html>
<!-- End Document -->
```

## Security — Server Side

Last, but not least, we need to modify our Content Security Policy header to allow external scripts from Facebook’s domains. So, we’ll make the following changes to our .htaccess—or whatever your configuration—file:

```
Header add Content-Security-Policy " \
  style-src 'self' 'nonce-2IRI4BAdMt' ; \
  script-src 'self' 'nonce-4yZwhMbBbX' *.facebook.net; \
  connect-src 'self' www.facebook.com; \
  "
```

Note: connect-src is required to allow these scripts to work in the Safari browser.

## Results

![Facebook Pixel GT Metrix After Results](/uploads/joseph-pinder-gt-metrix-facebook-pixel-after-results.jpg "Fig.1.2 — Facebook Pixel GT Metrix After Results")

1. By placing the Facebook Pixel at the end of our document, we allow our script to be loaded without interrupting our page’s first paint.

2. Delaying the execution of the script by 3 seconds:
  - reduces our page weight by 170Kb,
  - and delays our HTTP requests so that it’s not counted towards our page load time.

3. By using a Content Security Policy, we ensure that the only scripts running are those we want to run.

You can check your results over at [GT Metrix](https://web.archive.org/web/20240103080305/https://gtmetrix.com/) or with your browser’s developer tools.