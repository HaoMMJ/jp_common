$(function() {
  function translate(text){
    console.log("Searching....")
    var params = {};
    params.search_text = search_text;
    $.post( "/auto_translate", params ).done(function( data ) {
      console.log("generate")
      var words  = data.word_list
      var result_table = "<table>";
      var row = ""
      for(var i = 0; i < words.length; i++){
        var word = words[i]
        row += "<tr>";  
        row += "<td>" + word.word + "</td>";
        row += "<td>" + word.kana + "</td>";
        row += "<td>" + word.cn_mean + "</td>";
        row += "<td>" + word.mean + "</td>";
        row += "</tr>";
      }
      result_table += row;
      result_table += "</table>"
      $("#traslation_result").html(result_table)
    });
  }

  $("#search_text").change(function(){
    console.log("Txt changed");
    search_text = $(this).val();
    translate(search_text);
  });
});