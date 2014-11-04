import Widget from require "lapis.html"

class Welcome extends Widget
  content: =>
    h2 'Самопроверка домашних заданий'
    p 'Выберите файл с выполненныем заданием и нажмите на кнопку Отправить.'
    p [[Внимание! Эта форма не запоминает результатов.
Не забудьте в срок разместить файл в правильном месте.
Решение кладите в файл
~/term1/block3/credits/ВашаФамилия_практикум_мнемоника.py,
где ~ - ваша домашняя папка (не путать с папкой public_html!),
ВашаФамилия - ваша фамилия латинскими буквами с большой буквы,
а мнемоника - мнемоника, указанная в задании.
Пример: ~/term1/block3/credits/Pupkine_pr9_hello.py
]]
    form {
      action: "/send"
      method: "POST"
      enctype: "multipart/form-data"
    }, ->
      input type: "file", name: "uploaded_file"
      input type: "submit", value: "Отправить"

