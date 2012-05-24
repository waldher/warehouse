$(document).ready(function() {

	$.validator.addMethod(
		"length_for_title",
		function(value,element){
			return this.optional(element) || /^[a-zA-Z0-9._-]{1,70}$/i.test(value);

		},
		"More than 70 characters are not allowed"
	);
	$(".new_listing").validate({
	 rules: {
	    "listing[sublocation_id]": {
	      required: true
	    }
	  }
	});
	$(".edit_listing").validate({
	 rules: {
	    "listing[sublocation_id]": {
	     required: true
	    }
	  }
	});
	$("#listing_sublocation_id").blur(function() {
		$(this).valid();
	});
});







