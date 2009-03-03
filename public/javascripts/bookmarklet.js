var Mocra = Mocra || {};
(function($){ 
  Mocra.Url = Mocra.Url || {};
  Mocra.Url.Bookmark = function() {
    // init could fetch additional .js assets
    // ultimately run() should be called
    this.init = function() {
      this.run();
    };
    
    this.run = function() {
      $(document).ready(function() {
        $('body').append($("<div id='mocra-url-bookmark'>" +
        " bookmarklet" +
        "</div>"))
      });
      
    };
  };

  if (Mocra.env != "test") {
    document.mocra_url_bookmark = new Mocra.Url.Bookmark();
    document.mocra_url_bookmark.init();
  }
})(jQuery); 

