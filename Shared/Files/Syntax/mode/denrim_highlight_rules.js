/*
* To try in Ace editor, copy and paste into the mode creator
* here : http://ace.c9.io/tool/mode_creator.html
*/

define(function(require, exports, module) {
"use strict";
var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
/* --------------------- START ----------------------------- */
var DenrimHighlightRules = function() {
this.$rules = {
"start" : [
   {
      "token" : "constant.numeric",
      "regex" : "(^[a-zA-Z0-9_]+[ ]*=[ ]*)"
   },
   {
      "token" : "keyword",
      "regex" : "(\\b[a-z][a-z0-9]*)"
   },
   {
      "token" : "comment",
      "regex" : "(Group|Index|Rect|Id|RepeatX|Range|Layers|Platform|Size|Name|Shapes|Position|IsKeyDown|DrawBox)"
   },
   {
      "token" : "keyword",
      "regex" : "(Image|Alias|Layer|SceneOffset|Scene|Sequence|ScreenSize|Shape2D|Behavior|\\.|Key)"
   },
   {
      "token" : "comment",
      "regex" : "(Shape)"
   },
   {
      "token" : "constant.numeric",
      "regex" : "(-*\\b\\d+.*\\d*)"
   },
   {
      "token" : "punctuation",
      "regex" : "(\\<)",
      "push" : "main__1"
   },
   {
      "token" : "punctuation",
      "regex" : "(^:[ ]*.*)"
   },
   {
      "token" : "punctuation",
      "regex" : "(:)"
   },
   {
      "token" : "punctuation",
      "regex" : "(,)"
   },
   {
      "token" : "punctuation",
      "regex" : "(=)"
   },
   {
      "token" : "punctuation",
      "regex" : "(\\\")",
      "push" : "main__2"
   },
   {
      "token" : "punctuation",
      "regex" : "(\\()",
      "push" : "main__3"
   },
   {
      "token" : "comment",
      "regex" : "(#.*)"
   },
   {
      "token" : "invalid",
      "regex" : "([^\\s])"
   },
   {
      defaultToken : "text",
   }
],
"main__1" : [
   {
      "token" : "punctuation",
      "regex" : "(\\>)",
      "next" : "pop"
   },
   {
      "token" : "constant.numeric",
      "regex" : "(^[a-zA-Z0-9_]+[ ]*=[ ]*)"
   },
   {
      "token" : "keyword",
      "regex" : "(\\b[a-z][a-z0-9]*)"
   },
   {
      "token" : "comment",
      "regex" : "(Group|Index|Rect|Id|RepeatX|Range|Layers|Platform|Size|Name|Shapes|Position|IsKeyDown|DrawBox)"
   },
   {
      "token" : "keyword",
      "regex" : "(Image|Alias|Layer|SceneOffset|Scene|Sequence|ScreenSize|Shape2D|Behavior|\\.|Key)"
   },
   {
      "token" : "comment",
      "regex" : "(Shape)"
   },
   {
      "token" : "constant.numeric",
      "regex" : "(-*\\b\\d+.*\\d*)"
   },
   {
      "token" : "punctuation",
      "regex" : "(\\<)",
      "push" : "main__1"
   },
   {
      "token" : "punctuation",
      "regex" : "(^:[ ]*.*)"
   },
   {
      "token" : "punctuation",
      "regex" : "(:)"
   },
   {
      "token" : "punctuation",
      "regex" : "(,)"
   },
   {
      "token" : "punctuation",
      "regex" : "(=)"
   },
   {
      "token" : "punctuation",
      "regex" : "(\\\")",
      "push" : "main__2"
   },
   {
      "token" : "punctuation",
      "regex" : "(\\()",
      "push" : "main__3"
   },
   {
      "token" : "comment",
      "regex" : "(#.*)"
   },
   {
      "token" : "invalid",
      "regex" : "([^\\s])"
   },
   {
      defaultToken : "text",
   }
],
"main__2" : [
   {
      "token" : "punctuation",
      "regex" : "(\\\")",
      "next" : "pop"
   },
   {
      defaultToken : "text",
   }
],
"main__3" : [
   {
      "token" : "punctuation",
      "regex" : "(\\))",
      "next" : "pop"
   },
   {
      "token" : "constant.numeric",
      "regex" : "(-*\\b\\d+.*\\d*)"
   },
   {
      "token" : "punctuation",
      "regex" : "(,)"
   },
   {
      defaultToken : "text",
   }
]
};
this.normalizeRules();
};
/* ------------------------ END ------------------------------ */
oop.inherits(DenrimHighlightRules, TextHighlightRules);
exports.DenrimHighlightRules = DenrimHighlightRules;
});
