$(function() {
  var anki_list = []
  function search_and_update_anki(word){
    var params = {};
    params.word = word;
    $.post( "/update_anki", params ).done(function( data ) {
      console.log(data.message);
      switch(data.message) {
        case "existed":
          //show message exist in dictionary
          console.log("Existed!!!");
          $('#anki_search_info').html('Existed!!!');
          break;
        case "not_found":
          console.log("Not found!!!");
          $('#anki_search_info').html('Not found!!!');
          break;
        case "updated":
          createAnkiVocabRow(data.word);
          break;
        case "missing_words":
          anki_list = data.words
          $("#anki_vocabulary_selection").html(generateAnkiSelection(anki_list));
          break;
      }
    });
  }

  function createAnkiVocabRow(result){
    var html = '<tr style="background-color: red;">';
    var row_number = $("#anki_dictionary_tbl tbody").children().length;
    html += '<td>' + row_number + '</td>';
    html += '<td>' + result.word + '</td>';
    html += '<td>' + result.reading + '</td>';
    html += '<td>' + result.kanji_meaning + '</td>';
    html += '<td>' + result.mazii_meaning + '</td>';
    html += '<td>' + result.jisho_meaning + '</td>';
    html += '<td>' + result.used_meaning + '</td>';
    html += '</tr>';

    $('#anki_dictionary_tbl tr:last').after(html);
    $('#anki_vocalbularies').scrollTop($('#anki_vocalbularies')[0].scrollHeight);
  }

  function generateAnkiSelection(word_list){
    var html = "<table>";
    for(var i = 0; i< word_list.length; i++){
      var result = word_list[i];
      html += "<tr>";
      html += '<td>' + result.kanji + '</td>';
      html += '<td>' + result.kana + '</td>';
      html += '<td>' + result.cn_mean + '</td>';
      html += '<td>' + result.mean + '</td>';
      html += '<td>' + result.level + '</td>';

      html += '<td><button onclick="window.updateAnkiVocab(' + i + ')" >Pick it!</button></td>';
      html += "<tr>";
    }
    html += "</table>";
    return html;
  }

  window.updateAnkiVocab = function(index){
    var params = {};
    var vocab = anki_list[index];
    params.vocab_id = vocab.id
    $.post( "/update_anki_vocab", params ).done(function( data ) {
      if(!!data.error_msg){
        alert(data.error_msg);
      }else{
        createAnkiVocabRow(data.result);
      }
      $('#anki_vocabulary_selection').empty();
    });
  }

  $("#anki_input").change(function(){
    search_word = $(this).val();
    $(this).val("");
    $('#anki_search_info').empty();
    console.log(search_word);
    search_and_update_anki(search_word);
  });
});