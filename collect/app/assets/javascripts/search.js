$(function() {
  function existed(data){
    return !!data.existed;
  }

  function not_found(data){
    return !!data.not_found;
  }

  function search_and_update(word){
    var params = {};
    params.id   = $('#dic_id').val();
    params.word = word;
    $.post( "/update_list", params ).done(function( data ) {
      if(existed(data)){
        //show message exist in dictionary
        console.log("Existed!!!");
        $('#search_info').html('Existed!!!');
      }else if(not_found(data)){
        console.log("Not found!!!");
        $('#search_info').html('Not found!!!');
      }else {
        refresh_list(data);
      }
    });
  }

  function refresh_list(data){
    var html = '<tr style="background-color: red;">';
    var result =  data.result;
    var row_number = $("#dictionary_tbl tbody").children().length;
    html += '<td>' + row_number + '</td>';
    html += '<td>' + result.kanji + '</td>';
    html += '<td>' + result.kana + '</td>';
    html += '<td>' + result.cn_mean + '</td>';
    html += '<td>' + result.mean + '</td>';
    html += '<td>' + result.level + '</td>';
    html += '</tr>';

    $('#dictionary_tbl tr:last').after(html);
    $('#vocalbularies').scrollTop($('#vocalbularies')[0].scrollHeight);
  }

  $("#search").change(function(){
    search_word = $(this).val();
    $(this).val("");

    console.log(search_word);
    search_and_update(search_word);
  });
});