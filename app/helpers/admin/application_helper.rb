module Admin::ApplicationHelper

  def selected_title
    child_menu, title, *links = case (request.headers['PATH_INFO'] || request.request_uri)
                                  when admin_root_path, admin_users_path
                                    [nil, "ユーザ一覧"]
                                  when (@user and edit_admin_user_path(@user.id))
                                    [nil,"#{@user.display_name}さんの編集", "ユーザ一覧"]
                                  when admin_notes_path
                                    [nil, "ノート一覧"]
                                  when (@note and edit_admin_note_path(@note))
                                    ["プロパティ編集", "プロパティ編集", "ノート一覧", "#{@note.display_name}の管理"]
                                  when (@pages and @note and admin_note_pages_path(@note))
                                    ["ページ一覧編集", "ページ一覧編集", "ノート一覧", "#{@note.display_name}の管理"]
                                  when (@note and admin_group_path(@note.owner_group))
                                    ["メンバー編集", "メンバー編集", "ノート一覧", "#{@note.display_name}の管理"]
                                  when (@note and admin_note_label_indices_path(@note))
                                    ["ラベル編集", "ラベル編集", "ノート一覧", "#{@note.display_name}の管理"]
                                  when (@note and admin_note_attachments_path(@note))
                                    ["添付ファイル編集", "添付ファイル編集", "ノート一覧", "#{@note.display_name}の管理"]
                                  when (@pages and admin_pages_path)
                                    [nil, "ページ一覧"]
                                  when (@note and @page and admin_note_page_path(@note, @page))
                                    ["プレビュー", "プレビュー", "ページ一覧", "#{@page.display_name}の編集"]
                                  when (@note and @page and edit_admin_note_page_path(@note, @page))
                                    ["プロパティ編集", "プロパティ編集", "ページ一覧", "#{@page.display_name}の編集"]
                                  when (@note and @page and new_admin_note_page_history_path(@note, @page))
                                    ["編集", "編集", "ページ一覧", "#{@page.display_name}の編集"]
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
    note_links = ["プロパティ編集","メンバー編集","ラベル編集","ページ一覧編集","添付ファイル編集"]
    page_links = ["プロパティ編集","プレビュー","編集","削除"]
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
                  when "メンバー編集"
                    admin_group_path(@note.owner_group)
                  when "ラベル編集"
                    admin_note_label_indices_path(@note)
                  when "ページ一覧編集"
                    admin_note_pages_path(@note)
                  when "添付ファイル編集"
                    admin_note_attachments_path(@note)
                  when "プレビュー"
                    admin_note_page_path(@note, @page)
                  when "編集"
                    new_admin_note_page_history_path(@note, @page)
                  when "削除"
                    options = {:confirm=>_("Are you sure?"), :method=>:delete}
                    {:controller=>'admin/pages',:action=>'destroy',:note_id=>@note,:id=>@page }
                  when "#{@note.display_name}の管理"
                    edit_admin_note_path(@note.id)
                  when "#{@page.display_name}の編集"
                    edit_admin_note_page_path(@note, @page)
                end
    return link_to(name, link_path, options)
  end
end
