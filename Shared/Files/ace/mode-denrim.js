define("ace/mode/denrim_highlight_rules",["require","exports","module","ace/lib/oop","ace/mode/text_highlight_rules"],function(e,t,n){"use strict";var r=e("../lib/oop"),i=e("./text_highlight_rules").TextHighlightRules,s=function(){this.$rules={start:[{token:"constant.numeric",regex:"(\\b(sequence|tree|repeat|selector)\\b)"},{token:"constant.numeric",regex:"(^[ ]*[a-zA-Z0-9_]+[ ]*(?==)[ ]*)"},{token:"keyword",regex:"(\\b[a-z][a-z0-9]*)"},{token:"comment",regex:"(\\b(Group|Index|Rect|Id|RepeatX|Range|Layers|Platform|Size|Name|Shapes|Position|Float|Shaders|Float2|Float3|Float4|From|To|Minimum|Maximum|Key|SceneOffset|Mode|Variables|Variable|With|Text|Type|Color|Font|FontSize|Digits|Int|Variable|Variables|Tree|Bool|not|BehaviorId|ShapeId|PhysicsId|Gravity|Scale)\\b)"},{token:"keyword",regex:"(\\b(\\.|Shape2D|GridInstance2D|Physics2D|ApplyPhysics2D|ApplyTexture2D)\\b)"},{token:"comment",regex:"(\\b(Onion|Round|Radius|BorderColor|Border)\\b)"},{token:"keyword",regex:"([a-zA-Z]+)"},{token:"constant.numeric",regex:"(-*\\b\\d+\\.*\\d*)"},{token:"punctuation",regex:"(\\<)",push:"main__1"},{token:"punctuation",regex:"(^:[ ]*.*)"},{token:"punctuation",regex:"(:)"},{token:"punctuation",regex:"(,)"},{token:"punctuation",regex:"(=)"},{token:"punctuation",regex:'(\\")',push:"main__2"},{token:"punctuation",regex:"(\\()",push:"main__3"},{token:"comment",regex:"(#.*)"},{token:"invalid",regex:"([^\\s])"},{defaultToken:"text"}],main__1:[{token:"punctuation",regex:"(\\>)",next:"pop"},{token:"constant.numeric",regex:"(\\b(sequence|tree|repeat|selector)\\b)"},{token:"constant.numeric",regex:"(^[ ]*[a-zA-Z0-9_]+[ ]*(?==)[ ]*)"},{token:"keyword",regex:"(\\b[a-z][a-z0-9]*)"},{token:"comment",regex:"(\\b(Group|Index|Rect|Id|RepeatX|Range|Layers|Platform|Size|Name|Shapes|Position|Float|Shaders|Float2|Float3|Float4|From|To|Minimum|Maximum|Key|SceneOffset|Mode|Variables|Variable|With|Text|Type|Color|Font|FontSize|Digits|Int|Variable|Variables|Tree|Bool|not|BehaviorId|ShapeId|PhysicsId|Gravity|Scale)\\b)"},{token:"keyword",regex:"(\\b(\\.|Shape2D|GridInstance2D|Physics2D|ApplyPhysics2D|ApplyTexture2D)\\b)"},{token:"comment",regex:"(\\b(Onion|Round|Radius|BorderColor|Border)\\b)"},{token:"keyword",regex:"([a-zA-Z]+)"},{token:"constant.numeric",regex:"(-*\\b\\d+\\.*\\d*)"},{token:"punctuation",regex:"(\\<)",push:"main__1"},{token:"punctuation",regex:"(^:[ ]*.*)"},{token:"punctuation",regex:"(:)"},{token:"punctuation",regex:"(,)"},{token:"punctuation",regex:"(=)"},{token:"punctuation",regex:'(\\")',push:"main__2"},{token:"punctuation",regex:"(\\()",push:"main__3"},{token:"comment",regex:"(#.*)"},{token:"invalid",regex:"([^\\s])"},{defaultToken:"text"}],main__2:[{token:"punctuation",regex:'(\\")',next:"pop"},{defaultToken:"text"}],main__3:[{token:"punctuation",regex:"(\\))",next:"pop"},{token:"constant.numeric",regex:"(-*\\b\\d+\\.*\\d*)"},{token:"punctuation",regex:"(,)"},{defaultToken:"text"}]},this.normalizeRules()};r.inherits(s,i),t.DenrimHighlightRules=s}),define("ace/mode/folding/cstyle",["require","exports","module","ace/lib/oop","ace/range","ace/mode/folding/fold_mode"],function(e,t,n){"use strict";var r=e("../../lib/oop"),i=e("../../range").Range,s=e("./fold_mode").FoldMode,o=t.FoldMode=function(e){e&&(this.foldingStartMarker=new RegExp(this.foldingStartMarker.source.replace(/\|[^|]*?$/,"|"+e.start)),this.foldingStopMarker=new RegExp(this.foldingStopMarker.source.replace(/\|[^|]*?$/,"|"+e.end)))};r.inherits(o,s),function(){this.foldingStartMarker=/([\{\[\(])[^\}\]\)]*$|^\s*(\/\*)/,this.foldingStopMarker=/^[^\[\{\(]*([\}\]\)])|^[\s\*]*(\*\/)/,this.singleLineBlockCommentRe=/^\s*(\/\*).*\*\/\s*$/,this.tripleStarBlockCommentRe=/^\s*(\/\*\*\*).*\*\/\s*$/,this.startRegionRe=/^\s*(\/\*|\/\/)#?region\b/,this._getFoldWidgetBase=this.getFoldWidget,this.getFoldWidget=function(e,t,n){var r=e.getLine(n);if(this.singleLineBlockCommentRe.test(r)&&!this.startRegionRe.test(r)&&!this.tripleStarBlockCommentRe.test(r))return"";var i=this._getFoldWidgetBase(e,t,n);return!i&&this.startRegionRe.test(r)?"start":i},this.getFoldWidgetRange=function(e,t,n,r){var i=e.getLine(n);if(this.startRegionRe.test(i))return this.getCommentRegionBlock(e,i,n);var s=i.match(this.foldingStartMarker);if(s){var o=s.index;if(s[1])return this.openingBracketBlock(e,s[1],n,o);var u=e.getCommentFoldRange(n,o+s[0].length,1);return u&&!u.isMultiLine()&&(r?u=this.getSectionRange(e,n):t!="all"&&(u=null)),u}if(t==="markbegin")return;var s=i.match(this.foldingStopMarker);if(s){var o=s.index+s[0].length;return s[1]?this.closingBracketBlock(e,s[1],n,o):e.getCommentFoldRange(n,o,-1)}},this.getSectionRange=function(e,t){var n=e.getLine(t),r=n.search(/\S/),s=t,o=n.length;t+=1;var u=t,a=e.getLength();while(++t<a){n=e.getLine(t);var f=n.search(/\S/);if(f===-1)continue;if(r>f)break;var l=this.getFoldWidgetRange(e,"all",t);if(l){if(l.start.row<=s)break;if(l.isMultiLine())t=l.end.row;else if(r==f)break}u=t}return new i(s,o,u,e.getLine(u).length)},this.getCommentRegionBlock=function(e,t,n){var r=t.search(/\s*$/),s=e.getLength(),o=n,u=/^\s*(?:\/\*|\/\/|--)#?(end)?region\b/,a=1;while(++n<s){t=e.getLine(n);var f=u.exec(t);if(!f)continue;f[1]?a--:a++;if(!a)break}var l=n;if(l>o)return new i(o,r,l,t.length)}}.call(o.prototype)}),define("ace/mode/denrim",["require","exports","module","ace/lib/oop","ace/mode/text","ace/mode/denrim_highlight_rules","ace/mode/folding/cstyle"],function(e,t,n){"use strict";var r=e("../lib/oop"),i=e("./text").Mode,s=e("./denrim_highlight_rules").DenrimHighlightRules,o=e("./folding/cstyle").FoldMode,u=function(){this.HighlightRules=s,this.foldingRules=new o,this.$behaviour=this.$defaultBehaviour};r.inherits(u,i),function(){this.lineCommentStart="#",this.$id="ace/mode/denrim",this.snippetFileId="ace/snippets/denrim"}.call(u.prototype),t.Mode=u});                (function() {
                    window.require(["ace/mode/denrim"], function(m) {
                        if (typeof module == "object" && typeof exports == "object" && module) {
                            module.exports = m;
                        }
                    });
                })();
            