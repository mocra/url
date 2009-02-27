function setAsSeenOn(id, text, from_user, tweet_id) {
  $("#as-seen-on-" + id).append("<p><a href='http://twitter.com/" + from_user + "'>" + from_user + "</a>: " + text + " <small><a href='http://twitter.com/" + from_user + "/statuses/" + tweet_id + "'>tweet</a></small></p>");
}

function twitterCallback(data) {
  for (var i=0; i < data.results.length; i++) {
    var result = data.results[i];
    findUrl = result.text.match(/u.mocra.com\/([^\s]+)\b/)
    if (findUrl) {
      console.log(findUrl);
      var id = findUrl[1];
      $('#as-seen-on-' + id).show();
      console.log("SHOWING for " + id)
      setAsSeenOn(id, result.text, result.from_user, result.id);
    }
  }
}
