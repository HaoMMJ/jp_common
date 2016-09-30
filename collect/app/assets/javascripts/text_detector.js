$(function() {

	// Create variables (in this scope) to hold the API and image size
	var jcrop_api,
	    boundx,
	    boundy,
	    x_pos,
	    y_pos;

	$('#target').Jcrop({
	  onChange: updatePreview,
	  onSelect: updatePreview//,
	  // aspectRatio: xsize / ysize
	},function(){
	  // Use the API to get the real image size
	  var bounds = this.getBounds();
	  boundx = bounds[0];
	  boundy = bounds[1];
	  // Store the API in the jcrop_api variable
	  jcrop_api = this;
	});

	$('#detector_container').mouseup(function (e) {
	  x_pos = e.clientX;
	  y_pos = e.clientY;
	  var params = {};

	  params.search_image = JSON.stringify($("#preview")[0].toDataURL());
	  $.post( "/detect_text_image", params ).done(function( data ) {
	    debugger;
	  });
	})

	function updatePreview(c)
	{
	  var imageObj = $("#target")[0];
	  $("#preview").width(c.w);
	  $("#preview").height(c.h);
    var canvas = $("#preview")[0];
    var context = canvas.getContext("2d");
    context.drawImage(imageObj, c.x, c.y, c.w, c.h, 0, 0, canvas.width, canvas.height);
    var d = document.getElementById('preview');
    d.style.position = "absolute";
    d.style.left = x_pos + 'px';
    d.style.top = y_pos + 'px';
  };
});