

var Denali = Denali || {};

Denali.ImageZoom = (function ($) {
  'use strict';
  var opts = {
    $toggle          : $('.entry__photo-link'),
    zoomable_class  : 'entry__photo-link--zoomable',
    zoom_class      : 'entry__photo-link--fit'
  };

  var $window = $(window);
  var permalink = $('html[data-permalink]');

  var toggleZoom = function () {
    var $link = $(this);
    $link.toggleClass(opts.zoom_class);
    return false;
  };

  var init = function () {
    if (permalink.length === 0) { return; }

    opts.$toggle.each(function () {
      var $link = $(this);
      var width = parseInt($link.find('img').data('width'), 10);
      var height = parseInt($link.find('img').data('height'), 10);
      if (width <= $window.width() && height > $window.height()) {
       $link.addClass(opts.zoomable_class);
      }
    });
    $('.' + opts.zoomable_class).on('click', toggleZoom);
  };

  return {
    init : init
  };
})(jQuery);

Denali.ImageZoom.init();
