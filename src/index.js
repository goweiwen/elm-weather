
'use strict';

require('../node_modules/milligram/dist/milligram.min.css')
require('../static/index.html')

var Elm = require('./Main.elm')
var app = Elm.Main.fullscreen()

app.ports.title.subscribe(function(title) { document.title = title })
