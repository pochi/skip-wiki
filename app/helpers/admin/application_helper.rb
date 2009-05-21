module Admin::ApplicationHelper

  def generate_topics_str(topics, combine)
    topics.map do |topic|
      if topic.is_a?(Array)
        if topic.size > 1
          link_to h(topic.shift), topic.shift
        else
          h(topic.shift)
        end
      else
        h(topic)
      end
    end.join(combine)
  end

  def note_child_menu
    [["ユーザ一覧", admin_group_path(@note.owner_group)],
     ["ラベル一覧", admin_note_label_indices_path(@note)],
     ["ページ一覧", admin_note_pages_path(@note)],
     ["ファイル一覧", admin_note_attachments_path(@note)]]
  end

  def page_child_menu
    [["プロパティ編集", edit_admin_note_page_path(@note, @page)],
     ["編集", new_admin_note_page_history_path(@note, @page)],
     ["削除", {:controller=>'admin/pages',:action=>'destroy',:note_id=>@note,:id=>@page }]]
  end


  def child_menu
    unless @note or @page
      return nil
    end

    menu = @page ? page_child_menu : note_child_menu
    generate_topics_str(menu, " | ")
  end

  def search_target_path
    if @pages or @page
      admin_pages_path
    elsif @notes or @note
      admin_notes_path
    else
      nil
    end
  end
  
  def search_target_label
    if @pages or @page
      _("Search Page")
    elsif @notes or @note
      _("Search Note")
    else
      _("Search User")
    end
  end

end
