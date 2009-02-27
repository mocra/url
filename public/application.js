function setAsSeenOn(id, text, from_user, tweet_id) {
  $("#as-seen-on-" + id).append("<p><a href='http://twitter.com/" + from_user + "'>" + from_user + "</a>: " + text + " <small><a href='http://twitter.com/" + from_user + "/statuses/" + tweet_id + "'>tweet</a></small></p>");
}

function twitterCallback(data) {
  for (var i=0; i < data.results.length; i++) {
    var result = data.results[i];
    findUrl = result.text.match(/u.mocra.com\/([^\s]+)\b/);
    if (findUrl) {
      var id = findUrl[1];
      $('#as-seen-on-' + id).show();
      setAsSeenOn(id, result.text, result.from_user, result.id);
    }
  }
}

(function($){ 
  $(document).ready(function() {
    $('a.original-url').each(shortenUrl).hover(fullLengthUrl, shortenUrl);
  });
})(jQuery); 

function shortenUrl(index) {
  var href = $(this).attr("href");
  if (href.length > 80) {
    $(this).html(href.substr(0, 60) + "...");
  }
};

function fullLengthUrl(index) {
  var href = $(this).attr("href");
  $(this).html(href);
}
