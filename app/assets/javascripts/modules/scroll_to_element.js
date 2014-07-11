/*
  Scrolls window to the top of an element on page load
*/
(function(Modules) {
  "use strict";
  Modules.ScrollToElement = function() {
    var that = this;
    that.start = function(element) {
      $(window).scrollTop(element.offset().top);
    }
  };
})(window.GOVUKAdmin.Modules);
