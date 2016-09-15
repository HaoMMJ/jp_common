$(function() {
  function translate(text){
    var params = {};
    params.search_text = search_text;
    $.post( "/auto_translate", params ).done(function( data ) {
      $("#traslation_result").html(data)
    });
  }

  $("#search_text").change(function(){
    search_text = $(this).val();
    translate(search_text);
  });
});