function setAsSeenOn(id, text, from_user) {
  $("#as-seen-on-" + id).append("<p><a href='http://twitter.com/" + from_user + "'>" + from_user + "</a>: " + text + "</p>");
}

function twitterCallback(data) {
  var id = data.query.replace(/u.mocra.com%2F(.*)$/, '$1');
  if (data.results.length > 0) {
    $('#as-seen-on-' + id).show();
  }
  for (var i=0; i < data.results.length; i++) {
    var result = data.results[i];
    setAsSeenOn(id, result.text, result.from_user);
  }
}
