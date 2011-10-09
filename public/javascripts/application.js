function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  $(link).parent().after(content.replace(regexp, new_id));
}

function remove_fields(link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".fields").hide();
}



$(function() {
  $('.sortable').sortable({
    update: function() {
              id = $(this).attr('id');
              data = $(this).sortable('serialize');
              url = " /listings/image_update/"+id;
              $.post(url, data);
            }
  });
  $(".image_upload .fields").live('click', function() {
    content = $("<img />").attr("src", $(this).find('a').attr("data-url"));
    console.log(content);
    $(this).fancybox({content: content});
  });
});
