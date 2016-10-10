var pic_real_width, pic_real_height;
$(function() {

	// Create variables (in this scope) to hold the API and image size
	var jcrop_api,
	    boundx,
	    boundy,
	    x_pos,
	    y_pos;

  $("<img/>").load(function(){
    pic_real_width = this.width,
    pic_real_height = this.height;
    console.log( 'W='+ pic_real_width +' H='+ pic_real_height);

    var viewPortWidth = $( window ).width();
    console.log(' viewPortWidth ' , viewPortWidth)
    // $("#target").width(viewPortWidth);
  }).attr("src", $("#target").attr("src"));
	$('#target').Jcrop({
	  onChange: updatePreview,
	  onSelect: updatePreview
	},function(){
	  // Use the API to get the real image size
	  var bounds = this.getBounds();
	  boundx = bounds[0];
	  boundy = bounds[1];
	  // Store the API in the jcrop_api variable
	  jcrop_api = this;
	});

	$('#detector_container').mouseup(function (e) {
    x_pos = e.pageX;
    y_pos = e.pageY;

    if($("#preview")[0].width > 0){
	    textDecteror();
      $("#preview_tooltip").show();
    }else{
      $("#preview_tooltip").hide();
      $("#preview_tooltip").empty();
    }
	})

	function textDecteror(){
		$.ajax({
		  url: "/detect_text_image",
		  type: "POST",
		  data: {
		    search_image: JSON.stringify(getDetectorParams())
		  },
		  dataType: 'json'
		}).done(function(data) {
		  var word_list = data.word_list;
      // $("#preview_tooltip").html(extract_meaning(found_word));
      if(word_list.length > 0){
      	var translation = ""
	      for(var i = 0; i < word_list.length; i++){
	      	var word = word_list[i];
	      	translation += extract_meaning(word) + "<br/>"
	      }
	      $("#preview_tooltip").html(translation);
      }else{
      	$("#preview_tooltip").html("not found");
      }

		  var d = document.getElementById('preview_tooltip');
	    d.style.position = "absolute";
	    d.style.left = x_pos + 'px';
	    d.style.top = y_pos + 'px';
		}).fail(function() {
		  console.log("error");
		});
	}

	function getDetectorParams(){
		return {
			image_data: $("#preview")[0].toDataURL("image/jpeg", 1.0)
		}
	}

	function updatePreview(c)
	{
	  var imageObj = $("#target")[0];
    var canvas = $("#preview")[0];
    var ratio = pic_real_width / $("#target").width();
    canvas.width = c.w * ratio;
    canvas.height = c.h * ratio;

    var offset_x = c.x * ratio;
    var offset_y = c.y * ratio;
    var context = canvas.getContext("2d");
    context.drawImage(imageObj, offset_x, offset_y, canvas.width, canvas.height, 0, 0, canvas.width, canvas.height);
    // var p = document.getElementById('preview');
    // p.style.position = "absolute";
    // p.style.left = x_pos + 'px';
    // p.style.top = (y_pos - 100) + 'px';
  };

  function extract_meaning(word){
    console.log('extract_meaning ', word);
    if(word.word){
      return word.word + " (" + word.kana + ") [" + word.cn_mean + "] <br/>" + word.mean;
    }else if(word.kana){
      return word.kana + ": " + word.mean;
    }else{
      return word.origin + ": not found";
    }
  }
});