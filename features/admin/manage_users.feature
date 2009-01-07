フィーチャ: ユーザ管理
  管理者ユーザはskip-noteのユーザを管理できるようにしたい

  シナリオ: 管理者ユーザは管理者メニューにアクセスできる
    前提 言語は"ja_JP"
    かつ ユーザ"dammyadmin"を管理者として登録し、ログインする
    かつ ノート"a_note"が作成済みである
    もし ノート"a_note"のページ"FrontPage"を表示している
    ならば "管理者メニュー"と表示されていること

  シナリオ: ユーザ編集
    前提シナリオ  管理者ユーザは管理者メニューにアクセスできる
    かつ  "管理者メニュー"リンクをクリックする
    かつ  "編集"リンクをクリックする

    もし  "ログイン名"に""を入力する
    かつ  "更新"ボタンをクリックする
    ならば "validation error"と表示されていること


    