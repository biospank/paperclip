var Page = function() {
  this.info = {};
  var x = document.location.search.substring(1).split('&');
  for (var i in x) {
    var z = x[i].split('=',2);
    this.info[z[0]] = unescape(z[1]);
  }
}

Page.prototype.numbered = function() {
  $('span#page').text(this.info.page || 1);
  $('span#page-count').text(this.info.topage || 1);
}

Page.prototype.headerRepeat = function() {
  if((this.info.page || 1) == '1') {
    //$('table#head').before('<br />')
    $('table#head').hide();
  } else {
    $('table#head').show();
  }
}

Page.prototype.footerOnLastPage = function() {
  if(this.info.page == this.info.topage) {
    $('div#segue').hide();
    $('div#totali').show();
  } else {
    $('div#totali').hide();
    $('div#segue').show();
  }
}