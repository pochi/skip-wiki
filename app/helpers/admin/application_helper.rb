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
    [[_("GroupUsers"), admin_group_path(@note.owner_group)],
     [_("Label|Index"), admin_note_label_indices_path(@note)],
     [_("note pages"), admin_note_pages_path(@note)],
     [_("Attachment|Index"), admin_note_attachments_path(@note)]]
  end

  def page_child_menu
    [[_("edit property"), edit_admin_note_page_path(@note, @page)],
     [_("Edit"), new_admin_note_page_history_path(@note, @page)],
     [_("Delete"), {:controller=>'admin/pages',:action=>'destroy',:note_id=>@note,:id=>@page }]]
  end


  def child_menu
    if need_child_menu?
      menu = @page ? page_child_menu : note_child_menu
      generate_topics_str(menu, " | ")
    else 
      return nil
    end
  end

  def need_child_menu?
    if @note or @page
      if @pages
        return false
      elsif @attachments
        return false
      else
        return true
      end
    else
      return false
    end
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
