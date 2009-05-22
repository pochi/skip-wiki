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
    [[_("group users"), admin_group_path(@note.owner_group)],
     [_("label index"), admin_note_label_indices_path(@note)],
     [_("page"), admin_note_pages_path(@note)],
     [_("attachment"), admin_note_attachments_path(@note)]]
  end

  def page_child_menu
    [[_("edit property"), edit_admin_note_page_path(@note, @page)],
     [_("Edit"), new_admin_note_page_history_path(@note, @page)],
     [_("Delete"), {:controller=>'admin/pages',:action=>'destroy',:note_id=>@note,:id=>@page }]]
  end


  def child_menu
    menu = @page ? page_child_menu : note_child_menu
    generate_topics_str(menu, " | ")
  end

end
