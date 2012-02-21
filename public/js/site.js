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
      stackedGraph: gdiv.data('stack') ? true : false,
      drawPoints: true,
      labelsKMB: true,
      labelsDiv: 'label-'+gdiv.data('index'),
      labelsSeparateLines: true,
      legend: 'always',
      yValueFormatter: formatValue,
      highlightCallback: function(e, x, pts, row){
          var total = 0;
          $.each(pts,function(idx,val){
              total += val.yval;
          });
          if ( gdiv.data('stack') ) {
              $('#total-'+gdiv.data('index')).html('<em>TOTAL</em>:'+formatValue(total));
          }
      },
      unhighlightCallback: function(e) {
          $('#total-'+gdiv.data('index')).html('');
      }
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
              if ( param == 'path-data' ) {
                $(myform).find('[name="path-add"]').parents('div.controls').first().append(helpblock);
                $(myform).find('[name="path-add"]').parents('div.control-group').first().addClass('error');
              }
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

function addNewRow() {
    var tr = $('<tr></tr>');
    tr.append('<td><span class="table-order-pointer table-order-up">⬆</span><span class="table-order-pointer table-order-down">⬇</span></td>');
    tr.append('<td style="text-align:left">'+$('select[name="path-add"] option:selected').html()+'<input type="hidden" name="path-data" value="'+$('select[name="path-add"]').val()+'" /></td>');
    tr.append('<td style="text-align:center"><span class="table-order-remove">✖</span></td>');
    tr.appendTo($('table#data-tbl'));

    $('#data-tbl').find('tr:last').addClass('can-table-order');
    $('#data-tbl').find('span.table-order-up:last').click(tableOrderUp);
    $('#data-tbl').find('span.table-order-down:last').click(tableOrderDown);
    $('#data-tbl').find('span.table-order-remove:last').click(tableOrderRemove);

    var myform = $(this).parents('form').first();
    setTimeout(function(){tablePreview(myform)},10);

    return false;
};

function tableOrderUp() {
  var btn = this;
  var mytr = $(this).parents('tr.can-table-order').first();
  if ( mytr ) {
    var prevtr = mytr.prev('tr.can-table-order');
    mytr.insertBefore(prevtr);
  }
  var myform = $(this).parents('form').first();
  setTimeout(function(){tablePreview(myform)},10);
  return false;
}

function tableOrderDown() {
  var btn = this;
  var mytr = $(this).parents('tr.can-table-order').first();
  if ( mytr ) {
    var nexttr = mytr.next('tr.can-table-order');
    mytr.insertAfter(nexttr);
  }
  var myform = $(this).parents('form').first();
  setTimeout(function(){tablePreview(myform)},10);
  return false;
};

function tableOrderRemove() {
  var btn = this;
  var mytr = $(this).parents('tr.can-table-order').first();
  var myform = $(this).parents('form').first();
  setTimeout(function(){tablePreview(myform)},10);
  mytr.detach();
};

function tablePreview(myform) {
  var num = myform.find('input[name="path-data"]').length;
  var uri = $('#complex-preview').data('base');
  var data = new Array();
  myform.find('input[name="path-data"]').each(function(){ data.push($(this).val()) });
  uri += data.join(':');
  uri += '?stack=' + myform.find('select[name="stack"]').val();
console.log(uri);
  $('#complex-preview').attr('src',uri);
};

function setTablePreview() {
    var myform = $(this);
    $('#data-tbl').find('span.table-order-up').click(tableOrderUp);
    $('#data-tbl').find('span.table-order-down').click(tableOrderDown);
    $('#data-tbl').find('span.table-order-remove').click(tableOrderRemove);
    tablePreview(myform);
    myform.find('select[name="stack"]').change(
      function() {
        setTimeout(function(){ tablePreview(myform) }, 10)
      }
    );
};
