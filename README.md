# markdown-link

A lua neovim plugin, that helps to create links in markdown documents.

## Features

In markdown, links can be made in two ways:

```md
[See here](https://link.to/target)
```

or

```md
[See here][1]

[1]: https://link.to/target
```

The advantage of the second method is that you have your links all together at
the bottom of the page, that long links don't interrupt the raw markdown, and
that multiple links to the same target only have to be defined once.

Downside is that, when editing, it's a lot of work to insert them, update them, find the right number.

The `markdown-link` plugin will, when you want to create a link in your markdown document, insert the link though the second method.
It will also check if the link was already used before, and reuse the number if so.

## Installation

Using `lazy.vim` package manager:

```lua
return {
  "reinhrst/markdown-link",
  opts = true,
  ft = "markdown",
  config = function(opts)
    local markdownLink = require "markdown-link"
    markdownLink.setup(opts)
    vim.keymap.set({ "n", "v", "i" }, "<C-T>", markdownLink.PasteMarkdownLink, { desc = "Paste Markdown Link" })
  end,
}
```

Note that by default no key bindings are made, so you have to ensure that you bind it.

## Usage

Open a markdown document, copy a URL from some place, and use start typing:

```md
This is [a link]
```

Afterwards press <kbd><kbd>Ctrl</kbd>+<kbd>t</kbd></kbd> and `markdown-link` will do the work for you:

```md
This is [a link][1]

[1]: https://your.url/....
```

- In `normal` and `input` mode, the function expects to find a `]` character under or just before the cursor.
- In `visual` mode, the selected section will be surrounded with `[` and `]`

After this, the link will be made.
