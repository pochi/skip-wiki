# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include SkipEmbedded::Helpers

  # XXX option_groups_from_collection_for_selectが使えないか検討する
  def notes_navi_on_header(user, selected="")
    notes = user.free_or_accessible_notes.reject{ |n| !user.page_editable?(n) }
    out = content_tag("option", _("Jump to Note"), :value=>"")

    notes.each do |note|
      out << content_tag("option", h(note.display_name), :value=>note_page_url(note, "FrontPage"))
    end
    out
  end

  def datepicker_with_time(object, field, options = {})
    name = ActionController::RecordIdentifier.singular_class_name(object)
    date = object.send(field)
    [
      text_field_tag("#{name}[#{field}][date]", date.strftime("%Y-%m-%d"),
                                                :id => "#{name}_#{field}", :class => "datepicker", :size => 10),
      select_hour(date, {}, :name => "#{name}[#{field}][hour]", :id=>"#{name}_#{field}_hour"),
      content_tag("label", _("Hour"), :for => "#{name}_#{field}_hour"),

      select_minute(date, {}, :name => "#{name}[#{field}][min]", :id=>"#{name}_#{field}_min"),
      content_tag("label", _("Min"), :for => "#{name}_#{field}_min"),
    ].join("\n")
  end

  def val_tag(content, options = {})
    content_tag("span", h(content), {:class=>"val"}.merge(options))
  end

  def date_picker(selector)
    inclusion = javascript_include_tag "jquery/ui/i18n/ui.datepicker-#{locale}.js"
    date_picker_scripts = <<-JS
jQuery(function(){
  jQuery('#{selector}').datepicker(
      jQuery.extend({}, jQuery.datepicker.regional['#{locale}'], #{date_picker_opts.to_json})
  );
})
    JS
    [inclusion, javascript_tag(date_picker_scripts)].join("\n")
  end

  def back_link_to(page_name, url, options ={})
    options[:class] = options[:class].nil? ? "back" :  ["back", options[:class]].flatten.uniq
    link_to(_("Back to %{page}") % {:page => page_name}, url, options)
  end

  def javascript_include_file(filename)
    if ::Rails.env == "development"
      fullpath = File.expand_path("public/javascripts/#{filename}.js", ::Rails.root)
      javascript_tag File.read(fullpath)
    else
      javascript_include_tag filename
    end
  end

  def admin_operation(selected = request.request_uri)
    options_for_select( [
      [_("menu"), nil],
      [_("manage users"), admin_root_path],
      [_("manage notes"), admin_notes_path],
      [_("manage common files"), nil]
    ], selected)
  end

  def recent_pages user, menu_item_num=11
    notes = user.free_or_accessible_notes
    Page.active.scoped(:conditions=>["note_id IN (?)", notes.map(&:id)]).recent(menu_item_num)
  end

  private
  def locale
    GetText.locale
  end

  def date_picker_opts
    { :duration => '',
      :yearRange => '-80:10',
      :showOn => 'both',
      :buttonImage => image_path("jquery/ui.datepicker/calendar.png"),
      :buttonImageOnly => true,
      :dateFormat => "yy-mm-dd" }
  end
end
