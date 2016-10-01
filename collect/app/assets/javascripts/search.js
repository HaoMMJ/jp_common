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

  var word_list = [];
  function refresh_list(data){
    word_list =  data.result;

    if(word_list.length == 1){
      result = word_list[0];
      createVocabRow(result);
    }else{
      $("#vocabulary_selection").html(generateSelection(word_list));
    }
  }

  function createVocabRow(result){
    var html = '<tr style="background-color: red;">';
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

  function generateSelection(word_list){
    var html = "<table>";
    var dic_id = $('#dic_id').val();
    for(var i = 0; i< word_list.length; i++){
      var result = word_list[i];
      html += "<tr>";
      html += '<td>' + result.kanji + '</td>';
      html += '<td>' + result.kana + '</td>';
      html += '<td>' + result.cn_mean + '</td>';
      html += '<td>' + result.mean + '</td>';
      html += '<td>' + result.level + '</td>';

      html += '<td><button onclick="window.updateDicVocab(' + i + ')" >Pick it!</button></td>';
      html += "<tr>";
    }
    html += "</table>";
    return html;
  }

  window.updateDicVocab = function(index){
    var params = {};
    params.dic_id = $('#dic_id').val();
    var vocab = word_list[index];
    params.vocab_id = vocab.id
    $.post( "/update_dic_vocab", params ).done(function( data ) {
      if(!!data.error_msg){
        alert(data.error_msg);
      }else{
        createVocabRow(vocab);
      }
    });
  }

  $("#search").change(function(){
    search_word = $(this).val();
    $(this).val("");

    console.log(search_word);
    search_and_update(search_word);
  });
});