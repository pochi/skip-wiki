module Admin::ApplicationHelper

  def generate_topics_str(topics)
    topics.map do |title, link|
      link_to_if(link, h(title), link)
    end.join(" ＞ ")
  end

  def generate_child_menu_str(menus)
    menus.map do |title, link|
      link_to_if(link, h(title), link)
    end.join(" | ")
  end

  def paginate_links(selected=nil)
    url_param = params.dup
    links = [10,25,50].collect {|n| link_to_if(n != selected.to_i, n, url_for(url_param.merge(:per_page => n))) }
    return "| 1ページに: " + links.join(" , ")
  end

  def page_entries_info_ja(collection, options = {})
    entry_name = options[:entry_name] ||
      (collection.empty?? 'entry' : collection.first.class.name.underscore.sub('_', ' '))

    if collection.total_pages == 0
      "候補が見つかりません"
    else
      %{(<b>%d&nbsp;-&nbsp;%d</b> 件 / <b>%d</b> 件)} % [
        collection.offset + 1,
        collection.offset + collection.length,
        collection.total_entries
      ]
    end
  end


  # group_users => Wikiにアクセスできるユーザ一覧
  def note_child_menu
    [#[_("group users"), admin_group_path(@note.owner_group.name)],
     [_("label index"), admin_note_label_indices_path(@note)],
     [_("page"), admin_note_pages_path(@note)],
     [_("attachment"), admin_note_attachments_path(@note)]]
  end

  def page_child_menu
    [[_("edit property"), edit_admin_note_page_path(@note, @page)],
     [_("Edit"), new_admin_note_page_history_path(@note, @page)],
     [_("Delete"), {:controller=>'admin/pages',:action=>'destroy',:note_id=>@note,:id=>@page }]]
  end

  def need_child_menu?
    except_conditions = @notes || @pages || @attachments
    true_conditions =  @note || @page

    if except_conditions
      return false
    elsif true_conditions
      return true
    else
      return false
    end
  end

  def child_menu
    menu = @page ? page_child_menu : note_child_menu
    generate_child_menu_str(menu)
  end

end
