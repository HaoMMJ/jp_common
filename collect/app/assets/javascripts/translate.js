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

  function generate_translated_text(text, data){
    html = "<div>";
    translate_text = text;
    var words  = data.word_list;
    for(var i = 0; i < words.length; i++){
      var word = words[i];
      var origin = word.origin;
      translate_text = translate_text.replace(origin, "<span data='" + word.mean +"' style='background-color: red'>"+ origin +"</span>");
    }
    html += translate_text;
    html += "</div>";
    $("#traslation_result").html(html);
  }

  function translate(text){
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
    search_text = $(this).val();
    translate(search_text);
  });
});