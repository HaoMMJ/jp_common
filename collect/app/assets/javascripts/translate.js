$(function() {
  function generate_word_list(data){
    var words  = data.word_list
    var result_table = "<table>";
    var row = ""
    for(var i = 0; i < words.length; i++){
      var word = words[i];
      row += "<tr>";  
      row += "<td>" + word.word + "</td>";
      row += "<td>" + word.kana + "</td>";
      row += "<td>" + word.cn_mean + "</td>";
      row += "<td>" + word.mean + "</td>";
      row += "</tr>";
    }
    result_table += row;
    result_table += "</table>"
    $("#traslation_result").html(result_table);
  }

  function extract_meaning(word, temp_replace_text){
    if(word.word){
      var replace_text = (word.word == word.origin) ? temp_replace_text : word.word;
      return replace_text + " (" + word.kana + ") [" + word.cn_mean + "] <br/>" + word.mean;
    }else if(word.kana){
      var replace_text = (word.kana == word.origin) ? temp_replace_text : word.kana;
      return replace_text + ": " + word.mean;
    }else{
      return "not found";
    }
  }

  function generate_translated_text(text, data){
    html = "<div>";
    translate_text = text;
    var words  = data.word_list;
    var text_replace_memo = [];
    for(var i = 0; i < words.length; i++){
      var word = words[i];
      var origin = word.origin;
      console.log(origin)
      // var temp_replace_text = "temp_" + i.toString().split('').join("_");
      var temp_replace_text = "temp_" + i + "_temp";
      var highlight_class = (!!word.word || !!word.kana) ? "highlight" : "not_found"
      var text_edition  = "<div class='tooltip " + highlight_class +" '>";
      text_edition     += temp_replace_text;
      text_edition     += "<span class='tooltiptext'>";
      text_edition     += extract_meaning(word, temp_replace_text);
      text_edition     +="</span></div>";

      text_replace_memo.push({temp_text: temp_replace_text, origin_text: origin});
      translate_text = translate_text.replaceAll(
        origin, 
        text_edition
      );
      translate_text = translate_text.replace(/\n/g, '<br/>')
    }
    for(var j = 0; j < text_replace_memo.length; j++){
      translate_text = translate_text.replaceAll(
        text_replace_memo[j].temp_text, 
        text_replace_memo[j].origin_text
      );
    }
    console.log(text_replace_memo);
    html += translate_text;
    html += "</div>";
    $("#traslation_result").html(html);
  }

  function translate(search_text){
    console.log("Searching....")
    var params = {};
    params.search_text = search_text;
    $.post( "/auto_translate", params ).done(function( data ) {
      console.log("generate")
      // generate_word_list(data);
      generate_translated_text(search_text,data)
    });
  }

  $("#search_text").change(function(){
    console.log("Txt changed");
    var search_text = $(this).val();
    translate(search_text);
  });
});