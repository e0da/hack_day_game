hack_day_game
=============

Compile
-------

To compile the scripts once

    cake build

To continuously recompile the scripts as they change

    cake watch

Test Server
-----------

Run `./serve.sh`. It uses Ruby core libs, so no gems are needed. Or do any other
local web server you like, such as `python -m SimpleHTTPServer 8000` or `python
-m http.server 8000` or any of [these][Big list of http static server one-liners].

Codes
-----

Check `src/egg.coffee` for a complete list of codes as `event.keyCode`s, but
here's a list of the ones I have so far:

* A B A C A B B
* &uarr; &uarr; &darr; &darr; &larr; &rarr; &larr; &rarr; B A

[Big list of http static server one-liners]: https://gist.github.com/willurd/5720255
