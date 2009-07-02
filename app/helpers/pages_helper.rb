

module PagesHelper
  def fullscreen_action?(note = current_note)
    return true if note.label_navigation_style == LabelIndex::NAVIGATION_STYLE_NONE

    [%w[histories new], %w[pages new] ].any?{|c, a|
      params[:controller] == c && params[:action] == a
    }
  end

  def page_display_name_ipe_option(base={})
    {:messages => {:sending => _("Sending...")}}.merge(base)
  end

  def query_form_options(keys = [:keyword, :authors, :label_index_id, :order])
    {:method => "GET",
     :style  => keys.all?{|k| params[k].blank? } ? "display:none" : ""}
  end

  def group_by_date(pages, col=:updated_at, desc=true)
    ret = pages.group_by{|p| p[col].strftime("%F") }.sort_by{|d,_| d }
    desc ? ret.reverse : ret
  end

  def each_with_histories(pages, &block)
    history_opt = {
      :include => :user,
      :conditions => ["#{History.quoted_table_name}.page_id IN (?)", pages.map(&:id)],
    }
    histories = History.heads.find(:all, history_opt).inject({}) do |r, history|
      r.update(history.page_id => history)
    end

    label_opt = {:conditions =>{:page_id => pages.map(&:id)}, :include => :label_index}
    labels = LabelIndexing.find(:all, label_opt ).inject({}) do |r, indexing|
      r.update(indexing.page_id => indexing.label_index)
    end

    pages.each do |page|
      page.set_label_index_target(labels[page.id])
      yield page, histories[page.id]
    end
  end

  def render_page_content(page, rev=nil)
    case page.format_type
    when "hiki" then content_tag("div", render_hiki(page.content(rev)), :class => "rich_style")
    when "html" then render_richtext(page.content(rev))
    end
  end

  def render_richtext(content)
    sanitize_richtext(content)
  end

  def navi_item(text, path, current_path, *css)
    if path == current_path
      content = h(text)
      css = ["current", *css].join(" ")
    else
      content = link_to(h(text), path)
      css = css.join(" ")
    end

    content_tag("li", content, :class => css)
  end

  def editor_opt(page)
    {
      :basePath => controller.request.relative_url_root + "/javascripts/fckeditor/",
      :height => 450,
      :initialState => page.format_type
    }
  end

  def palette_opt(page)
    {
      :editor => "history_content",
      :url => {:attachments => note_attachments_url(current_note),
               :pages => note_pages_url(current_note) },
      :messages => {
        :tab => {:insert_link_label => _("Insert Link"),
                 :navi_prev => _("PREV"),
                 :navi_next => _("NEXT")},
        :page_search => {:show_all => _("Show all"),
                         :filter   => _("Filter"),
                         :keyword  => _("Input keyword to search")}
      },
      :uploader => {:target => IframeUploader::UPLOAD_KEY,
                    :trigger => "submit",
                    :src => {:form =>   new_note_attachment_path(current_note, IframeUploader.palette_opt),
                             :target => note_attachments_path(IframeUploader.palette_opt) },
                    :callback => nil }
    }
  end

  def page_operation(selected = request.request_uri)
    common_options = [
      [_("menu"), nil],
      [_("show page"), note_page_path(current_note, @page)],
      [_("edit content"), new_note_page_history_path(current_note, @page)],
      [_("edit page"), edit_note_page_path(current_note, @page)],
      [_("page histories"), note_page_histories_path(current_note, @page)],
    ]
    unless @page.front_page?
      common_options << [_("Delete %{entity}") % {:entity => _("page")}, edit_note_page_path(current_note, @page, :anchor=>"delete")]
    end

    options_for_select(common_options, selected)
  end

  def label_navi(note)
    out = ""
    head = content_tag("option", _("label change"), :value=>"")
    note.label_indices.inject(head) do |out, label_index|
      out << content_tag("option",
                         h(label_index.display_name),
                         :value=>label_index.id,
                         :style=>"background:%s" % label_index.color)
    end
  end

  def label_navi_for_new_page(note)
    note.label_indices.collect do |label_index|
      [label_index.display_name, label_index.id]
    end
  end

  def pages_indexed_by_label(labels, inlucde_draft = true)
    pages = Page.scoped(:conditions => {:note_id => current_note.id}).active
    pages = pages.published unless inlucde_draft

    loaded = pages.find(:all, :include => :label_index)
    labels.inject([]) do |r, label|
      ps = loaded.select{|p| p.label_index == label}
      ps.empty? ? r : r << [label, ps]
    end
  end
end
