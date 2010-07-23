What this library is about
==========================

The idea behind this library is to provide a clean way of writing
scripts for WeeChat, giving the programmer the usual Ruby experience.

While WeeChat already provides an extensive API which allows to modify
and control many parts of the client, that API is only providing the
plain C functions, making it very unintuitive for Ruby users (or
actually every other scripting/programming language, too). That also
means that writing Ruby scripts usually comes with a lot of repetitive
tasks, like converting C booleans to Ruby, handling string
representations of C pointers or having to free objects. Also the
approach of simply exposing the C API leaves us with absolutely no
object orientation.

And that's what this library is supposed to check. About every
function is wrapped into classes, conversions are done under the hood
and writing scripts in general becomes way more intuitive. No more
pointers or callbacks in the form of strings, no more freeing of
objects and a more appealing interface in general.


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


Writing scripts
===============

Initializing
------------

A common practice when writing scripts for WeeChat is to have a bunch
of constants which contain script name, description and so on. Those
constants then will be used in the weechat_init and weechat_register
functions.

This library is taking it a step further, expecting the user to create
a hash called `@script` with those information (where missing
information will be filled with default values by the library). An
included weechat_init method will then automatically use that hash to
register the script. After that, it will, if existing, call the
`setup` method defined by the script writer, in which one can do
additional things when loading the script, like creating commands.

A similar hook, `teardown`, will be called when the script is
unloaded.

    require 'weechat'
    include Weechat

    @script = {
      :name => "testscript",                           # must not be empty
      :author => "Dominik Honnef <dominikho@gmx.net>", # defaults to "Anonymous"
      :version => "0.0.1",                             # defaults to "0.0.1"
      :license => 'GPL3',                              # defaults to "unlicensed"
      :gem_version => '0.0.1',                         # defaults to "0.0.1" and specifies the
                                                       # the minimum required version of the gem
      :description => "this serves as a test suite and example file for the weechat gem",
      # defaults to "Empty script description
    }

    def setup
      # do custom stuff when the script is being loaded
    end

    def teardown
      # do custom stuff when the script is being unloaded
    end

Commands
--------

* String#split_shell
* Hash
* Two arguments

Configs
-------

We provide an abstraction around plugin specific configs, including
automatic typecasting and default values, getting and setting of
values (also in place [see "Working with Properties"]).

While some objects like Strings, Arrays and Booleans can be converted
directly to and from a weechat config string, other objects can, too,
be stored in Weechat's per-plugin config system using YAML for the
internal representation. While this allows one to store any kind of
objects, it is more than unlikely that a user is willing to change
those settings using /set, so use those objects sparingly.

    # ...
    @config = Script::Config.new(
                                 'some_list'    => [Array, []],
                                 'some_boolean' => [Boolean, true],
                                 'some_color'   => [Color, 'red'],
                                )
    def setup
      @config.some_list # returns an array (either [] if the option
                        # is not set yet or whatever has been set by the user)

      @config.some_list << "new item" # automatically converts the new array
                                      # to a string and store it in the config
    end

### Implementing own objects

If you want to implement your own conversion for objects (instead of
using YAML), define an instance method `to_weechat_config` and a class
method `from_weechat_config(value)` on the class of your object.

### Own configuration files

Currently there are no plans on implementing the more general
configurations.

Return values
-------------

While the original API expects you to return constants denoting
success/failure, this library expects you to raise certain exceptions.
The idea behind this is that the original constants had the values `0`,
`1` and `-1`; values which might well be implicitly returned by any ruby
code that was executed last in a callback. A raised exception, on the
other side, is unambiguous. Those exceptions live in the
{Weechat::Exception} namespace and got the same name as the old
constants.


Updating the gem
================

The easiest way of updating the gem is to run `gem update weechat` and
then, in WeeChat, `/upgrade`.

Asynchronous calls
==================

Due to the nature of IRC, some information cannot be requested
synchronously, e.g. those that /whois returns. In order to use them,
one has to use callbacks (not to be confused with WeeChat callbacks),
which will get called as soon as the requested information are
available.

    user.real_name do |rn|
      # this will get called as soon as the real_name is available.
      # rn will contain the requested information
    end

Information like a user's real name are internally requested and
handled using the {Weechat::IRC::Whois} class, which can be accessed
using {Weechat::IRC::User#whois}, in the same fashion a single property can be requested:

    user.whois do |whois|
      # one can either rely on Whois#method_missing ...
      whois.real_name

      # or access the data hash directly
      whois.data # => {:real_name => "...", ...}
    end


Contributing to the project
===========================

In case you want to contribute to this lovely project: Don't worry,
you will have plenty of chances for doing so!

Sending me gifts
----------------

While sending me gifts won't fix any bugs or add any new features, it
will postively affect my mood, and some people say that good temper
equals many bugfixes, so give it a try!

I accept things like new hardware, gadgets, beer, women, plain money
and whatever else you can think of. But please DO NOT send me your
first born child, even if you really want to, thanks.

Reporting bugs / requesting features
-------------------------------------

In case you found a bug in my
library or miss an important feature, feel free to
[create a ticket][issues].

Contributing code
-----------------

Do you belong to those that don't want to only report bugs but who
also fix them on your own? Great! Fork my repository at github, create
a feature branch, do your stuff and then send me a pull request. If
your code does what it is supposed to do, I will merge in your
changes.

Write documentation
-------------------

While this library provides a basic documentation, it lacks examples
and guides. I would really appreciate enhancements.

Telling me how great I am
-------------------------
No, really, feel free to tell me.

[issues]: http://github.com/dominikh/weechat-ruby/issues
[weechat_doc]: http://www.weechat.org/files/doc/stable/weechat_plugin_api.en.html
