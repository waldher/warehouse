$(document).ready(function() {

	$.validator.addMethod(
		"length_for_title",
		function(value,element){
			return this.optional(element) || (value.length < 70 );

		},
		"More than 70 characters are not allowed !"
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
	  },
	  errorElement: "div"
	});
	$("#listing_sublocation_id").blur(function() {
		$(this).valid();
	});
});







