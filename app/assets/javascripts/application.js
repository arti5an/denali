//= require ./vendors/picturefill
//= require ./vendors/loadcss
//= require ./vendors/salvattore
//= require turbolinks
//= require_tree ./application

'use strict';

// I'm loading scripts async, so if the page has finished loading then
// I need to init these scripts directly, because the `page:change`
// event has already fired.
if (document.readyState !== 'loading') {
  Denali.SocialShare.init();
  Denali.Shortcuts.init();
  Denali.ImageZoom.init();
  Denali.Analytics.sendPageview();
  Denali.Grid.init();
  Denali.LazyLoad.loadImages();
}

// Attach event listeners
document.addEventListener('page:change', picturefill);
document.addEventListener('page:change', Denali.SocialShare.init);
document.addEventListener('page:change', Denali.Shortcuts.init);
document.addEventListener('page:change', Denali.ImageZoom.init);
document.addEventListener('page:change', Denali.Analytics.sendPageview);
document.addEventListener('page:change', Denali.Grid.init);
document.addEventListener('page:change', Denali.LazyLoad.loadImages);
document.addEventListener('orientationchange', Denali.ImageZoom.init);
document.addEventListener('keydown', Denali.Shortcuts.handleKeyPress);
document.addEventListener('scroll', Denali.LazyLoad.handleScroll);
window.addEventListener('resize', Denali.LazyLoad.handleScroll);
