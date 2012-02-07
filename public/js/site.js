var suffixes = ['', 'k', 'M', 'G', 'T'];
function round(num, places) {
  var shift = Math.pow(10, places);
  return Math.round(num * shift)/shift;
};
function formatValue(v) {
  if (v < 1000) return v;
  var magnitude = Math.floor(String(Math.floor(v)).length / 3);
  if (magnitude > suffixes.length - 1)
    magnitude = suffixes.length - 1;
  return String(round(v / Math.pow(10, magnitude * 3), 2)) +
    suffixes[magnitude];
}
function loadGraphs () {
  var gdiv = $(this);
  g = new Dygraph(
    gdiv.context,
    gdiv.data('csv'),
    {
      includeZero: true,
      dateWindow: [ Date.parse(gdiv.data('datewindow')[0]),Date.parse(gdiv.data('datewindow')[1]) ],
      colors: gdiv.data('colors'),
      stackedGraph: true,
      drawPoints: true,
      labelsKMB: true,
      yValueFormatter: formatValue,
    }
  );
};
function setHxrpost() {
  var myform = this;
  $(myform).first().prepend('<div class="alert alert-error hide">System Error!</div>');
  $(myform).submit(function(){
    $(myform).find('.alert-error').hide();
    $(myform).find('.validator_message').detach();
    $(myform).find('.control-group').removeClass('error');
    $.ajax({
      type: 'POST',
      url: myform.action,
      data: $(myform).serialize(),
      success: function(data) {
        $(myform).find('.alert-error').hide();
        if ( data.error == 0 ) {
            location.href = data.location;
        }
        else {
            $.each(data.messages, function (param,message) {
              var helpblock = $('<p class="validator_message help-block"></p>');
              helpblock.text(message);
              $(myform).find('[name="'+param+'"]').parents('div.controls').first().append(helpblock);
              $(myform).find('[name="'+param+'"]').parents('div.control-group').first().addClass('error');
            });
        }
      },
      error: function() {
        $(myform).find('.alert-error').show();
      }
    });
    return false;
  });
};

function setHxrConfirmBtn() {
  var mybtn = this;
  var modal = $('<div class="modal fade">'+
'<form method="post" action="#">'+
'<div class="modal-header"><h3>confirm</h3></div>'+
'<div class="modal-body"><div class="alert alert-error hide">System Error!</div><p>confirm</p></div>'+
'<div class="modal-footer"><input type="submit" class="btn btn-danger" value="confirm" /></div>'+
'</form></div>');
  modal.find('h3').text($(mybtn).text());
  modal.find('input[type=submit]').attr('value',$(mybtn).text());
  modal.find('.modal-body > p').text( $(mybtn).data('confirm') );
  modal.find('form').submit(function(){
    $.ajax({
      type: 'POST',
      url: $(mybtn).data('uri'),
      data: modal.find('form').serialize(),
      success: function(data) {
        modal.find('.alert-error').hide();
        if ( data.error == 0 ) {
          location.href = data.location;
        }
      },
      error: function() {
        modal.find('.alert-error').show();
      }
    });
    return false;
  });
  $(mybtn).click(function(){
    modal.modal({
      show: true,
    });
  });
};
