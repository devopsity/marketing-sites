---
layout: post
title:  "Options for creating a new site with Jekyll"
author: john
categories: [ Jekyll, tutorial ]
image: assets/images/13.jpg
summary: "A guide to the different options available when creating a new Jekyll site using the jekyll new command. Covers flags like --force, --skip-bundle, and --blank, as well as how Bundler integrates with the site creation process."
faq:
  - q: "What does the jekyll new command do?"
    a: "The jekyll new command installs a new Jekyll site at the specified path, automatically running bundle install to set up dependencies. It uses the Minima gem-based theme by default."
  - q: "How do I create a blank Jekyll site without a theme?"
    a: "Use the --blank flag: jekyll new myblog --blank. This creates a minimal site structure without the default Minima theme."
definitions:
  - term: "Gem-Based Theme"
    definition: "A Jekyll theme packaged as a Ruby gem, where theme files like layouts and includes are stored in the gem rather than in the project directory, keeping the site structure clean and updatable."
sources:
  - url: "https://jekyllrb.com/docs/"
    title: "Jekyll Official Documentation"
---

`jekyll new <PATH>` installs a new Jekyll site at the path specified (relative to current directory). In this case, Jekyll will be installed in a directory called `myblog`. Here are some additional details:

- To install the Jekyll site into the directory you're currently in, run `jekyll new` . If the existing directory isn't empty, you can pass the --force option with jekyll new . --force.
- `jekyll new` automatically initiates `bundle install` to install the dependencies required. (If you don't want Bundler to install the gems, use `jekyll new myblog --skip-bundle`.)
- By default, the Jekyll site installed by `jekyll new` uses a gem-based theme called Minima. With gem-based themes, some of the directories and files are stored in the theme-gem, hidden from your immediate view.
- We recommend setting up Jekyll with a gem-based theme but if you want to start with a blank slate, use `jekyll new myblog --blank`
- To learn about other parameters you can include with `jekyll new`, type `jekyll new --help`.