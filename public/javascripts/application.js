function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  $('#listing_images_id').append(content.replace(regexp, new_id));
}

function remove_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".fields").hide();
}

$(function() {
  $(".image_upload .fields").live('click', function() {
    content = $("<img />").attr("src", $(this).find('a').attr("data-url"));
    console.log(content);
    $(this).fancybox({content: content});
  });
});
