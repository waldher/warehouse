function add_fields(link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  $(link).parent().after(content.replace(regexp, new_id));
}

function remove_fields(link) {
  if(confirm("Are you sure you want to delete this image?")) {
    $(link).prev("input[type=hidden]").val("1");
    $(link).closest(".fields").hide();
  }
}



$(function() {
  $('.sortable').sortable({
    placeholder: "ui-state-highlight",
    tolerance: 'pointer',
    delay: 500,
    pointer: 'move',
    revert: true,
    start: function(e, ui) {
      ui.placeholder.height(ui.item.height());
    },
    update: function(e, ui) {
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
