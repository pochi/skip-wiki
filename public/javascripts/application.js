// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

(function() {
  jQuery.fn.preview = function(config){
    var root = this;
    function showPreview(){
      var data = root.parents("form").serializeArray();
      data = jQuery.grep(data, function(o){return o.name != "_method"});

     root.find("div.rendered").load(config["url"], data, function(){
          root.next("textarea").hide();
          root.
            find("div.rendered").fadeIn("fast").end().
            find("ul li.show").hide().end().end().
            find("ul li.hide").fadeIn("fast");
      });
      return false;
    }

    function hidePreview(){
      root.next("textarea").fadeIn("fast");
      root.
        find("div.rendered").hide().end().
        find("ul li.hide").hide().end().end().
        find("ul li.show").fadeIn("fast");
      return false;
    };

    root.find("li.show a.wii_button").click(showPreview);
    root.find("li.hide a.wii_button").click(hidePreview);
    hidePreview();
  };

  jQuery.fn.editor = function(config){
    var root = this;
    var form = root.parents("form");

    function api(){
      return FCKeditorAPI.GetInstance(root.attr("id"));
    }

    function activateFCKeditor(){
      if(!this.oFCKeditor){
        this.oFCKeditor = new FCKeditor(root.attr("id"), "100%", config["height"]||"330", "Normal") ;
        this.oFCKeditor.BasePath = config["basePath"];
        this.oFCKeditor.ReplaceTextarea() ;
        if(!config["submit_to_save"]){ addDynamicSave() };
      }
      root.hide().
        siblings(".previewable").hide().end().
        siblings("iframe").fadeIn("fast").end();
    };
/* Hiki
    function activateHikiAndPreview(){
      root.fadeIn("fast").
        siblings("iframe").hide().end().
        siblings(".previewable").fadeIn("fast");
    };
*/
    function addDynamicSave(){
      form.one("submit", createHistory).
           find("input[type=submit]").disable().end().
           find("a.back").click(confirmBack);
    };

    function confirmBack(){
      if(needToSave()){
        return confirm("未保存の更新があります。移動しますか?");
      }else{
        return true;
      }
    }

    function createHistory(){
      var button = jQuery(this);
      return saveHistory("POST", function(req,_){
        form.attr("action", req.getResponseHeader("Location"));
        button.submit( updateHistory );
      });
    };

    function updateHistory(){
      return saveHistory("PUT", function(){});
    }

    function needToSave(){
      return api().IsDirty() &&
             (jQuery.trim( api().GetHTML(true) ).length > 0);
    }

    function saveHistory(method, onSuccess){
      if(!needToSave()){
        alert("No need to save");
        return false;
      }
      var content = api().GetData(true);

      jQuery.ajax({ type: method,
                    url:  form.attr("action") + ".js",
                    data: ({"authenticity_token": $("input[name=authenticity_token]").val(),
                            "history[content]"  : content }),
                    complete : function(req, stat){
                      if(stat == "success"){
                        api().SetData(content, true);
                        onSuccess(req, stat);
                      }
                    } });
      return false;
    };

    function dispatch(){
      if(config["initialState"] == "html"){
        activateFCKeditor();
      }else{
        activateHikiAndPreview();
      }
    };
    dispatch();
  };

  jQuery.fn.linkPalette = function(config){
    var root = jQuery(this);
    var message = config["message"];

    function insertToEditor(elem){
      FCKeditorAPI.GetInstance(config["editor"]).InsertElement(elem.get(0));
    }

    function insertLink(label, href){
      return jQuery("<span>").text(message["insert_link_label"]).attr("class", "insertLink").click(function(){
        insertToEditor(jQuery("<a>").text(label).attr("href", href));
      });
    }

    function insertImage(label, src, filename){
      if(src){
        var img = jQuery("<img />").attr("src", src).attr("alt", label);
        return img.clone().attr("width", 200).click(function(){ insertToEditor(img); });
      }else{
        return jQuery("<span>").text(filename.substr(0,16));
      }
    }

    function attachmentToTableRow(data){
      var tr = jQuery("<tr>");
      tr.append(jQuery("<td class='name'>").append(insertImage(data["display_name"], data["inline"], data["filename"]))).
         append(jQuery("<td class='display_name'>").text(data["display_name"])).
         append(jQuery("<td class='insert'>").append(insertLink(data["display_name"], data["path"])));

      return tr;
    }

    function loadAttachments(palette, url, label){
      if(!url) return;
      jQuery.getJSON(url, function(data,stat){
        if(data.length == 0) return;
        var tbody = jQuery("<tbody>");
        jQuery.each(data, function(_num_, atmt){
          tbody.append(attachmentToTableRow(atmt["attachment"]));
        });
        palette.
          append(jQuery("<table>").
            append(jQuery("<caption>").text(label)).
            append(tbody));
      });
    }

    function hidePalette(){
      root.hide();
      jQuery("span.trigger.operation").one("click", onLoad);
    }

    function uploaderButtontton(conf){
      conf["callback"] = function(){
        root.find("table").remove();
        loadAttachments(root.find(".palette"), config["note_attachments"], message["note_attachments"]);
      };

      return jQuery("<div class='attachment upload' />").append(
          jQuery("<span class='operation'>").
            text(message["upload_attachment"]).
            one("click", function(){ jQuery(this).hide().parent().iframeUploader(conf) })
      )
    }

    function onLoad(){
      root.empty().attr("class", "enabled").draggable().
        append(
          jQuery("<div>").append(
            jQuery("<h3>").text(message["title"]).append(
              jQuery("<span>").text(message["close"]).click(hidePalette)
            )).append(
              uploaderButtontton(config["uploader"])
            ).append(
              jQuery("<div class='palette' />")
          )).
        show();
      loadAttachments(root.find(".palette"), config["note_attachments"], message["note_attachments"]);
    }
    jQuery("span.trigger.operation").one("click", onLoad);
  },

  jQuery.fn.labeledTextField = function(config){
    var target = jQuery(this);
    var focusClass = config["focusClass"] || "focus";
    var message = config["message"];

    target.parents("form").get(0).reset();
    if(target.val() != message){ target.addClass(focusClass); };

    target.focus(function(){
        target.addClass(focusClass);
        if(target.val() == message){ target.val("") };
      });
    target.blur(function(){
        if(target.val() == ""){
          target.removeClass(focusClass);
          target.parents("form").get(0).reset()
        };
      });
  },

  jQuery.fn.reloadLabelRadios = function(config){
    var self = jQuery(this);
    var proto = self.find("li:first").clone().find("input").attr("checked", null).end();
    jQuery.getJSON(config["url"], function(data, status){
      if(status != "success"){ return ; }
      self.empty();
      jQuery.each(data, function(num, l){
        var label = l["label_index"];
        var li = proto.clone()
        var ident = "page_label_index_id_" + label.id;
        li.find("input[type=radio]").attr("id", ident).attr("value", label.id).end().
           find("label").attr("for", ident).
             find("span").attr("style", "border-color:"+label.color).
             text(label.display_name);
        self.append(li);
      });
    });
  }

  jQuery.fn.manageLabel = function(config){
    var table = jQuery(this).find("table");

    function post(f, callback){
      jQuery.ajax({url: f.attr("action") + ".js",
        type: "POST",
        data: f.serializeArray(),
        success: callback
      });
    }

    function create(){
      var f = jQuery(this);
      f.nextAll("ul.errors").remove();
      jQuery.ajax({url: f.attr("action") + ".js",
        type: "POST",
        data: f.serializeArray(),
        dataType: "json",
        complete: function(req, stat){
          if(stat == "success"){
            f.reset(); appendLabel(req);
          } else if(stat == "error" && req.status == "422"){
            showValidationError(req);
          }
        }
      });
      return false;
    }

    function destroy(){
      if(!confirm("削除しますか?")) return false ;
      var f = jQuery(this);
      post(f, function(){f.parents("tr").fadeOut().remove()});

      return false;
    }

    function showValidationError(xhr){
      var errors = jQuery.httpData( xhr, "json");
      var ul = jQuery("<ul class='errors'>");
      ul.appendTo( jQuery("div.new") );
      jQuery.each(errors, function(){ jQuery("<li>").text(this.toString()).appendTo(ul) });
    }

    function update(td, _req, _stat){
      var name  = td.find("[name='label_index[display_name]']").val();
      var color = td.find("[name='label_index[color]']").val();

      td.find("span.label_badge").
        attr("style", "border-color:"+color).
        text(name);
      return false;
    }

    function appendLabel(xhr){
      var data = jQuery.httpData( xhr, "json")["label_index"];
      var display_name = data["display_name"];
      var color = data["color"];
      var url = xhr.getResponseHeader("Location");

      var row = table.find("tr:first").clone().
                  find("span.label_badge").
                    attr("style", "border-color:"+color).
                    text(display_name).end().
                  find("td.inplace-edit").
                    find("form").attr("action", url).
                      find("[name='label_index[display_name]']").val(display_name).end().
                      find("[name='label_index[color]']").val(color).end().
                    end().
                  end().
                  find("td.delete form").attr("action", url).submit(destroy).end();

      row.find("td.inplace-edit").aresInplaceEditor({callback:update});

      table.
        find("tr.inplace-edit span.ipe-cancel").trigger("click").end().
        find("tbody").append(row);
    }

    jQuery(this).find("div.new form").submit(create);
    jQuery.each(table.find("td.inplace-edit"), function(){jQuery(this).aresInplaceEditor({callback:update}) });
    table.find("td.delete form").submit(destroy);
  }

  jQuery.fn.aresInplaceEditor = function(config){
    var self = jQuery(this);
    var form = self.find("div.edit form");
    var messages = jQuery.extend({
                     sending: "Sending..."
                   },config["messages"])

    function showIPE(){
      self.find("div.edit").show().siblings("div.show").hide();
    }

    function hideIPE(){
      self.find("div.show").show().siblings("div.edit").hide();
    }

    function submitIPE(){
      try{
        var submitLabel = form.find("input[type=submit]").val();
        jQuery.ajax({url: form.attr("action") + ".js",
          type: "PUT",
          data: form.serializeArray(),
          dataType: "json",
          beforeSend: function(){
            self.find(".indicator").show();
            self.find("span.ipe-cancel").hide();
            if(messages["sending"]){ form.find("input[type=submit]").val( messages["sending"]) };
          },
          complete: function(req, status){
            self.find(".indicator").hide();
            self.find("span.ipe-cancel").show();
            if(messages["sending"]){ form.find("input[type=submit]").val( submitLabel ) };
            hideIPE();
            return config["callback"](self, req, status);
          }
        });
      }catch(e){
        alert(e);
      }
      return false;
    }

    self.
      find("div.show").
        find(".ipe-trigger").click(showIPE).end().end().
      find("div.edit").
        find("form").submit(submitIPE).
          find(".ipe-cancel").click(hideIPE).end().end();

    return self;
  }
})(jQuery);

application = function(){}
application.callbacks = {
  pageDisplaynameEditor : function(root, req, stat){
    if(stat == "success"){
      var data = jQuery.httpData( req, "json")["page"];
      root.find("span.title").text(data["display_name"]).effect("highlight", {}, 2*1000);
      root.find("form input[type=text]").val(data["display_name"]);
    } else if(stat == "parsererror" && req.responseText.match(/\s*/)){
      root.find("span.title").text(
        root.find("form input[type=text]").val()
      ).effect("highlight", {}, 2*1000);
    } else if(stat == "error" && req.status == "422"){
      alert(req.responseText);
    }
  }
};

