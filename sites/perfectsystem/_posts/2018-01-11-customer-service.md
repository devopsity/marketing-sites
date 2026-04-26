---
layout: post
title:  "Inception Movie"
author: john
categories: [ Jekyll, tutorial ]
tags: [red, yellow]
image: assets/images/11.jpg
description: "My review of Inception movie. Acting, plot and something else in this short description."
featured: true
hidden: true
rating: 4.5
summary: "A review of the movie Inception, covering acting, plot, and overall quality. The post also demonstrates how to use the review rating feature in Jekyll with Mediumish theme by adding a rating field to the YAML front matter."
faq:
  - q: "How do I add a review rating to a Jekyll post?"
    a: "Add a 'rating' field to your YAML front matter with a value between 0 and 5. Half values like 4.5 are supported. The Mediumish theme will automatically render star ratings."
definitions:
  - term: "YAML Front Matter"
    definition: "A block of metadata at the top of a Jekyll markdown file, enclosed between triple dashes (---), used to set variables like layout, title, and custom fields such as ratings."
sources:
  - url: "https://jekyllrb.com/docs/front-matter/"
    title: "Jekyll Front Matter Documentation"
---

Review products, books, movies, restaurant and anything you like on your Jekyll blog with Mediumish! JSON-LD ready for review property.

#### How to use?

It's actually really simple! Add the rating in your YAML front matter. It also supports halfs:

```html
---
layout: post
title:  "Inception Movie"
author: john
categories: [ Jekyll, tutorial ]
tags: [red, yellow]
image: assets/images/11.jpg
description: "My review of Inception movie. Actors, directing and more."
rating: 4.5
---
```
