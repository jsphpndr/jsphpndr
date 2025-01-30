+++
date = '2021-05-28T00:00:00-04:00'
draft = false
title = 'Stop Email Spam With Obscurejs Hide Your Email Address From Spammers'
description = ''

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
  hasObscure = false
+++

Did you know that spambots scan websites looking to harvest emails all the time? I didn’t. At least, not starting out.  

When I first started programming, I didn’t know that it was a bad idea to hardcode email addresses into my HTML. Needless to say, I got a lot of spam. Lots and lots of it.  

When I first started looking around for a solution, this was what I found:  

```html
<script>
	let user = 'name';
	let site = 'domain.com';
	document.write('<a href="mailto:' + user + '@' + site + '">');
	document.write(user + '@' + site + '</a>');
</script>
```

It worked great. Or, so I thought.  

If you’re paying attention, you may immediately spot what’s wrong.  

It’s `document.write`.  

And since it’s a common solution still offered today, I didn’t have many options.  

So, I wrote a plugin…  

## Obscure.js  

**Obscure.js** is a lightweight script that obscures — or hides — email addresses and telephone numbers from spammers.  

### How Does It Work?  

Obscure.js uses data-attributes on the `<template>` tag to generate email addresses and telephone numbers.  

This is a great approach because the `<template>` tag is a non-semantic element designed specifically to render its content with JavaScript. When JavaScript isn’t available, the content in our `<template>` tag isn’t rendered, and we get a quiet fail.  

### Attributes  

The `obscure` data-attribute is required on the `<template>` tag in order to work.  

Values for email addresses and numbers utilize the `data-pX` data-attribute, wherein `X` represents an integer (i.e. `data-p1="val"`, `data-p2="val"`).  

ID and class attributes can also be added to `<template>` tags.  

```html
<template id="val" class="val" data-p1="val" data-p2="val" obscure></template>
```

### Patterns  

Patterns are determined by the content configuration nested in the `<template>` tag.  

To call a value in a pattern, use `%X` wherein `X` represents a corresponding integer (i.e. `%1`, `%2`).  

```plaintext
%1@%2
```

### Adding an Email Address  

To add an email address, create a `<template>` tag with the following attributes:  

- `data-p1`  
- `data-p2`  
- `obscure`  

The `data-p1` data-attribute will contain the username, and `data-p2` the relevant domain (i.e. `hotmail.com` or `mycustomurl.com`).  

```html
<template obscure data-p1="hello" data-p2="example.com">
  <a href="mailto:%1@%2">%1@%2</a>
</template>
```

This will render the following:  

```html
<span><a href="mailto:hello@example.com">hello@example.com</a></span>
```

### Adding Telephone Numbers  

There’s not only a need to hide emails, but phone numbers as well.  

To add a US-pattern telephone number, create a `<template>` tag with the following attributes:  

- `data-p1`  
- `data-p2`  
- `data-p3`  
- `data-p4`  
- `obscure`  

The `data-p1` data-attribute represents the country code, `data-p2` the area code, `data-p3` the prefix code, and `data-p4` the line code.  

```html
<template obscure data-p1="+1" id="test2" class="test1" data-p2="481" data-p3="914" data-p4="1124">
  (%2) %3-%4
</template>
```

This will render the following:  

```html
<span>(481) 914-1124</span>
```

If not already apparent, Obscure.js allows numbers to be rendered in any pattern as well.  

```html
<template id="france" class="french pattern" data-p1="+33" data-p2="1" data-p3="22" data-p4="33" data-p5="44" data-p6="55" obscure>
  <a href="tel:%1%2%3%4%5%6">%1 %2 %3 %4 %5 %6</a>
</template>

<span id="france" class="french pattern"><a href="tel:+33122334455">+33 1 22 33 44 55</a></span>
```

### Initialize Obscure.js  

Just before the closing `</body>` tag, include the `obscure.js` external script and initialize:  

```html
<script src="/path/to/obscure.min.js"></script>

<script>
  var obscure = new Obscure();
</script>

```

## Special Thanks

A special thanks to Jordin Brown for his help on this project.