define(['jquery'], function($) {
  return (function ($, undefined) {
    $.fn.getCursorPosition = function() {
      var el = $(this).get(0);
      var pos = 0;
      if('selectionStart' in el) {
        pos = el.selectionStart;
      } else if('selection' in document) {
        el.focus();
        var Sel = document.selection.createRange();
        var SelLength = document.selection.createRange().text.length;
        Sel.moveStart('character', -el.value.length);
        pos = Sel.text.length - SelLength;
      }
      return pos;
    }
    endOfWord = function(charVal) {
      return (typeof charVal === 'undefined' || charVal === "\n" || charVal === ' ')
    }
    replaceRange = function(s, start, end, substitute) {
      return s.substring(0, start) + substitute + s.substring(end);
    }
    String.prototype.replaceAtPos = function(startIdx, replaceWith) {
      return this.substring(0, startIdx) +
        replaceWith +
        this.substring(startIdx + replaceWith.length);
    }
    $.fn.moveToEndOf = function(selector) {
      return this.each(function() {
        var cl = $(this).clone();
        $(cl).appendTo(selector);
        $(this).remove();
      });
    }
    $.fn.moveToBeginningOf = function(selector) {
      return this.each(function() {
        var cl = $(this).clone();
        $(cl).prependTo(selector);
        $(this).remove();
      });
    }
    $.fn.getCurrentWordRange = function() {
      var el = $(this).get(0);
      var curPos = wordEndBound = $(el).getCursorPosition();
      var wordStartBound = 0;
      var textVal = $(el).val()

      // Are we at the end of the word?
      if (!endOfWord(textVal[curPos])) {
        // No, then find it
        while (curPos <= textVal.length) {
          curPos++;
          if (endOfWord(textVal[curPos])) {
            wordEndBound = curPos;
            break;
          }
        }
      }

      // Find the beginning of the current word
      while (curPos >= 0) {
        curPos--;
        if (curPos === 0 || textVal[curPos] === ' ') {
          wordStartBound = curPos;
          // Account for the space between words
          if (curPos > 0) {
            wordStartBound++;
          }
          break;
        }
      }
      return {start: wordStartBound, end: wordEndBound, value: textVal.substring(wordStartBound, wordEndBound)};
    }
  })(jQuery);
});
