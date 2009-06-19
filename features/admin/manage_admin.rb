Then /管理者メニューが表示されていること/ do
   Then '"管理者メニュー"と表示されていること'
   Then '"ノート"というリンクがあること'
   Then '"ページ"というリンクがあること'
   Then '"ファイル"というリンクがあること'
   Then '"ユーザ"というリンクがあること'
end


# opposite order from Engilsh one(original)
Then /^"([^\"]*)"から"([^\"]*)"が選択されていること$/ do |field, value|
  Then %Q(the "#{field}" field should contain "#{value}")
end
