---
layout: post
title:  "Education must also train one for quick, resolute and effective thinking."
author: john
categories: [ Jekyll, tutorial ]
image: assets/images/3.jpg
beforetoc: "Markdown editor is a very powerful thing. In this article I'm going to show you what you can actually do with it, some tricks and tips while editing your post."
toc: true
summary: "A comprehensive guide to the Markdown editor's capabilities, covering special formatting (strikethrough, highlights), code blocks with syntax highlighting, reference lists, and embedding full HTML including YouTube videos. The post serves as both a tutorial and a live demonstration."
faq:
  - q: "How do I add syntax-highlighted code blocks in Markdown?"
    a: "Use triple backticks followed by the language name (e.g., ```ruby) to create a fenced code block with syntax highlighting. Jekyll uses Rouge as the default syntax highlighter."
  - q: "Can I use HTML inside a Markdown file?"
    a: "Yes, Markdown supports inline HTML. You can write standard HTML tags directly in your Markdown content and they will render as expected."
definitions:
  - term: "Markdown"
    definition: "A lightweight markup language created by John Gruber that uses plain text formatting syntax to create structured documents. It is widely used for writing content in static site generators like Jekyll."
sources:
  - url: "https://daringfireball.net/projects/markdown/"
    title: "Daring Fireball — Markdown by John Gruber"
  - url: "https://jekyllrb.com/docs/configuration/markdown/"
    title: "Jekyll — Markdown Configuration"
---
There are lots of powerful things you can do with the Markdown editor

If you've gotten pretty comfortable with writing in Markdown, then you may enjoy some more advanced tips about the types of things you can do with Markdown!

As with the last post about the editor, you'll want to be actually editing this post as you read it so that you can see all the Markdown code we're using.


## Special formatting

As well as bold and italics, you can also use some other special formatting in Markdown when the need arises, for example:

+ ~~strike through~~
+ ==highlight==
+ \*escaped characters\*


## Writing code blocks

There are two types of code elements which can be inserted in Markdown, the first is inline, and the other is block. Inline code is formatted by wrapping any word or words in back-ticks, `like this`. Larger snippets of code can be displayed across multiple lines using triple back ticks:

```
.my-link {
    text-decoration: underline;
}
```

If you want to get really fancy, you can even add syntax highlighting using Rouge.


![walking]({{ site.baseurl }}/assets/images/8.jpg)

## Reference lists

The quick brown jumped over the lazy.

Another way to insert links in markdown is using reference lists. You might want to use this style of linking to cite reference material in a Wikipedia-style. All of the links are listed at the end of the document, so you can maintain full separation between content and its source or reference.

## Full HTML

Perhaps the best part of Markdown is that you're never limited to just Markdown. You can write HTML directly in the Markdown editor and it will just work as HTML usually does. No limits! Here's a standard YouTube embed code as an example:

<p><iframe style="width:100%;" height="315" src="https://www.youtube.com/embed/Cniqsc9QfDo?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe></p>