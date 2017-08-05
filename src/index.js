
'use strict';

require('../node_modules/milligram/dist/milligram.min.css')
require('../static/index.html')

var Elm = require('./Main.elm')
var root = document.getElementById('root')
var app = Elm.Main.embed(root)
