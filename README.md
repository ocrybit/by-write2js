By-Write2JS
===========

A Bystander plugin to auto-write compiled code to JavaScript files.

Note, for now, it has to be used in conjunction with [by-coffeescript](http://tomoio.github.com/by-coffeescript/) plugin, and it only works with CoffeeScript-to-Javascript compiled code.

Installation
------------

To install **by-write2js**,

    sudo npm install -g by-write2js

Options
-------

> `bin` : true to map a `.bin.coffee` file to a no extension file. (e.g. `write2js.bin.coffee` to `write2.js`)  
> `binDir` : a directory to save  no extension bin files.  
> `mapper` : an array of key-value pairs to map CoffeeScript source files to output Javascript files. The key is a glob pattern, and the value is an array of arguments to pass to `replace()` method or a `function` that returns a bloolean value.  
> `noWrite` : an array of glob patterns for files to ignore.

By-Write2JS uses [minimatch](https://github.com/isaacs/minimatch) without `matchBase` option to match glob patterns.  

#### Examples

Saving compiled files from `src` directory into `lib` directory, and `.bin.coffee` files into `bin` directory while ignoring files under `ignore` directory.

    // .bystander config file
	.....
	.....
      "plugins" : ["by-coffeescript", "by-write2js"],
      "by" : {
        "write2js" : {
          "mapper" : ["**/src/*", [/src/i, "/lib/"]],
          "bin" : true,
          "binDir" : "./bin",
          "noWrite" : ["**/test/**"]
        }
      },
    .....
	.....

Note, `.coffee` will be automatically replaced with `.js`, and `binDir` will be resolved against the project root path, not the current working directory.

Broadcasted Events for further hacks
------------------------

> `wrote2js` : successfully wrote to the corresponding js file after a coffee `compiled` event  
> `write2js error` : failed to write to the js file  
> `unlink error` : failed to remove the given js file  
> `js removed` : removed the correspoding js file after a coffee `File removed` event  

See the [annotated source](docs/by-write2js.html) for details.

Running Tests
-------------

Run tests with [mocha](http://mochajs.org/)

    make
	
License
-------
**By-Write2js** is released under the **MIT License**. - see the [LICENSE](https://raw.github.com/tomoio/by-write2js/master/LICENSE) file

