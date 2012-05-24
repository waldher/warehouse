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
    stop: function(e, ui) {
      $.each($(".sortable input.threading"), function(i, obj) {
        $(obj).val(i+1);
      });
    }
  });

  $(".image_upload .fields").live('click', function() {
    content = $("<img />").attr("src", $(this).find('a').attr("data-url"));
    console.log(content);
    $(this).fancybox({content: content});
  });

  $(".title").live('keyup', function(event) {
    var self = this;
    // check to see if the user added a new title
    haveTitle = $(self).parent().find('.title').last().find('input').val();
    // if they added a title we need a new empty title field
    if(haveTitle) {
      // clone the element else it will only change the position
      var content = $(self).clone();
      // get the element string so we can search for num(regex need string)
      var html_content = content.html();
      // e.g. regex given 'ad_title[1]', will capture '1' (as string)
      var regex = new RegExp(/ad_title\[(\d+)\]/);
      // parse it to get integer 
      var num = parseInt(html_content.match(regex)[1], 10);
      // replace any occurance of regex_pattern 
      html_content = html_content.replace(/ad_title\[(\d+)\]/g, "ad_title["+ ++num + "]");
      html_content = $("<span></span>").attr({"class": "field title", "style": "display:block;"}).html(html_content);

      // convert it back to jquery element
      content = $(html_content);

      // clear the cloned element's input string
      content.find('input').val('');
      // append it to parent node
      var node = $(this).parent().append(content);
      //$('span.title').last().css('display','none');
      // for animation hiding and then showing
      $('span.title').last().hide().slideDown("slow");

      // add event blur to the new element. So that, if the are blank they are removed from the list
      $(".title").find('input').blur(function() {
        if(!$(this).val().trim()) {
          if($(".title input").length > 1){
            $(this).closest('.title').slideUp("normal", function() {
              $(this).remove();
            });
          }
        }
      });
      //content.appendTo($(this).parent());
      //var tTip = "Make your ad titles as eye-catching and appealing to prospective clients as possible"
      //node.find('input').attr('onmouseover', tip(tTip));
      //node.find('input').tooltip();
    }
  });

  // it will be applied to first element
  // though I'm not using it

  $(".title input").blur(function() {
        if(!$(this).val().trim()) {
          if($(".title input").length > 1){
            $(this).closest('.title').slideUp("normal", function() {
              $(this).remove();
            });  
          }
        }
  });


});
