define(function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextMode = require("./text").Mode;

var DenrimHighlightRules = require("./denrim_highlight_rules").DenrimHighlightRules;
var FoldMode = require("./folding/cstyle").FoldMode;

var Mode = function() {
    this.HighlightRules = DenrimHighlightRules;
    this.foldingRules = new FoldMode();
    this.$behaviour = this.$defaultBehaviour;
};
oop.inherits(Mode, TextMode);

(function() {
    this.lineCommentStart = "#";
    this.$id = "ace/mode/denrim";
    this.snippetFileId = "ace/snippets/denrim";
}).call(Mode.prototype);

exports.Mode = Mode;
});
