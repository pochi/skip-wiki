module Admin::ApplicationHelper

  def selected_title
    child_menu, title, *links = case (request.headers['PATH_INFO'] || request.request_uri)
                                   when admin_root_path, admin_users_path
                                     [nil, "ユーザ一覧"]
                                   when (@user and edit_admin_user_path(@user.id))
                                     [nil,"#{@user.display_name}さん", "ユーザ一覧"]
                                   when admin_notes_path
                                     [nil, "ノート一覧"]
                                   when (@note and edit_admin_note_path(@note))
                                     [true,  "#{@note.display_name}", "ノート一覧"]
                                   when (@pages and @note and admin_note_pages_path(@note))
                                     ["ページ一覧", "ページ一覧", "ノート一覧", "#{@note.display_name}"]
                                   when (@note and admin_group_path(@note.owner_group))
                                     ["ユーザ一覧", "ユーザ一覧", "ノート一覧", "#{@note.display_name}"]
                                   when (@note and admin_note_label_indices_path(@note))
                                     ["ラベル編集", "ラベル編集", "ノート一覧", "#{@note.display_name}"]
                                   when (@note and admin_note_attachments_path(@note))
                                     ["添付ファイル一覧", "添付ファイル一覧", "ノート一覧", "#{@note.display_name}"]
                                   when (@pages and admin_pages_path)
                                     [nil, "ページ一覧"]
                                   when (@note and @page and admin_note_page_path(@note, @page))
                                     [true, "#{@page.display_name}", "ページ一覧"]
                                   when (@note and @page and edit_admin_note_page_path(@note, @page))
                                     ["プロパティ編集", "プロパティ編集", "ページ一覧", "#{@page.display_name}"]
                                   when (@note and @page and new_admin_note_page_history_path(@note, @page))
                                     ["編集", "編集", "ページ一覧", "#{@page.display_name}"]
                                   when admin_attachments_path
                                     [nil, "添付ファイル一覧"]
                                end
    menu = child_menu ? make_child_menu(child_menu) : nil
    [menu, make_title(title, links)]
  end

  def make_title(title, links)
    links.collect {|link| collation_link(link)}.concat(title.to_a).join("　＞　")
  end

  def make_child_menu(selected)
    note_links = ["ユーザ一覧","ラベル編集","ページ一覧","添付ファイル一覧"]
    page_links = ["プロパティ編集","編集","削除"]

    links = @page ? page_links : note_links
    links.collect {|link| link == selected ? link : collation_link(link) }.join(" | ")
  end

  def collation_link(name)
    link_path = case name
                  when "ユーザ一覧"
                    admin_users_path
                  when "ノート一覧"
                    admin_notes_path
                  when "ページ一覧"
                    admin_pages_path
                  when "プロパティ編集"
                    @page ? edit_admin_note_page_path(@note, @page) : edit_admin_note_path(@note)
                  when "ユーザ一覧"
                    admin_group_path(@note.owner_group)
                  when "ラベル編集"
                    admin_note_label_indices_path(@note)
                  when "ページ一覧"
                    admin_note_pages_path(@note)
                  when "添付ファイル一覧"
                    admin_note_attachments_path(@note)
                  when "編集"
                    new_admin_note_page_history_path(@note, @page)
                  when "削除"
                    options = {:confirm=>_("Are you sure?"), :method=>:delete}
                    {:controller=>'admin/pages',:action=>'destroy',:note_id=>@note,:id=>@page }
                  when "#{@note.display_name}"
                    edit_admin_note_path(@note)
                  when "#{@page.display_name}"
                    admin_note_page_path(@note, @page)
                end
    return link_to(name, link_path, options)
  end

  def search_target_path
    if @pages or @page
      admin_pages_path
    elsif @notes or @note
      admin_notes_path
    else
      admin_users_path
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
