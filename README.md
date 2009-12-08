Working with properties
=======================

The WeeChat API has multiple means of returning and setting properties.
On the one side, some properties of windows and buffers are exposed by
(window|buffer)\_get\_(string|integer) methods, but on the other side
some properties are also only available through infolists. Both ways
of receiving properties got the downside of returning C'ish values (0
for false, 1 for true, "" for nil/empty arrays).

Setting properties is even more unnatural to Ruby programmers, because
it always expects string arguments, again C'ish values ("0" for false
and so on) and sometimes the setter methods are even used for invoking
actions, like moving a buffer or resetting the read marker.

Because of this, the WeeChat gem provides an abstractional layer
around the whole concept of properties, exposing all properties as
instance attributes (that is, as getter and setter methods), providing
methods for actions like resetting the read marker, and applying
transformations to turn C'ish values into real Ruby classes and vice
versa. Also, while using the traditional API only returned duplicates
of values, the abstractional layer returns references to objects. That
means, if two variables point to the same property, none of them will
be outdated if the other one is being changed in place.

    buffer = Weechat::Buffer.current
    buffer.highlight_words = ["word1", "word2"]
    buffer.highlight_words # => ["word1", "word2"]

    buffer = Weechat::Buffer.all.last
    buffer.lines_hidden? # => false
    buffer.show          # displays the buffer in the current window

    buffer = Weechat::Buffer.current
    a = buffer.short_name # => "weechat"
    b = buffer.short_name # => "weechat"
    a.replace("new name") # => "new name"
    buffer.short_name     # => "new name"
    b                     # => "new name"

References, however, won't be updated once an assignment was made
to the property, just like with real Ruby objects:

    buffer = Weechat::Buffer.current
    a = buffer.short_name          # => "weechat"
    buffer.short_name = "new name" # => "new name"
    a                              # => "weechat"

Programatically accessing properties
------------------------------------

If you have to access properties in a metaprogrammed fashion but do
not want to use the low level methods, feel free to use
{Weechat::Properties::InstanceMethods#get_property} and
{Weechat::Properties::InstanceMethods#set_property}, which provide all
of the added functionality mentioned above (note, however, that
properties returning true/false won't have an appended question mark
to their name if using
{Weechat::Properties::InstanceMethods#get_property #get_property} and
{Weechat::Properties::InstanceMethods#set_property #set_property}.

Note regarding the documentation
--------------------------------

Because most getters and setters for properties are being generated
using metaprogramming, they won't show up in the attribute or method
lists in the documentation. Instead you can find a list of those
properties and their return values in the introductional description
of each class (if suitable).

Low level access
----------------

The WeeChat gem provides several methods for low level access to
properties (which are still better than directly using the WeeChat
API), in varying degress. Using those, however, should never be
necessary nor should it give any advantages over the abstractional
layer. If you ever get into a situation where you have to use the low
level API, please [inform me][issues], providing a sample of what you
are doing and your intentions and I will try to update the layer.

If you, for whatever reason, feel attached to the low level API
though, please consult the [official API documentation][weechat_doc] regarding
property names and {Weechat::Properties} regarding available methods.


Buffers
=======

See {Weechat::Buffer}


Windows
=======

See {Weechat::Window}


Infolists
=========

Infolists do represent a lower level aspect, are an exception to the
general "you shouldn't use the low level calls" though, as it might be
necessary to use them directly from time to time.

See {Weechat::Infolist}

Sorted lists
============

While the WeeChat API exposes a few functions for creating and working
with sorted lists, I've decided not to implement any of those because
Ruby provides own means of lists. If you think this is a missing
feature, [inform me][issues] and I might add them to the library.

[issues]: http://github.com/dominikh/weechat-ruby/issues
[weechat_doc]: http://www.weechat.org/files/doc/stable/weechat_plugin_api.en.html
