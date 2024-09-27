# Helper

Helper is a Mudlet package to provide help text parsing via tags. It is
inspired by the help system in the [generic_mapper](https://github.com/Mudlet/Mudlet/blob/development/src/mudlet-lua/lua/generic-mapper/generic_mapper.xml)
package that comes with Mudlet.

This package is meant to accompany your own packages to provide help text for
commands, triggers, and whatever else you can think of.

## Usage
To use Helper, all you need is to have it installed as a package, or,
alternatively, you can just copy the `Helper.lua` file into your own package.

The function to call to use Helper is:

```lua
helper.print({text = "Your text"[, styles = {h1 = "chartreuse", h2 = "blue"}]})
```

It accepts two arguments:

- `text` - The text to parse for help tags.
- `styles` - A table of styles to use for the help text.

### Styles

The `styles` parameter is optional. If not provided, the default styles will be
used. Passing styles will merge your custom styles with the defaults,
overriding existing styles and adding new ones.

By default, Helper has the following styles defined:

```lua
local defaultStyles = {
  h1 = "red",
  h2 = "blue",
  h3 = "yellow",
  h4 = "green",
  h5 = "magenta",
  h6 = "cyan",
}
```

The values for the colours are those which are supported as part of Mudlet's
[colour table](https://wiki.mudlet.org/images/c/c3/ShowColors.png)
which works with the [`cecho()`](https://wiki.mudlet.org/w/Manual:Lua_Functions#cecho)
function that is used to display the text.

### Text

The text can contain tags which are similar in appearance to those in HTML,
including those which are recognised by the [`cecho()`](https://wiki.mudlet.org/w/Manual:Lua_Functions#cecho)
function, as well as the `<reset>` tag.

A basic example of the text parameter might look like:

```lua
local my_styles = {
  h1 = "chartreuse",
  danger = "orange_red",
}
helper.print({
  text =
"<danger><u>Warning</u></danger>\n" ..
"This is a <h1>test</h1> of the emergency text system. Contact your local\n" ..
"kitten for some comfort.",
  styles = my_styles,
})
```

### Function tags

Helper supports the use of tags which can derive text as return values from
functions.

A tag is defined by using the `@` symbol followed by the name of the function
which will be called to provide the text for that tag. For example:

Using a function to provide the text for a tag:

```lua
helper.print({text = "The current version of this package is <b><@version></b>."})

function version()
  return helper._VERSION
end
```

Using a method to provide the URL for a link:

```lua
helper.print({text = "You can download the latest version of this package "
                     "from <@MyPackage:url>."})

function MyPackage:url()
  return self._URL
end
```

The function must be defined and accessible by the Helper module.

## Support

While there is no official support and this is a hobby project, you are welcome
to report issues on the [GitHub repo](https://github.com/gesslar/Helper/issues).

## Credits

[Question icons created by Roundicons - Flaticon](https://www.flaticon.com/free-icons/question)
